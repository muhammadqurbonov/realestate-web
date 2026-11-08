import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Насбкунии барнома ҳамчун PWA (экрани асосии телефон).
class AppInstall {
  static bool _listening = false;

  static JSObject get _window => globalContext;

  static JSObject? get _navigator => _window.getProperty<JSObject?>('navigator'.toJS);

  static bool get isWeb => true;

  /// Агар барнома аллакай аз экрани асосӣ кушода шуда бошад.
  static bool get isStandalone {
    try {
      final mq = _window.callMethod<JSObject>('matchMedia'.toJS, '(display-mode: standalone)'.toJS);
      if (mq.getProperty<JSBoolean>('matches'.toJS).toDart) return true;
      final standalone = _navigator?.getProperty<JSAny?>('standalone'.toJS); // iOS
      return standalone.dartify() == true;
    } catch (_) {
      return false;
    }
  }

  static bool get isIOS {
    try {
      final nav = _navigator;
      if (nav == null) return false;
      final ua = nav.getProperty<JSString>('userAgent'.toJS).toDart;
      if (RegExp(r'iPhone|iPad|iPod', caseSensitive: false).hasMatch(ua)) return true;
      final platform = nav.getProperty<JSString?>('platform'.toJS)?.toDart ?? '';
      final touch = nav.getProperty<JSNumber?>('maxTouchPoints'.toJS)?.toDartInt ?? 0;
      return platform == 'MacIntel' && touch > 1;
    } catch (_) {
      return false;
    }
  }

  static bool get canPrompt {
    try {
      return _window.getProperty<JSAny?>('deferredPrompt'.toJS) != null;
    } catch (_) {
      return false;
    }
  }

  static void listen(void Function() onChange) {
    if (_listening) return;
    _listening = true;

    final JSFunction onBeforeInstall = (JSObject event) {
      event.callMethod<JSAny?>('preventDefault'.toJS);
      _window.setProperty('deferredPrompt'.toJS, event);
      onChange();
    }.toJS;

    final JSFunction onInstalled = (JSObject event) {
      _window.setProperty('deferredPrompt'.toJS, null);
      onChange();
    }.toJS;

    _window.callMethod<JSAny?>('addEventListener'.toJS, 'beforeinstallprompt'.toJS, onBeforeInstall);
    _window.callMethod<JSAny?>('addEventListener'.toJS, 'appinstalled'.toJS, onInstalled);
  }

  static Future<bool> prompt() async {
    final event = _window.getProperty<JSObject?>('deferredPrompt'.toJS);
    if (event == null) return false;
    try {
      event.callMethod<JSAny?>('prompt'.toJS);
      final choice = await event.getProperty<JSPromise>('userChoice'.toJS).toDart;
      _window.setProperty('deferredPrompt'.toJS, null);
      return (choice as JSObject).getProperty<JSString>('outcome'.toJS).toDart == 'accepted';
    } catch (_) {
      return false;
    }
  }
}