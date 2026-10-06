import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/app_notification.dart';
import '../models/app_user.dart';
import '../models/client.dart';
import '../models/property.dart';
import 'firestore_service.dart';
import 'notification_seen_service.dart';

/// Маркази огоҳиномаҳо. Ду манбаъро якҷоя мекунад:
///  1) огоҳиномаҳои ширкат — "фалон менеҷер хонаи нав илова кард"
///     (худи иловаккунанда онро намебинад);
///  2) мувофиқатҳо — хонаи нав ба муштарии ҲАМИН менеҷер мувофиқ аст.
///     Ин дар дастгоҳи худи менеҷер ҳисоб мешавад (ӯ муштариёни худро
///     мехонад), бинобар ин ба қоидаҳои Firestore тағйирот лозим нест.
/// Агар хона ҳам мувофиқат дошта бошад, танҳо огоҳии мувофиқат нишон
/// дода мешавад (то такрор нашавад).
class NotificationCenter extends ChangeNotifier {
  final FirestoreService _fs = FirestoreService();
  final NotificationSeenService _seen = NotificationSeenService();

  AppUser? _user;
  StreamSubscription<List<AppNotification>>? _notifSub;
  StreamSubscription<List<Client>>? _clientSub;
  StreamSubscription<List<Property>>? _propSub;

  List<AppNotification> _company = [];
  List<Client> _clients = [];
  List<Property> _props = [];
  bool _gotNotif = false, _gotClients = false, _gotProps = false;
  bool _baselineDone = false;

  final Set<String> _known = {};
  final List<AppNotification> _pending = [];
  Timer? _debounce;

  // Огоҳиномаҳои аз ҷониби худи корбар нест кардашуда (танҳо дар ин дастгоҳ).
  Set<String> _dismissed = {};

  DateTime _lastSeen = DateTime.now();
  List<AppNotification> _items = [];
  bool _disposed = false;

  /// Вақте огоҳии НАВ меояд ва барнома кушода аст, садо мекунад.
  void Function(AppNotification latest, int more)? onIncoming;

  List<AppNotification> get items => _items;
  DateTime get lastSeen => _lastSeen;
  int get unreadCount => _items.where((n) => n.createdAt.isAfter(_lastSeen)).length;

  /// Аз ProxyProvider даъват мешавад; агар корбар тағйир наёфта бошад, коре намекунад.
  void attach(AppUser? user) {
    if (user?.uid == _user?.uid && user?.companyId == _user?.companyId) return;
    _stop();
    _user = user;
    if (user == null) {
      _items = [];
      _safeNotify();
      return;
    }
    _start(user);
  }

  Future<void> _start(AppUser user) async {
    final stored = await _seen.getLastSeen(user.uid);
    if (_user?.uid != user.uid || _disposed) return;
    if (stored == null) {
      // Дастгоҳи нав: огоҳиномаҳои пештара "надида" ҳисоб намешаванд.
      _lastSeen = DateTime.now();
      await _seen.setLastSeen(user.uid, _lastSeen);
    } else {
      _lastSeen = stored;
    }
    _dismissed = await _seen.getDismissed(user.uid);
    if (_user?.uid != user.uid || _disposed) return;

    _notifSub = _fs.companyNotifications(user.companyId).listen((v) {
      _company = v;
      _gotNotif = true;
      _rebuild();
    }, onError: (Object e) {
      debugPrint('Notifications stream error: $e');
      _gotNotif = true;
      _rebuild();
    });
    _clientSub = _fs.myClients(user.uid).listen((v) {
      _clients = v;
      _gotClients = true;
      _rebuild();
    }, onError: (Object e) {
      debugPrint('Clients stream error: $e');
      _gotClients = true;
      _rebuild();
    });
    _propSub = _fs.recentProperties(const Duration(days: 30)).listen((v) {
      _props = v;
      _gotProps = true;
      _rebuild();
    }, onError: (Object e) {
      debugPrint('Properties stream error: $e');
      _gotProps = true;
      _rebuild();
    });
  }

