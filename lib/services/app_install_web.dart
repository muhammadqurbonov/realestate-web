import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Насбкунии барнома ҳамчун PWA (экрани асосии телефон).
///
/// Android / Chrome / Edge: ҳодисаи `beforeinstallprompt` нигоҳ дошта мешавад ва бо як
/// зеркунӣ диалоги насб кушода мешавад. iPhone/iPad (Safari) чунин имкон надорад,
/// онҳо дастури «Илова ба экрани асосӣ»-ро мебинанд.
///
/// Бе `dart:html` ва `dart:js_util` навишта шудааст (онҳо дар Dart-и нав нестанд).
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
      // iPadOS 13+ худро Mac муаррифӣ мекунад, вале экрани ламсӣ дорад.
      final platform = nav.getProperty<JSString?>('platform'.toJS)?.toDart ?? '';
      final touch = nav.getProperty<JSNumber?>('maxTouchPoints'.toJS)?.toDartInt ?? 0;
      return platform == 'MacIntel' && touch > 1;
    } catch (_) {
      return false;
    }
  }

  /// Браузер насбро пешниҳод кардааст (ҳодиса дар index.html ё ин ҷо гирифта шудааст).
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

  /// Диалоги насби браузерро мекушояд. true — агар корбар розӣ шуд.
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
