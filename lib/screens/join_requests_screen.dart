import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/locale_service.dart';
import '../l10n/app_strings.dart';
import '../models/app_user.dart';

/// Дархостҳои воридшавӣ — танҳо барои админ/суперадмин.
/// Менеҷери нав то қабул шуданаш хона/муштарӣ илова карда наметавонад.
class JoinRequestsScreen extends StatelessWidget {
  const JoinRequestsScreen({super.key});

  String _ago(DateTime? dt, bool isRu) {
    if (dt == null || dt.year < 2000) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return isRu ? 'только что' : 'ҳозир';
    if (diff.inMinutes < 60) return '${diff.inMinutes} ${isRu ? "мин. назад" : "дақ. пеш"}';
    if (diff.inHours < 24) return '${diff.inHours} ${isRu ? "ч. назад" : "соат пеш"}';
    return '${diff.inDays} ${isRu ? "дн. назад" : "рӯз пеш"}';
  }

  Future<void> _approve(BuildContext context, AppUser u, bool isRu) async {
    final auth = context.read<AuthService>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await auth.approveUser(u.uid);
      messenger.showSnackBar(SnackBar(
        content: Text(isRu ? '${u.fullName} принят(а) в команду' : '${u.fullName} ба дастаи кормандон қабул шуд'),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _reject(BuildContext context, AppUser u, bool isRu) async {
    final auth = context.read<AuthService>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isRu ? 'Отклонить заявку ${u.fullName}?' : 'Дархости ${u.fullName}-ро рад мекунем?'),
        content: Text(isRu
            ? 'Заявка будет удалена, человек не сможет войти.'
            : 'Дархост нест мешавад ва шахс ворид шуда наметавонад.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(isRu ? 'Отмена' : 'Бекор')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isRu ? 'Отклонить' : 'Рад кардан', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await auth.rejectUser(u.uid);
      messenger.showSnackBar(SnackBar(content: Text(isRu ? 'Заявка отклонена' : 'Дархост рад карда шуд')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleService>().strings;
    final isRu = t.locale == AppLocale.ru;
    final me = context.watch<AuthService>().currentUser;
    if (me == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(title: Text(isRu ? 'Заявки на вход' : 'Дархостҳои воридшавӣ')),
      body: StreamBuilder<List<AppUser>>(
        stream: FirestoreService().companyUsers(me.companyId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('${snapshot.error}', style: const TextStyle(color: Colors.red))));
          }
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final pending = snapshot.data!.where((u) => !u.approved).toList()
            ..sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
          if (pending.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.how_to_reg_outlined, size: 54, color: Colors.grey[500]),
                  const SizedBox(height: 10),
                  Text(isRu ? 'Новых заявок нет' : 'Дархости нав нест', style: const TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pending.length,
            itemBuilder: (context, i) {
              final u = pending[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.78),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.orange.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.orange.withOpacity(0.15),
                          child: Text(u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                              if (u.phone.isNotEmpty) Text(u.phone, style: const TextStyle(fontSize: 12.5)),
                              if (u.email.isNotEmpty) Text(u.email, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                            ],
                          ),
                        ),
                        Text(_ago(u.createdAt, isRu), style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _reject(context, u, isRu),
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: Text(isRu ? 'Отклонить' : 'Рад кардан'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: BorderSide(color: Colors.red.shade200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _approve(context, u, isRu),
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: Text(isRu ? 'Принять' : 'Қабул кардан'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF12A36B),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
