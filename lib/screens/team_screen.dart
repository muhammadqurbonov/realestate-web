import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/locale_service.dart';
import '../l10n/app_strings.dart';
import '../models/app_user.dart';

const _kPrimary = Color(0xFF0F6B5C);

/// Рӯйхати менеҷерону админҳои ширкат — танҳо суперадмин/админ мебинад.
/// Суперадмин метавонад ҳам менеҷер, ҳам админро ҳазф кунад.
/// Админ танҳо менеҷеронро ҳазф карда метавонад (на админи дигар, на
/// суперадминро).
class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleService>().strings;
    final me = context.watch<AuthService>().currentUser;
    final firestoreService = FirestoreService();

    if (me == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(title: Text(t.locale == AppLocale.ru ? 'Команда' : 'Кормандон')),
      body: StreamBuilder<List<AppUser>>(
        stream: firestoreService.companyUsers(me.companyId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('${snapshot.error}', style: const TextStyle(color: Colors.red)),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final isMe = user.uid == me.uid;

              // Иҷозати ҳазф: суперадмин ҳамаро (ба ҷуз худаш) ҳазф
              // мекунад; админ танҳо менеҷеронро.
              final canDelete = !isMe &&
                  ((me.role == UserRole.superAdmin) ||
                      (me.role == UserRole.admin && user.role == UserRole.manager));

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: _kPrimary.withOpacity(0.1),
                      child: Text(
                        user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                        style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                              if (isMe) ...[
                                const SizedBox(width: 6),
                                Text('(${t.locale == AppLocale.ru ? "вы" : "шумо"})',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ],
                          ),
                          Text(user.phone, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _roleColor(user.role).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _roleLabel(user.role, t),
                        style: TextStyle(color: _roleColor(user.role), fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (canDelete) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        onPressed: () => _confirmDelete(context, user, firestoreService, t),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _roleLabel(UserRole role, AppStrings t) {
    switch (role) {
      case UserRole.superAdmin:
        return t.locale == AppLocale.ru ? 'Суперадмин' : 'Суперадмин';
      case UserRole.admin:
        return t.locale == AppLocale.ru ? 'Админ' : 'Админ';
      case UserRole.manager:
        return t.locale == AppLocale.ru ? 'Менеджер' : 'Менеҷер';
    }
  }

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return Colors.purple;
      case UserRole.admin:
        return Colors.orange;
      case UserRole.manager:
        return _kPrimary;
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppUser user,
    FirestoreService firestoreService,
    AppStrings t,
  ) async {
    final isRu = t.locale == AppLocale.ru;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isRu ? 'Удалить ${user.fullName}?' : '${user.fullName}-ро ҳазф кунем?'),
        content: Text(isRu
            ? 'Он потеряет доступ к приложению.'
            : 'Ӯ дигар ба барнома дастрасӣ надорад.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(isRu ? 'Отмена' : 'Бекор')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isRu ? 'Удалить' : 'Ҳазф', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await firestoreService.deleteUserDoc(user.uid);
    }
  }
}
