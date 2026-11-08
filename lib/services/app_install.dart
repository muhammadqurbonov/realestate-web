// Ҳангоми build барои веб `app_install_web.dart`, барои дигар платформаҳо
// (Windows, Android, iOS) — `app_install_stub.dart` истифода мешавад,
// бинобар ин `dart:html` ба build-и дигар платформаҳо халал намерасонад.
export 'app_install_stub.dart' if (dart.library.html) 'app_install_web.dart';
