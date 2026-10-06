import 'package:shared_preferences/shared_preferences.dart';

/// "Дидашуд ё не" ба ҳар дастгоҳ ва ҳар корбар хос аст — дар
/// SharedPreferences (маҳаллӣ) нигоҳ дошта мешавад.
class NotificationSeenService {
  String _key(String uid) => 'notifications_last_seen_ms_$uid';

  /// null — агар ин корбар дар ин дастгоҳ ҳеҷ гоҳ огоҳиномаҳоро накушодааст.
  Future<DateTime?> getLastSeen(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_key(uid));
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  String _dKey(String uid) => 'notifications_dismissed_$uid';

  Future<Set<String>> getDismissed(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_dKey(uid)) ?? const <String>[]).toSet();
  }

  Future<void> setDismissed(String uid, Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    // Рӯйхат бепоён нашавад: танҳо 500-и охир нигоҳ дошта мешавад.
    final list = ids.toList();
    final trimmed = list.length > 500 ? list.sublist(list.length - 500) : list;
    await prefs.setStringList(_dKey(uid), trimmed);
  }

  Future<void> setLastSeen(String uid, DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key(uid), time.millisecondsSinceEpoch);
  }
}
