import 'package:flutter/material.dart';

/// "Sign in with Google" button. On web it must stay an app button rather
/// than the Google-rendered one: the sign-in opens a token popup, which the
/// browser only allows straight from a click on our own handler.
Widget buildGoogleSignInButton({
  required VoidCallback onPressed,
  Widget? label,
}) {
  return FilledButton.icon(
    icon: const Icon(Icons.login),
    label: label ?? const Text('Sign in with Google'),
    onPressed: onPressed,
  );
}
