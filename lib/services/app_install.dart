// Барои веб `app_install_web.dart`, барои дигар платформаҳо (Windows, Android, iOS)
// `app_install_stub.dart` истифода мешавад.
export 'app_install_stub.dart' if (dart.library.js_interop) 'app_install_web.dart';
