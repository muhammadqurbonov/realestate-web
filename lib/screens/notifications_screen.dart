import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/locale_service.dart';
import '../services/notification_center.dart';
import '../l10n/app_strings.dart';
import '../models/app_notification.dart';
import 'property_detail_screen.dart';

const _kPrimary = Color(0xFF1E6FD9);
const _kMatch = Color(0xFF12A36B);

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  /// Вақти "дидашуд"-и пеш аз кушодан — барои нишон додани огоҳиҳои нав.
  late final DateTime _openedLastSeen;

  @override
  void initState() {
    super.initState();
    final center = context.read<NotificationCenter>();
    _openedLastSeen = center.lastSeen;
    // Кушодани ин саҳифа маънои "ҳама дида шуд"-ро дорад.
    WidgetsBinding.instance.addPostFrameCallback((_) => center.markAllSeen());
  }

  String _timeAgo(DateTime dt, bool isRu) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return isRu ? 'только что' : 'ҳозир';
    if (diff.inMinutes < 60) return '${diff.inMinutes} ${isRu ? "мин. назад" : "дақ. пеш"}';
    if (diff.inHours < 24) return '${diff.inHours} ${isRu ? "ч. назад" : "соат пеш"}';
    return '${diff.inDays} ${isRu ? "дн. назад" : "рӯз пеш"}';
  }

  Future<void> _open(BuildContext context, AppNotification n) async {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return;
    final property = await FirestoreService().getProperty(n.propertyId);
    if (property != null && context.mounted) {
      final canSeePrivate = user.uid == property.addedByUid || user.canManageManagers;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PropertyDetailScreen(property: property, canSeePrivate: canSeePrivate),
        ),
      );
    }
  }

  void _delete(BuildContext context, AppNotification n, bool isRu) {
    final center = context.read<NotificationCenter>();
    center.dismiss(n.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(isRu ? 'Уведомление удалено' : 'Огоҳинома нест карда шуд'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: isRu ? 'Отменить' : 'Бекор кардан',
          textColor: Colors.white,
          onPressed: () => center.restore(n.id),
        ),
      ));
  }

  Future<void> _deleteAll(BuildContext context, bool isRu) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isRu ? 'Удалить все?' : 'Ҳамаро нест кунем?'),
        content: Text(isRu
            ? 'Все уведомления будут удалены только у вас.'
            : 'Ҳамаи огоҳиномаҳо танҳо аз ҳисоби шумо нест мешаванд.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(isRu ? 'Отмена' : 'Бекор')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isRu ? 'Удалить' : 'Ҳазф'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) context.read<NotificationCenter>().dismissAll();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleService>().strings;
    final isRu = t.locale == AppLocale.ru;
    final items = context.watch<NotificationCenter>().items;

    return Scaffold(
      appBar: AppBar(
        title: Text(isRu ? 'Уведомления' : 'Огоҳиномаҳо'),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              tooltip: isRu ? 'Удалить все' : 'Ҳамаро нест кардан',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _deleteAll(context, isRu),
            ),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Text(isRu ? 'Уведомлений пока нет' : 'Ҳанӯз огоҳиномае нест',
                  style: const TextStyle(color: Colors.grey)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final n = items[index];
                final isNew = n.createdAt.isAfter(_openedLastSeen);
                final accent = n.isClientMatch ? _kMatch : _kPrimary;
                return Dismissible(
                  key: ValueKey(n.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _delete(context, n, isRu),
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.only(right: 20),
                    alignment: Alignment.centerRight,
                    decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _open(context, n),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(isNew ? 0.9 : 0.72),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isNew ? accent.withOpacity(0.6) : const Color(0xCCFFFFFF), width: isNew ? 1.4 : 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(n.isClientMatch ? Icons.person_search_rounded : Icons.home_rounded,
                              color: accent, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.title(isRu),
                                  style: TextStyle(fontWeight: isNew ? FontWeight.w800 : FontWeight.w700, fontSize: 13.5)),
                              const SizedBox(height: 2),
                              Text(n.address, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                              if (n.isClientMatch)
                                Text(
                                  (isRu ? 'Добавил(а): ' : 'Илова кард: ') + n.managerName,
                                  style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
                                ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(_timeAgo(n.createdAt, isRu),
                                style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                            if (isNew)
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                              ),
                          ],
                        ),
                        IconButton(
                          tooltip: t.t('delete'),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          icon: Icon(Icons.close_rounded, size: 20, color: Colors.grey[600]),
                          onPressed: () => _delete(context, n, isRu),
                        ),
                      ],
                    ),
                  ),
                  ),
                );
              },
            ),
    );
  }
}
