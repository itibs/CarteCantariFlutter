import 'package:ccc_flutter/models/custom_list.dart';
import 'package:equatable/equatable.dart';

/// The account data synced to the cloud: favorites, custom lists, settings
/// and the Jubilate/Cor music sheet unlocks.
class UserData extends Equatable {
  static const int DEFAULT_APP_THEME = 0;
  static const double DEFAULT_TEXT_SIZE = 21.0;

  final Set<String> favorites;
  final List<CustomList> customLists;
  /// False when an older cloud payload omitted custom lists; local lists
  /// should be kept and uploaded rather than replaced with empty.
  final bool hasCustomLists;
  final int appTheme;
  final double textSize;
  final bool showKeySignatures;
  final bool allowJubilate;
  final bool allowCor;
  final int updatedAt;

  const UserData({
    required this.favorites,
    required this.customLists,
    this.hasCustomLists = true,
    required this.appTheme,
    required this.textSize,
    required this.showKeySignatures,
    required this.allowJubilate,
    required this.allowCor,
    required this.updatedAt,
  });

  UserData.defaults({required this.updatedAt})
      :         favorites = const {},
        customLists = const [],
        hasCustomLists = true,
        appTheme = DEFAULT_APP_THEME,
        textSize = DEFAULT_TEXT_SIZE,
        showKeySignatures = false,
        allowJubilate = false,
        allowCor = false;

  factory UserData.fromJson(Map<String, dynamic> json) {
    final settings = (json['settings'] as Map<String, dynamic>?) ?? const {};
    final unlocks = (json['unlocks'] as Map<String, dynamic>?) ?? const {};
    return UserData(
      favorites: ((json['favorites'] as List<dynamic>?) ?? const [])
          .cast<String>()
          .toSet(),
      customLists: _customListsFromJson(json['custom_lists']),
      hasCustomLists: json.containsKey('custom_lists'),
      appTheme: (settings['theme'] as num?)?.toInt() ?? DEFAULT_APP_THEME,
      textSize: (settings['textSize'] as num?)?.toDouble() ?? DEFAULT_TEXT_SIZE,
      showKeySignatures: settings['showKeySignatures'] as bool? ?? false,
      allowJubilate: unlocks['allowJubilate'] as bool? ?? false,
      allowCor: unlocks['allowCor'] as bool? ?? false,
      updatedAt: (json['updated_at'] as num?)?.toInt() ?? 0,
    );
  }

  static List<CustomList> _customListsFromJson(dynamic json) {
    if (json is! List) {
      return const [];
    }
    return json
        .whereType<Map>()
        .map((item) => CustomList.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'favorites': favorites.toList(),
      'custom_lists': customLists.map((list) => list.toJson()).toList(),
      'settings': {
        'theme': appTheme,
        'textSize': textSize,
        'showKeySignatures': showKeySignatures,
      },
      'unlocks': {
        'allowJubilate': allowJubilate,
        'allowCor': allowCor,
      },
      'updated_at': updatedAt,
    };
  }

  @override
  List<Object?> get props => [
        favorites,
        customLists.map((list) => list.toJson()).toList(),
        hasCustomLists,
        appTheme,
        textSize,
        showKeySignatures,
        allowJubilate,
        allowCor,
        updatedAt,
      ];
}
