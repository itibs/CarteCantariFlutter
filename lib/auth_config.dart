library auth_config;

import 'package:flutter/foundation.dart' show kReleaseMode;

/// Google OAuth "Web application" client ID from Google Cloud Console
/// (APIs & Services -> Credentials). Used:
///  - as `clientId` on web,
///  - as `serverClientId` on Android/iOS so the ID token audience matches the
///    backend JWT authorizer.
/// See docs/auth.md if these IDs need to change.
const String GOOGLE_WEB_CLIENT_ID =
    "181044477832-ukamqp27o2c5er3s56jggj6q85pbtl1g.apps.googleusercontent.com";

// API Gateway HTTP API IDs of the user-data sync API (output `UserDataApi` of
// `sam deploy` in the carte-cantari-backend repo; the ID is the subdomain).
const String _USER_DATA_PROD_API_ID = 'aa0pfa0b51';
const String _USER_DATA_DEV_API_ID = '32gthx3t9g';

const String _USER_DATA_API_ID =
    kReleaseMode ? _USER_DATA_PROD_API_ID : _USER_DATA_DEV_API_ID;

const String USER_DATA_API_URL =
    'https://$_USER_DATA_API_ID.execute-api.eu-central-1.amazonaws.com/user-data';
