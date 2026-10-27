import 'package:flutter/widgets.dart';

abstract class EndorsementImageLoader {
  /// [cacheWidth] decodes the image at that many physical pixels wide
  /// instead of full resolution; use it for thumbnails.
  Widget buildImage(
    String path, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    int? cacheWidth,
  });
  ImageProvider? getImageProvider(String path);
}

