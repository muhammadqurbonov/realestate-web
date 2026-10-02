import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_strings.dart';

/// Идоракунии забони интихобкардаи корбар.
class LocaleService extends ChangeNotifier {
  static const _prefsKey = 'app_locale';

  AppLocale _locale = AppLocale.ru;
  AppLocale get locale => _locale;
  AppStrings get strings => AppStrings(_locale);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved == 'tj') {
      _locale = AppLocale.tj;
    } else {
      _locale = AppLocale.ru;
    }
    notifyListeners();
  }

  Future<void> setLocale(AppLocale locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale == AppLocale.ru ? 'ru' : 'tj');
    notifyListeners();
  }
}
