import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

import 'endorsement_image_loader_interface.dart';

class NativeEndorsementImageLoader implements EndorsementImageLoader {
  @override
  Widget buildImage(String path, {BoxFit fit = BoxFit.cover, double? width, double? height}) {
    if (path.startsWith('data:')) {
      final comma = path.indexOf(',');
      if (comma != -1) {
        final bytes = base64Decode(path.substring(comma + 1));
        return Image.memory(bytes, fit: fit, width: width, height: height);
      }
    }
    if (path.startsWith('memory://') || path.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        width: width,
        height: height,
        child: const Icon(Icons.description, color: Colors.grey),
      );
    }
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(file, fit: fit, width: width, height: height);
    }
    return Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      width: width,
      height: height,
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }

  @override
  ImageProvider? getImageProvider(String path) {
    if (path.startsWith('data:')) {
      final comma = path.indexOf(',');
      if (comma != -1) {
        final bytes = base64Decode(path.substring(comma + 1));
        return MemoryImage(bytes);
      }
    }
    if (path.startsWith('memory://') || path.isEmpty) {
      return null;
    }
    final file = File(path);
    if (file.existsSync()) {
      return FileImage(file);
    }
    return null;
  }
}

EndorsementImageLoader getEndorsementImageLoader() => NativeEndorsementImageLoader();

