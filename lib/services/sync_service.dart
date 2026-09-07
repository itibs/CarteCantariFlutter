import 'dart:async';
import 'dart:convert';

import 'package:ccc_flutter/blocs/auth/auth_cubit.dart';
import 'package:ccc_flutter/blocs/settings/allow_cor_music_sheets/allow_cor_music_sheets.dart';
import 'package:ccc_flutter/blocs/settings/allow_jubilate_music_sheets/allow_jubilate_music_sheets.dart';
import 'package:ccc_flutter/blocs/settings/show_key_signatures/show_key_signatures.dart';
import 'package:ccc_flutter/blocs/theme/app_themes.dart';
import 'package:ccc_flutter/blocs/theme/theme_bloc.dart';
import 'package:ccc_flutter/constants.dart';
import 'package:ccc_flutter/models/custom_list.dart';
import 'package:ccc_flutter/models/user_data.dart';
import 'package:ccc_flutter/repositories/custom_lists_repository/custom_lists_mobile_repository.dart';
import 'package:ccc_flutter/repositories/custom_lists_repository/custom_lists_repository.dart';
import 'package:ccc_flutter/repositories/custom_lists_repository/custom_lists_web_repository.dart';
import 'package:ccc_flutter/repositories/favorites_repository/favorites_mobile_repository.dart';
import 'package:ccc_flutter/repositories/favorites_repository/favorites_repository.dart';
import 'package:ccc_flutter/repositories/favorites_repository/favorites_web_repository.dart';
import 'package:ccc_flutter/repositories/user_data_repository/user_data_repository.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

/// Orchestrates cloud sync of the account data (favorites, custom lists,
/// settings, music sheet unlocks).
///
/// Local storage stays the source of truth the app reads from; the cloud is a
/// mirror. All background sync is opportunistic and fire-and-forget: when
/// offline it fails silently, a dirty flag is kept, and the push is retried on
/// the next app start or local change.
class SyncService {
  /// Nullable so code paths (and tests) that run without an initialized sync
  /// service degrade to plain local behavior.
  static SyncService? instance;

  final AuthCubit authCubit;
  final ThemeBloc themeBloc;
  final ShowKeySignaturesCubit showKeySignaturesCubit;
  final AllowJubilateMusicSheetsCubit allowJubilateCubit;
  final AllowCorMusicSheetsCubit allowCorCubit;
  final UserDataRepository _userDataRepository;
  final IFavoritesRepository _favoritesRepository;
  final ICustomListsRepository _customListsRepository;

  /// Set by MainScreen so applied remote favorites/lists are reflected in the
  /// already-loaded book list.
  void Function()? onSyncedDataApplied;

  Timer? _debounce;

  SyncService({
    required this.authCubit,
    required this.themeBloc,
    required this.showKeySignaturesCubit,
    required this.allowJubilateCubit,
    required this.allowCorCubit,
    UserDataRepository? userDataRepository,
    IFavoritesRepository? favoritesRepository,
    ICustomListsRepository? customListsRepository,
  })  : _userDataRepository = userDataRepository ?? UserDataRepository(),
        _favoritesRepository = favoritesRepository ??
            (kIsWeb ? FavoritesWebRepository() : FavoritesMobileRepository()),
        _customListsRepository = customListsRepository ??
            (kIsWeb
                ? CustomListsWebRepository()
                : CustomListsMobileRepository());

  bool get _signedIn => authCubit.state.signedIn;

