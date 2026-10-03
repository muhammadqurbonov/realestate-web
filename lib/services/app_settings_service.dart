import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Намуди фони барнома.
enum BackgroundStyle { ocean, glass }

/// Танзимоти намуди зоҳирии барнома (дар дастгоҳ нигоҳ дошта мешавад).
class AppSettingsService extends ChangeNotifier {
  static const _kBg = 'bg_style';
  static const _kAnim = 'bg_animation';
  static const _kScale = 'text_scale';

  BackgroundStyle _bg = BackgroundStyle.ocean;
  bool _animations = true;
  double _textScale = 1.0;

  BackgroundStyle get backgroundStyle => _bg;
  bool get animationsEnabled => _animations;
  double get textScale => _textScale;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _bg = p.getString(_kBg) == 'glass' ? BackgroundStyle.glass : BackgroundStyle.ocean;
    _animations = p.getBool(_kAnim) ?? true;
    _textScale = p.getDouble(_kScale) ?? 1.0;
    notifyListeners();
  }

  Future<void> setBackgroundStyle(BackgroundStyle v) async {
    _bg = v;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_kBg, v == BackgroundStyle.glass ? 'glass' : 'ocean');
  }

  Future<void> setAnimationsEnabled(bool v) async {
    _animations = v;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kAnim, v);
  }

  Future<void> setTextScale(double v) async {
    _textScale = v;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kScale, v);
  }

  Future<void> resetAppearance() async {
    _bg = BackgroundStyle.ocean;
    _animations = true;
    _textScale = 1.0;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.remove(_kBg);
    await p.remove(_kAnim);
    await p.remove(_kScale);
  }
}
