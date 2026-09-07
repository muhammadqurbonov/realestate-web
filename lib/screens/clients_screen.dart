import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/locale_service.dart';
import '../models/client.dart';
import '../models/property.dart';
import '../widgets/property_card.dart';

const _kPrimary = Color(0xFF0F6B5C);

class ClientsScreen extends StatelessWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleService>().strings;
    final user = context.watch<AuthService>().currentUser;
    final firestoreService = FirestoreService();

    if (user == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(title: Text(t.t('clients'))),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _kPrimary,
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) => _AddClientSheet(companyId: user.companyId, addedByUid: user.uid),
        ),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Client>>(
        stream: firestoreService.companyClients(user.companyId),
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
          final clients = snapshot.data!;
          if (clients.isEmpty) {
            return const Center(child: Icon(Icons.people_outline, size: 48, color: Colors.grey));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: clients.length,
            itemBuilder: (context, index) {
              final client = clients[index];
              final canDelete = user.uid == client.addedByUid || user.canManageManagers;
              return _ClientTile(
                client: client,
                firestoreService: firestoreService,
                canDelete: canDelete,
              );
            },
          );
        },
      ),
    );
  }
}

class _ClientTile extends StatelessWidget {
  final Client client;
  final FirestoreService firestoreService;
  final bool canDelete;
  const _ClientTile({required this.client, required this.firestoreService, required this.canDelete});

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${client.fullName}-ро ҳазф кунем?'),
        content: const Text('Ин амалро баргардонидан мумкин нест.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Бекор')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ҳазф', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await firestoreService.deleteClient(client.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleService>().strings;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        shape: const Border(),
        title: Text(client.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (client.phone.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 14, color: _kPrimary),
                    const SizedBox(width: 4),
                    Text(client.phone, style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              const SizedBox(height: 2),
              Text(
                '${client.minRooms}-${client.maxRooms} ${t.t('property_rooms').toLowerCase()} · ${client.minBudget.toStringAsFixed(0)}-${client.maxBudget.toStringAsFixed(0)} ${t.t('somoni')}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        trailing: canDelete
            ? IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: () => _confirmDelete(context),
              )
            : const Icon(Icons.expand_more),
        children: [
          FutureBuilder<List<Property>>(
            future: firestoreService.matchPropertiesForClient(client),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                );
              }
              final matches = snapshot.data!;
              if (matches.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text('—', style: TextStyle(color: Colors.grey)),
                );
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  children: matches.map((p) => PropertyCard(property: p)).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AddClientSheet extends StatefulWidget {
  final String companyId;
  final String addedByUid;
  const _AddClientSheet({required this.companyId, required this.addedByUid});

  @override
  State<_AddClientSheet> createState() => _AddClientSheetState();
}

class _AddClientSheetState extends State<_AddClientSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _minRoomsController = TextEditingController();
  final _maxRoomsController = TextEditingController();
  final _minBudgetController = TextEditingController();
  final _maxBudgetController = TextEditingController();
  final _areaController = TextEditingController();
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    final client = Client(
      id: '',
      companyId: widget.companyId,
      addedByUid: widget.addedByUid,
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      minRooms: int.tryParse(_minRoomsController.text) ?? 0,
      maxRooms: int.tryParse(_maxRoomsController.text) ?? 99,
      minBudget: double.tryParse(_minBudgetController.text) ?? 0,
      maxBudget: double.tryParse(_maxBudgetController.text) ?? 999999999,
      preferredArea: _areaController.text.trim(),
      createdAt: DateTime.now(),
    );
    await FirestoreService().addClient(client);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleService>().strings;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.t('clients'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Ном'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: t.t('phone')),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minRoomsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Ҳадди ақали ҳуҷра'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _maxRoomsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Ҳадди аксари ҳуҷра'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minBudgetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Буҷаи ҳадди ақал'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _maxBudgetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Буҷаи ҳадди аксар'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _areaController,
            decoration: const InputDecoration(labelText: 'Минтақаи дилхоҳ'),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(t.t('save')),
          ),
        ],
      ),
    );
  }
}