  void _stop() {
    _notifSub?.cancel();
    _clientSub?.cancel();
    _propSub?.cancel();
    _notifSub = _clientSub = _propSub = null;
    _debounce?.cancel();
    _pending.clear();
    _known.clear();
    _company = [];
    _clients = [];
    _props = [];
    _dismissed = {};
    _gotNotif = _gotClients = _gotProps = false;
    _baselineDone = false;
  }

  void _rebuild() {
    final user = _user;
    if (user == null) return;

    final matches = <AppNotification>[];
    final matchedPropIds = <String>{};
    for (final p in _props) {
      if (p.companyId != user.companyId || p.isSold) continue;
      for (final c in _clients) {
        // Танҳо хонаҳои баъд аз илова шудани муштарӣ омада.
        if (!p.createdAt.isAfter(c.createdAt)) continue;
        if (!c.matches(p)) continue;
        matchedPropIds.add(p.id);
        matches.add(AppNotification(
          id: 'match_${c.id}_${p.id}',
          companyId: p.companyId,
          propertyId: p.id,
          address: p.address,
          managerName: p.addedByName,
          addedByUid: p.addedByUid,
          clientName: c.fullName,
          type: kNotifClientMatch,
          createdAt: p.createdAt,
        ));
      }
    }

    final generic = _company.where((n) => n.addedByUid != user.uid && !matchedPropIds.contains(n.propertyId));
    final merged = [...matches, ...generic]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _items = merged.where((n) => !_dismissed.contains(n.id)).take(100).toList();

    if (_gotNotif && _gotClients && _gotProps) {
      if (!_baselineDone) {
        // Аввалин боршавӣ — таърихро бе садо қабул мекунем.
        _known.addAll(_items.map((e) => e.id));
        _baselineDone = true;
      } else {
        for (final n in _items) {
          final fresh = _known.add(n.id);
          if (fresh && n.createdAt.isAfter(_lastSeen) && n.addedByUid != user.uid) {
            _pending.add(n);
          }
        }
        if (_pending.isNotEmpty) {
          // Каме интизор мешавем, то ҳарду навъи огоҳӣ (умумӣ + мувофиқат) омада расанд.
          _debounce?.cancel();
          _debounce = Timer(const Duration(milliseconds: 700), _flush);
        }
      }
    }
    _safeNotify();
  }

  void _flush() {
    final list = List<AppNotification>.of(_pending);
    _pending.clear();
    final matchProps = {for (final n in list) if (n.isClientMatch) n.propertyId};
    final show = list.where((n) => n.isClientMatch || !matchProps.contains(n.propertyId)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (show.isEmpty) return;
    onIncoming?.call(show.first, show.length - 1);
  }

  /// Як огоҳиномаро нест мекунад (танҳо барои ин корбар, дар ин дастгоҳ).
  Future<void> dismiss(String id) async {
    final user = _user;
    if (user == null) return;
    _dismissed.add(id);
    _items = _items.where((n) => n.id != id).toList();
    notifyListeners(); // Dismissible талаб мекунад, ки элемент фавран аз дарахт гирад.
    await _seen.setDismissed(user.uid, _dismissed);
  }

  /// Бозгардонидани огоҳиномаи нестшуда («Бекор кардан»).
  Future<void> restore(String id) async {
    final user = _user;
    if (user == null) return;
    _dismissed.remove(id);
    _rebuild();
    await _seen.setDismissed(user.uid, _dismissed);
  }

  /// Ҳамаи огоҳиномаҳои ҳозираро нест мекунад.
  Future<void> dismissAll() async {
    final user = _user;
    if (user == null) return;
    _dismissed.addAll(_items.map((n) => n.id));
    _items = [];
    notifyListeners();
    await _seen.setDismissed(user.uid, _dismissed);
  }

  /// Ҳама "дида шуд" — тегчаи зангӯла нест мешавад.
  Future<void> markAllSeen() async {
    final user = _user;
    if (user == null) return;
    _lastSeen = DateTime.now();
    _safeNotify();
    await _seen.setLastSeen(user.uid, _lastSeen);
  }

  void _safeNotify() {
    // Дар вақти сохтани виджетҳо даъват шуда метавонад — аз ин рӯ дар microtask.
    Future.microtask(() {
      if (!_disposed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _stop();
    super.dispose();
  }
}
