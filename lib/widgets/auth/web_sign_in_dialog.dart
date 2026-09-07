import 'dart:async';

import 'package:ccc_flutter/blocs/auth/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'google_sign_in_button_stub.dart'
    if (dart.library.js_interop) 'google_sign_in_button_web.dart';

/// Web-only sign-in dialog hosting Google's rendered sign-in button.
/// Pops with the signed-in account, or null if the user dismisses it.
class WebSignInDialog extends StatefulWidget {
  final AuthCubit authCubit;

  const WebSignInDialog({Key? key, required this.authCubit}) : super(key: key);

  @override
  State<WebSignInDialog> createState() => _WebSignInDialogState();
}

class _WebSignInDialogState extends State<WebSignInDialog> {
  StreamSubscription<GoogleSignInAccount>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.authCubit.signInEvents.listen((account) {
      if (mounted) {
        Navigator.of(context).pop(account);
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Conectare cu Google"),
      content: SizedBox(
        width: 250,
        height: 60,
        child: Center(child: buildGoogleSignInButton()),
      ),
    );
  }
}