  /// Called from user-action mutation sites (favorite toggled, list changed,
  /// setting changed, sheet unlocked). Marks local data dirty and schedules a
  /// debounced background push.
  void notifyLocalChange() {
    if (!_signedIn) {
      return;
    }
    SharedPreferences.getInstance().then((prefs) async {
      await prefs.setBool(PREFS_SYNC_DIRTY, true);
      await prefs.setInt(
          PREFS_SYNC_UPDATED_AT, DateTime.now().millisecondsSinceEpoch);
    });
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 3), () {
      pushLocal().catchError((_) {});
    });
  }

  /// Opportunistic sync on app start: push pending local changes, then pull
  /// and apply remote data if it is newer. Silently does nothing when offline.
  Future<void> onAppStart() async {
    if (!_signedIn) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(PREFS_SYNC_DIRTY) ?? false) {
      try {
        await pushLocal();
      } catch (_) {
        return;
      }
    }
    try {
      final remote = await _fetchRemote();
      if (remote == null) {
        return;
      }
      final localUpdatedAt = prefs.getInt(PREFS_SYNC_UPDATED_AT) ?? 0;
      if (remote.updatedAt > localUpdatedAt) {
        await _applyRemote(remote);
      }
    } catch (_) {}
  }

  /// Post-authentication flow, run before the account is marked signed in at
  /// the app level. [askImport] shows the first-login import dialog.
  /// Returns false on failure, in which case the caller signs back out.
  Future<bool> handleSignedIn(
      {required Future<bool> Function() askImport}) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final remote = await _fetchRemote();
      await _snapshotAnonymous(prefs);
      if (remote != null) {
        await _applyRemote(remote);
      } else {
        // First login on this account.
        final now = DateTime.now().millisecondsSinceEpoch;
        final import = await askImport();
        if (import) {
          // The live local data becomes the account data; the logged-out app
          // is reset to defaults from now on.
          await _resetAnonymousSnapshotToDefaults(prefs);
        } else {
          // Fresh account; the anonymous data stays for logged-out use.
          await _applyRemote(UserData.defaults(updatedAt: now));
        }
        await prefs.setInt(PREFS_SYNC_UPDATED_AT, now);
        await pushLocal();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Pre-logout flow: pushes pending changes (logout is blocked when this
  /// fails, so unsynced data isn't lost), then restores the anonymous profile.
  /// Returns false if logout must be blocked.
  Future<bool> handleSignOut() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(PREFS_SYNC_DIRTY) ?? false) {
      try {
        await pushLocal();
      } catch (_) {
        return false;
      }
    }
    _debounce?.cancel();
    await _restoreAnonymous(prefs);
    return true;
  }

  /// Uploads the current live local data to the account.
  Future<void> pushLocal() async {
    final token = await authCubit.getIdToken();
    if (token == null) {
      throw Exception('No ID token available');
    }
    final prefs = await SharedPreferences.getInstance();
    final data = await _collectLocal(prefs);
    await _userDataRepository.storeUserData(token, data);
    await prefs.setBool(PREFS_SYNC_DIRTY, false);
  }

  Future<UserData?> _fetchRemote() async {
    final token = await authCubit.getIdToken();
    if (token == null) {
      throw Exception('No ID token available');
    }
    return _userDataRepository.fetchUserData(token);
  }

  Future<UserData> _collectLocal(SharedPreferences prefs) async {
    final favorites = await _favoritesRepository.getFavorites();
    final customLists = await _customListsRepository.getLists();
    return UserData(
      favorites: favorites,
      customLists: customLists,
      appTheme: prefs.getInt(PREFS_APP_THEME_KEY) ?? UserData.DEFAULT_APP_THEME,
      textSize:
          prefs.getDouble(PREFS_TEXT_SIZE_KEY) ?? UserData.DEFAULT_TEXT_SIZE,
      showKeySignatures:
          prefs.getBool(PREFS_SETTINGS_SHOW_KEY_SIGNATURES) ?? false,
      allowJubilate: prefs.getBool(PREFS_ALLOW_JUBILATE) ?? false,
      allowCor: prefs.getBool(PREFS_ALLOW_COR) ?? false,
      updatedAt: prefs.getInt(PREFS_SYNC_UPDATED_AT) ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Writes [data] into live local storage and refreshes the app state.
  Future<void> _applyRemote(UserData data) async {
    final prefs = await SharedPreferences.getInstance();
    await _favoritesRepository.storeFavorites(data.favorites);
    if (data.hasCustomLists) {
      await _customListsRepository.storeLists(data.customLists);
    }
    await prefs.setInt(PREFS_APP_THEME_KEY, data.appTheme);
    await prefs.setDouble(PREFS_TEXT_SIZE_KEY, data.textSize);
    await prefs.setBool(
        PREFS_SETTINGS_SHOW_KEY_SIGNATURES, data.showKeySignatures);
    await prefs.setBool(PREFS_ALLOW_JUBILATE, data.allowJubilate);
    await prefs.setBool(PREFS_ALLOW_COR, data.allowCor);
    await prefs.setInt(PREFS_SYNC_UPDATED_AT, data.updatedAt);
    await prefs.setBool(PREFS_SYNC_DIRTY, false);
    _refreshLiveState(data);
    if (!data.hasCustomLists) {
      // Older cloud records have no lists field; keep local lists and upload.
      notifyLocalChange();
    }
  }

  void _refreshLiveState(UserData data) {
    final themeIdx = data.appTheme >= 0 && data.appTheme < AppTheme.values.length
        ? data.appTheme
        : UserData.DEFAULT_APP_THEME;
    // ThemeLoaded only updates the UI; prefs were already written above.
    themeBloc.add(ThemeLoaded(theme: AppTheme.values[themeIdx]));
    showKeySignaturesCubit.setValue(data.showKeySignatures);
    allowJubilateCubit.setValue(data.allowJubilate);
    allowCorCubit.setValue(data.allowCor);
    onSyncedDataApplied?.call();
  }

  Future<void> _snapshotAnonymous(SharedPreferences prefs) async {
    final favorites = await _favoritesRepository.getFavorites();
    final customLists = await _customListsRepository.getLists();
    await prefs.setString(PREFS_ANON_FAVORITES, json.encode(favorites.toList()));
    await prefs.setString(PREFS_ANON_CUSTOM_LISTS,
        json.encode(customLists.map((list) => list.toJson()).toList()));
    await prefs.setInt(PREFS_ANON_APP_THEME,
        prefs.getInt(PREFS_APP_THEME_KEY) ?? UserData.DEFAULT_APP_THEME);
    await prefs.setDouble(PREFS_ANON_TEXT_SIZE,
        prefs.getDouble(PREFS_TEXT_SIZE_KEY) ?? UserData.DEFAULT_TEXT_SIZE);
    await prefs.setBool(PREFS_ANON_SHOW_KEY_SIGNATURES,
        prefs.getBool(PREFS_SETTINGS_SHOW_KEY_SIGNATURES) ?? false);
    await prefs.setBool(PREFS_ANON_ALLOW_JUBILATE,
        prefs.getBool(PREFS_ALLOW_JUBILATE) ?? false);
    await prefs.setBool(
        PREFS_ANON_ALLOW_COR, prefs.getBool(PREFS_ALLOW_COR) ?? false);
    await prefs.setBool(PREFS_ANON_SNAPSHOT_EXISTS, true);
  }

  /// After a first-login import the local data moves into the account, so the
  /// logged-out app must come back empty.
  Future<void> _resetAnonymousSnapshotToDefaults(
      SharedPreferences prefs) async {
    await prefs.setString(PREFS_ANON_FAVORITES, json.encode(const <String>[]));
    await prefs.setString(PREFS_ANON_CUSTOM_LISTS, json.encode(const []));
    await prefs.setInt(PREFS_ANON_APP_THEME, UserData.DEFAULT_APP_THEME);
    await prefs.setDouble(PREFS_ANON_TEXT_SIZE, UserData.DEFAULT_TEXT_SIZE);
    await prefs.setBool(PREFS_ANON_SHOW_KEY_SIGNATURES, false);
    await prefs.setBool(PREFS_ANON_ALLOW_JUBILATE, false);
    await prefs.setBool(PREFS_ANON_ALLOW_COR, false);
    await prefs.setBool(PREFS_ANON_SNAPSHOT_EXISTS, true);
  }

  Future<void> _restoreAnonymous(SharedPreferences prefs) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    UserData snapshot;
    if (prefs.getBool(PREFS_ANON_SNAPSHOT_EXISTS) ?? false) {
      final favoritesJson = prefs.getString(PREFS_ANON_FAVORITES);
      final favorites = favoritesJson == null
          ? <String>{}
          : (json.decode(favoritesJson) as List<dynamic>)
              .cast<String>()
              .toSet();
      snapshot = UserData(
        favorites: favorites,
        customLists: _customListsFromPrefs(prefs.getString(PREFS_ANON_CUSTOM_LISTS)),
        appTheme:
            prefs.getInt(PREFS_ANON_APP_THEME) ?? UserData.DEFAULT_APP_THEME,
        textSize: prefs.getDouble(PREFS_ANON_TEXT_SIZE) ??
            UserData.DEFAULT_TEXT_SIZE,
        showKeySignatures:
            prefs.getBool(PREFS_ANON_SHOW_KEY_SIGNATURES) ?? false,
        allowJubilate: prefs.getBool(PREFS_ANON_ALLOW_JUBILATE) ?? false,
        allowCor: prefs.getBool(PREFS_ANON_ALLOW_COR) ?? false,
        updatedAt: now,
      );
    } else {
      snapshot = UserData.defaults(updatedAt: now);
    }

    await _favoritesRepository.storeFavorites(snapshot.favorites);
    if (prefs.containsKey(PREFS_ANON_CUSTOM_LISTS)) {
      await _customListsRepository.storeLists(snapshot.customLists);
    }
    await prefs.setInt(PREFS_APP_THEME_KEY, snapshot.appTheme);
    await prefs.setDouble(PREFS_TEXT_SIZE_KEY, snapshot.textSize);
    await prefs.setBool(
        PREFS_SETTINGS_SHOW_KEY_SIGNATURES, snapshot.showKeySignatures);
    await prefs.setBool(PREFS_ALLOW_JUBILATE, snapshot.allowJubilate);
    await prefs.setBool(PREFS_ALLOW_COR, snapshot.allowCor);

    await prefs.remove(PREFS_ANON_SNAPSHOT_EXISTS);
    await prefs.remove(PREFS_ANON_FAVORITES);
    await prefs.remove(PREFS_ANON_CUSTOM_LISTS);
    await prefs.remove(PREFS_ANON_APP_THEME);
    await prefs.remove(PREFS_ANON_TEXT_SIZE);
    await prefs.remove(PREFS_ANON_SHOW_KEY_SIGNATURES);
    await prefs.remove(PREFS_ANON_ALLOW_JUBILATE);
    await prefs.remove(PREFS_ANON_ALLOW_COR);
    await prefs.remove(PREFS_SYNC_DIRTY);
    await prefs.remove(PREFS_SYNC_UPDATED_AT);

    _refreshLiveState(snapshot);
  }

  List<CustomList> _customListsFromPrefs(String? jsonString) {
    if (jsonString == null) {
      return [];
    }
    final decoded = json.decode(jsonString);
    if (decoded is! List) {
      return [];
    }
    return decoded
        .whereType<Map>()
        .map((item) => CustomList.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
