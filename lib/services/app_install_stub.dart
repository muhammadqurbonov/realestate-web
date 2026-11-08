/// Платформаҳои ғайриве: насбкунии PWA лозим нест.
class AppInstall {
  static bool get isWeb => false;
  static bool get isStandalone => false;
  static bool get isIOS => false;
  static bool get canPrompt => false;

  static void listen(void Function() onChange) {}

  static Future<bool> prompt() async => false;
}
