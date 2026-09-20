import 'package:shared_preferences/shared_preferences.dart';

/// Огоҳиномаҳо дар Firestore умумианд (ба ҳамаи кормандони ширкат
/// намоён), вале "дидашуд ё не" ба ҳар дастгоҳ хос аст — бинобар ин
/// дар SharedPreferences (маҳаллӣ) нигоҳ дошта мешавад, на дар сервер.
class NotificationSeenService {
  static const _prefsKey = 'notifications_last_seen_ms';

  Future<DateTime> getLastSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_prefsKey);
    if (ms == null) return DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> markSeenNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, DateTime.now().millisecondsSinceEpoch);
  }
}
