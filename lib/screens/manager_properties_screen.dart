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

/// Як сатри рӯйхати менеҷерон.
class _ManagerEntry {
  final String uid;
  final String name;
  final String phone; // танҳо барои админ/суперадмин (аз users)
  final int count; // шумораи хонаҳо (барои менеҷер — аз properties)
  const _ManagerEntry({required this.uid, required this.name, this.phone = '', this.count = 0});
}

/// Рӯйхати менеҷерон — зер кардани яке хонаҳои ҳамон менеҷерро нишон медиҳад.
///
/// Админ/суперадмин: рӯйхат аз `users` (бо телефон).
/// Менеҷери оддӣ: қоидаҳои Firestore хондани `users`-ро манъ мекунанд,
/// бинобар ин рӯйхат аз хонаҳои ОММАВӢ сохта мешавад (ном + шумора).
/// Маълумоти шахсӣ (рақами соҳибхона, комиссия) ҳамеша пинҳон мемонад.
class ManagerPropertiesScreen extends StatelessWidget {
  const ManagerPropertiesScreen({super.key});

  Stream<List<_ManagerEntry>> _entries(AppUser user, FirestoreService fs) {
    if (user.canManageManagers) {
      return fs.companyUsers(user.companyId).map((users) => users
          .map((u) => _ManagerEntry(uid: u.uid, name: u.fullName, phone: u.phone))
          .toList());
    }
    return fs.allProperties().map((props) {
      final byUid = <String, _ManagerEntry>{};
      for (final p in props) {
        if (p.companyId != user.companyId || p.addedByUid.isEmpty) continue;
        final prev = byUid[p.addedByUid];
        byUid[p.addedByUid] = _ManagerEntry(
          uid: p.addedByUid,
          name: prev?.name.isNotEmpty == true ? prev!.name : p.addedByName,
          count: (prev?.count ?? 0) + 1,
        );
      }
      return byUid.values.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleService>().strings;
    final isRu = t.locale == AppLocale.ru;
    final user = context.watch<AuthService>().currentUser;
    final firestoreService = FirestoreService();

    if (user == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(title: Text(t.t('manager_properties_title'))),
      body: StreamBuilder<List<_ManagerEntry>>(
        stream: _entries(user, firestoreService),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '${t.t('no_access')}\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          // Худи корбар аввал меояд.
          final entries = [...snapshot.data!]..sort((a, b) {
              if (a.uid == user.uid) return -1;
              if (b.uid == user.uid) return 1;
              return a.name.compareTo(b.name);
            });
          if (entries.isEmpty) {
            return Center(child: Text(t.t('no_results'), style: const TextStyle(color: Colors.grey)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final m = entries[index];
              final isMe = m.uid == user.uid;
              final subtitle = m.phone.isNotEmpty
                  ? m.phone
                  : '${m.count} ${isRu ? "объектов" : "хона"}';
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _ManagerPropertiesListScreen(uid: m.uid, name: m.name, isOwn: isMe),
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
                          m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                          style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMe ? '${m.name} (${t.t('you')})' : m.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
  final String uid;
  final String name;
  final bool isOwn;
  const _ManagerPropertiesListScreen({required this.uid, required this.name, required this.isOwn});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleService>().strings;
    final currentUser = context.watch<AuthService>().currentUser;
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: StreamBuilder<List<Property>>(
        stream: firestoreService.myProperties(uid),
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
              // Маълумоти шахсӣ: танҳо соҳиб ва админ/суперадмин.
              final canSeePrivate = isOwn || (currentUser?.canManageManagers ?? false);
              return PropertyCard(property: property, canSeePrivate: canSeePrivate);
            },
          );
        },
      ),
    );
  }
}
