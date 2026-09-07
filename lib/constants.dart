library constants;

import 'package:flutter/material.dart';

const COLOR_WHITE = Color.fromRGBO(250, 250, 250, 1.0);
const COLOR_BLUE = Color.fromRGBO(46, 193, 244, 1.0);
const COLOR_DARKER_BLUE = Color.fromRGBO(13, 57, 73, 1.0);
const COLOR_DARK_BLUE = Color.fromRGBO(18, 77, 98, 1.0);
const COLOR_LIGHT_BLUE = Color.fromRGBO(26, 108, 140, 1.0);

// ignore: non_constant_identifier_names
final COLOR_FAVORITE = Colors.yellow[600];
//final COLOR_FAVORITE = Colors.red[500];
// ignore: non_constant_identifier_names
final COLOR_DARK_FAVORITE = Colors.yellow[700];
//final COLOR_DARK_FAVORITE = Colors.red[700];

const PREFS_APP_THEME_KEY = "appTheme";
const PREFS_SETTINGS_SHOW_KEY_SIGNATURES = "settingsShowKeySignatures";
const PREFS_PRIORITIZE_MUSIC_SHEETS = "prioritizeMusicSheets";
const PREFS_TEXT_SIZE_KEY = "textSize";
const PREFS_ALLOW_JUBILATE = "allowJubilate";
const PREFS_ALLOW_COR = "allowCor";
const PREFS_UPDATE_VERSION = "updateVersion";

// Auth: the app persists the signed-in account itself so a cold start with no
// internet still shows the user as logged in.
const PREFS_AUTH_SIGNED_IN = "authSignedIn";
const PREFS_AUTH_EMAIL = "authEmail";
const PREFS_AUTH_DISPLAY_NAME = "authDisplayName";
const PREFS_AUTH_PHOTO_URL = "authPhotoUrl";

// Cloud sync bookkeeping.
const PREFS_SYNC_DIRTY = "syncDirty";
const PREFS_SYNC_UPDATED_AT = "syncUpdatedAt";

// Snapshot of the anonymous (logged-out) profile, taken when logging in and
// restored when logging out.
const PREFS_ANON_SNAPSHOT_EXISTS = "anonSnapshotExists";
const PREFS_ANON_APP_THEME = "anonAppTheme";
const PREFS_ANON_TEXT_SIZE = "anonTextSize";
const PREFS_ANON_SHOW_KEY_SIGNATURES = "anonShowKeySignatures";
const PREFS_ANON_ALLOW_JUBILATE = "anonAllowJubilate";
const PREFS_ANON_ALLOW_COR = "anonAllowCor";
const PREFS_ANON_FAVORITES = "anonFavorites";
const PREFS_ANON_CUSTOM_LISTS = "anonCustomLists";

const LATEST_UPDATE_VERSION = 3;

const HOSTNAME = "185.177.59.158";
//const HOSTNAME = "localhost:5001";
