import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// navigator.canShare({files: [...]}) — Chrome/Edge/Safari дар телефон ва Chrome дар Windows
/// дастгирӣ мекунанд; Firefox-и компютерӣ не (он гоҳ линкҳо фиристода мешаванд).
bool canShareFilesNow() {
  try {
    final nav = globalContext.getProperty<JSObject?>('navigator'.toJS);
    if (nav == null || !nav.has('share') || !nav.has('canShare')) return false;
    final fileCtor = globalContext.getProperty<JSFunction?>('File'.toJS);
    if (fileCtor == null) return false;

    final opts = <String, Object?>{'type': 'image/jpeg'}.jsify() as JSObject;
    final file = fileCtor.callAsConstructor<JSObject>(<JSAny?>[].toJS, 'photo.jpg'.toJS, opts);

    final data = <String, Object?>{}.jsify() as JSObject;
    data.setProperty('files'.toJS, <JSAny?>[file].toJS);
    return nav.callMethod<JSBoolean>('canShare'.toJS, data).toDart;
  } catch (_) {
    return false;
  }
}
