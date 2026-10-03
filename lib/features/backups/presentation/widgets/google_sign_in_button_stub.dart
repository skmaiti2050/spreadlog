import 'package:flutter/material.dart';

/// Stub implementation of Google Sign In button for non-web platforms (Android, iOS, Desktop).
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
