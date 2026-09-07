import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/locale_service.dart';
import '../l10n/app_strings.dart';
import '../models/app_user.dart';
import 'team_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleService>().strings;
    final localeService = context.watch<LocaleService>();
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(t.t('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(t.t('language'), style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          SegmentedButton<AppLocale>(
            segments: const [
              ButtonSegment(value: AppLocale.tj, label: Text('Тоҷикӣ')),
              ButtonSegment(value: AppLocale.ru, label: Text('Русский')),
            ],
            selected: {localeService.locale},
            onSelectionChanged: (selection) => localeService.setLocale(selection.first),
          ),
          const Divider(height: 32),

          // Танҳо суперадмин/админ ин қисмро мебинанд
          if (user != null && user.canManageManagers) ...[
            ListTile(
              leading: const Icon(Icons.person_add_alt_outlined),
              title: Text(t.t('add_manager')),
              onTap: () => showDialog(
                context: context,
                builder: (_) => _AddManagerDialog(
                  companyId: user.companyId,
                  // Танҳо суперадмин метавонад нақши "admin" таъин кунад
                  allowAdminRole: user.canManageAdmins,
                ),
              ),
            ),
            const SizedBox(height: 4),
            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: Text(t.locale == AppLocale.ru ? 'Команда' : 'Кормандон'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeamScreen())),
            ),
            const Divider(height: 32),
          ],

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(t.t('logout'), style: const TextStyle(color: Colors.red)),
            onTap: () => auth.logout(),
          ),
        ],
      ),
    );
  }
}

class _AddManagerDialog extends StatefulWidget {
  final String companyId;
  final bool allowAdminRole;
  const _AddManagerDialog({required this.companyId, required this.allowAdminRole});

  @override
  State<_AddManagerDialog> createState() => _AddManagerDialogState();
}

class _AddManagerDialogState extends State<_AddManagerDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _role = UserRole.manager;
  bool _saving = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final auth = context.read<AuthService>();
    final result = await auth.createManagerAccount(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      tempPassword: _passwordController.text,
      companyId: widget.companyId,
      role: _role,
    );
    setState(() => _saving = false);
    if (result == null) {
      if (mounted) Navigator.pop(context);
    } else {
      setState(() => _error = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleService>().strings;
    return AlertDialog(
      title: Text(t.t('add_manager')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Ном'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: t.t('phone')),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(labelText: t.t('password')),
          ),
          if (widget.allowAdminRole) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<UserRole>(
              value: _role,
              items: const [
                DropdownMenuItem(value: UserRole.manager, child: Text('Менеҷер')),
                DropdownMenuItem(value: UserRole.admin, child: Text('Админ')),
              ],
              onChanged: (v) => setState(() => _role = v!),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Бекор')),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(t.t('save')),
        ),
      ],
    );
  }
}
