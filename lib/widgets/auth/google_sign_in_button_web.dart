import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as gsi_web;

/// On web, interactive sign-in must go through Google's own rendered button.
Widget buildGoogleSignInButton() {
  return gsi_web.renderButton();
}
