import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_seen_service.dart';
import '../services/locale_service.dart';
import '../l10n/app_strings.dart';
import '../models/app_notification.dart';
import 'property_detail_screen.dart';

const _kPrimary = Color(0xFF0F6B5C);

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Кушодани ин саҳифа маънои "ҳама дида шуд"-ро дорад.
    NotificationSeenService().markSeenNow();
  }

  String _timeAgo(DateTime dt, bool isRu) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return isRu ? 'только что' : 'ҳозир';
    if (diff.inMinutes < 60) return '${diff.inMinutes} ${isRu ? "мин. назад" : "дақ. пеш"}';
    if (diff.inHours < 24) return '${diff.inHours} ${isRu ? "ч. назад" : "соат пеш"}';
    return '${diff.inDays} ${isRu ? "дн. назад" : "рӯз пеш"}';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleService>().strings;
    final user = context.watch<AuthService>().currentUser;
    final firestoreService = FirestoreService();
    final isRu = t.locale == AppLocale.ru;

    if (user == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(title: Text(isRu ? 'Уведомления' : 'Огоҳиномаҳо')),
      body: StreamBuilder<List<AppNotification>>(
        stream: firestoreService.companyNotifications(user.companyId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return Center(
              child: Text(isRu ? 'Уведомлений пока нет' : 'Ҳанӯз огоҳиномае нест',
                  style: const TextStyle(color: Colors.grey)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final n = items[index];
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  final property = await firestoreService.getProperty(n.propertyId);
                  if (property != null && context.mounted) {
                    final canSeePrivate = user.uid == property.addedByUid || user.canManageManagers;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PropertyDetailScreen(property: property, canSeePrivate: canSeePrivate),
                      ),
                    );
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _kPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.home_rounded, color: _kPrimary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                      text: n.managerName,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                                  TextSpan(
                                    text: isRu ? ' добавил(а) новый объект' : ' хонаи нав илова кард',
                                    style: const TextStyle(fontSize: 13.5),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(n.address, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                          ],
                        ),
                      ),
                      Text(_timeAgo(n.createdAt, isRu),
                          style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
