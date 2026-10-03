import 'package:flutter/material.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart' as gsi_web;

/// Web implementation of Google Sign In button using official Google Identity Services (GIS) button.
Widget buildGoogleSignInButton({
  required VoidCallback onPressed,
  Widget? label,
}) {
  try {
    final plugin = GoogleSignInPlatform.instance;
    if (plugin is gsi_web.GoogleSignInPlugin) {
      return SizedBox(
        height: 40,
        child: plugin.renderButton(),
      );
    }
  } catch (e) {
    debugPrint('Could not render GIS web button: $e');
  }

  return FilledButton.icon(
    icon: const Icon(Icons.login),
    label: label ?? const Text('Sign in with Google'),
    onPressed: onPressed,
  );
}
