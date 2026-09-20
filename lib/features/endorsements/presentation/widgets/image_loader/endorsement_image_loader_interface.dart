import 'package:flutter/widgets.dart';

abstract class EndorsementImageLoader {
  Widget buildImage(String path, {BoxFit fit = BoxFit.cover, double? width, double? height});
  ImageProvider? getImageProvider(String path);
}

