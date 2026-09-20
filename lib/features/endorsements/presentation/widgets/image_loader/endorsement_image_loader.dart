import 'endorsement_image_loader_interface.dart';
import 'endorsement_image_loader_stub.dart'
    if (dart.library.js_interop) 'endorsement_image_loader_web.dart'
    if (dart.library.io) 'endorsement_image_loader_native.dart';

export 'endorsement_image_loader_interface.dart';

final EndorsementImageLoader defaultImageLoader = getEndorsementImageLoader();

