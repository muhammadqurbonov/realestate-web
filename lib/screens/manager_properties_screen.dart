import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/locale_service.dart';
import '../models/app_user.dart';
import '../models/property.dart';
import '../widgets/property_card.dart';
import '../l10n/app_strings.dart';

const _kPrimary = Color(0xFF1E6FD9);

/// Рӯйхати менеҷерон — зер кардани яке хонаҳои ҳамон менеҷерро
/// нишон медиҳад.
class ManagerPropertiesScreen extends StatelessWidget {
  const ManagerPropertiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleService>().strings;
    final user = context.watch<AuthService>().currentUser;
    final firestoreService = FirestoreService();

    if (user == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(title: Text(t.t('manager_properties_title'))),
      body: StreamBuilder<List<AppUser>>(
        stream: firestoreService.companyUsers(user.companyId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final managerUser = users[index];
              final isMe = managerUser.uid == user.uid;
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _ManagerPropertiesListScreen(manager: managerUser, isOwn: isMe),
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.72),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xCCFFFFFF)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: _kPrimary.withOpacity(0.1),
                        child: Text(
                          managerUser.fullName.isNotEmpty ? managerUser.fullName[0].toUpperCase() : '?',
                          style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMe ? '${managerUser.fullName} (${t.t('you')})' : managerUser.fullName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(managerUser.phone, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Colors.grey),
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

class _ManagerPropertiesListScreen extends StatelessWidget {
  final AppUser manager;
  final bool isOwn;
  const _ManagerPropertiesListScreen({required this.manager, required this.isOwn});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleService>().strings;
    final currentUser = context.watch<AuthService>().currentUser;
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: Text(manager.fullName)),
      body: StreamBuilder<List<Property>>(
        stream: firestoreService.myProperties(manager.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final properties = snapshot.data!;
          if (properties.isEmpty) {
            return Center(child: Text(t.t('no_results'), style: const TextStyle(color: Colors.grey)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: properties.length,
            itemBuilder: (context, index) {
              final property = properties[index];
              final canSeePrivate = isOwn || (currentUser?.canManageManagers ?? false);
              return PropertyCard(property: property, canSeePrivate: canSeePrivate);
            },
          );
        },
      ),
    );
  }
}
