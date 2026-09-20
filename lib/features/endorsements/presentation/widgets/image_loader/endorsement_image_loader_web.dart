import 'dart:convert';
import 'package:flutter/material.dart';

import 'endorsement_image_loader_interface.dart';

class WebEndorsementImageLoader implements EndorsementImageLoader {
  @override
  Widget buildImage(String path, {BoxFit fit = BoxFit.cover, double? width, double? height}) {
    if (path.startsWith('data:')) {
      final comma = path.indexOf(',');
      if (comma != -1) {
        final bytes = base64Decode(path.substring(comma + 1));
        return Image.memory(bytes, fit: fit, width: width, height: height);
      }
    }
    if (path.startsWith('http')) {
      return Image.network(path, fit: fit, width: width, height: height);
    }
    return Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      width: width,
      height: height,
      child: const Icon(Icons.description, color: Colors.grey),
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
    if (path.startsWith('http')) {
      return NetworkImage(path);
    }
    return null;
  }
}

EndorsementImageLoader getEndorsementImageLoader() => WebEndorsementImageLoader();

