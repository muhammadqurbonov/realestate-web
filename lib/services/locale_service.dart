import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_strings.dart';

/// Идоракунии забони интихобкардаи корбар.
/// Ҳар корбар (менеҷер/админ) метавонад забони худро мустақилона
/// интихоб кунад — интихоб дар дастгоҳ (SharedPreferences) нигоҳ дошта мешавад.
class LocaleService extends ChangeNotifier {
  static const _prefsKey = 'app_locale';

  AppLocale _locale = AppLocale.tj;
  AppLocale get locale => _locale;
  AppStrings get strings => AppStrings(_locale);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved == 'ru') {
      _locale = AppLocale.ru;
    } else {
      _locale = AppLocale.tj;
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
