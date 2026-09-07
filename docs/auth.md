# Google Sign-In and user-data sync

Optional login (drawer menu) syncs favorites, custom lists, settings, and
Jubilate/Cor sheet unlocks. The app works without it. There is no Firebase;
Google ID tokens are validated by API Gateway, and the account document lives
in DynamoDB (`carte-cantari-backend`).

If you need to rotate credentials or point the app at a new API, change the
values below. Client IDs are public (they ship in the app); do not put a
Google client secret or AWS keys in this repo.

## What to change

| Value | Where | Where to get it |
|-------|--------|-----------------|
| Web OAuth client ID | `lib/auth_config.dart` → `GOOGLE_WEB_CLIENT_ID` | [Google Cloud Console](https://console.cloud.google.com/apis/credentials) → the **Web application** OAuth client. Used as `clientId` on web and as `serverClientId` on Android/iOS so ID tokens share one audience. |
| User-data API (dev / prod) | `lib/auth_config.dart` → `_USER_DATA_DEV_API_ID` / `_USER_DATA_PROD_API_ID` | `sam deploy` output `UserDataApi` in `carte-cantari-backend`. The ID is the subdomain of `https://<id>.execute-api.eu-central-1.amazonaws.com/user-data`. Debug builds use dev; release builds use prod. |
| iOS OAuth client ID | `ios/Runner/Info.plist` → `GIDClientID` | Same Credentials page → the **iOS** OAuth client (bundle ID `ro.ber.cartecantari`). |
| iOS URL scheme | `ios/Runner/Info.plist` → `CFBundleURLSchemes` | The iOS client ID with the domain reversed, e.g. `123-abc.apps.googleusercontent.com` → `com.googleusercontent.apps.123-abc`. |
| JWT audiences | `carte-cantari-backend` `samconfig.toml` → `GoogleClientIds` (both `[default]` and `[prod]`) | Comma-separated **Web and iOS** client IDs. Android sign-in tokens use the Web client as audience, so the Android client ID is not listed here. Redeploy after changing. |

Android has no client ID in this repo. Sign-in uses the Web client as
`serverClientId`. New Android builds still need a matching **Android** OAuth
client in Cloud Console (package `ro.ber.cartecantari` + that build’s signing
certificate SHA-1).

## When you replace or add OAuth clients

In Cloud Console → the **Web** client → Authorized JavaScript origins, keep
an exact origin for every place the web app is served (scheme + host + port,
no path):

- production: `https://cartecantari.ro` (and `https://www.cartecantari.ro` if used)
- local Flutter web: `http://localhost` **and** `http://localhost:<port>`
  (the `web` launch config in `.vscode/launch.json` uses port `5000`)

A missing origin shows Google’s `origin_mismatch` / Error 400.

For Android clients, add one OAuth client per signing certificate (debug,
upload key, and Play’s app-signing key if Play App Signing is on). SHA-1
comes from Play Console → Setup → App integrity, or `keytool -list -v` on
the keystore used to sign that build.
