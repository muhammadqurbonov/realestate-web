import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/locale_service.dart';
import '../services/app_settings_service.dart';
import '../l10n/app_strings.dart';
import '../models/app_user.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import 'team_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String _roleLabel(AppStrings t, UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return t.t('superadmin_label');
      case UserRole.admin:
        return t.t('admin_label');
      case UserRole.manager:
        return t.t('manager_label');
    }
  }

  void _toast(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _sendReset(BuildContext context, AppUser user, AppStrings t) async {
    final auth = context.read<AuthService>();
    final error = await auth.sendPasswordResetEmail(user.email);
    if (!context.mounted) return;
    _toast(context, error ?? t.t('reset_password_sent'));
  }

  Future<void> _confirmLogout(BuildContext context, AppStrings t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.t('logout')),
        content: Text(t.t('logout_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.t('cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.t('confirm_yes')),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final auth = context.read<AuthService>();
      // Саҳифаҳоро мепӯшем, баъд мебароем (RootGate ба Login мегузарад).
      Navigator.of(context).popUntil((r) => r.isFirst);
      await auth.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeService = context.watch<LocaleService>();
    final t = localeService.strings;
    final settings = context.watch<AppSettingsService>();
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(t.t('settings'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          // ---------- Профил ----------
          if (user != null)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.28), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
                        const SizedBox(height: 2),
                        Text(_roleLabel(t, user.role), style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12.5)),
                        if (user.phone.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(user.phone, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
                        ],
                        if (user.email.isNotEmpty)
                          Text(user.email, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // ---------- Забон ----------
          _SectionTitle(t.t('language')),
          GlassCard(
            padding: const EdgeInsets.all(14),
            child: SegmentedButton<AppLocale>(
              style: const ButtonStyle(visualDensity: VisualDensity.comfortable),
              segments: const [
                ButtonSegment(value: AppLocale.tj, label: Text('Тоҷикӣ')),
                ButtonSegment(value: AppLocale.ru, label: Text('Русский')),
              ],
              selected: {localeService.locale},
              onSelectionChanged: (selection) => localeService.setLocale(selection.first),
            ),
          ),
          const SizedBox(height: 16),

          // ---------- Намуди барнома ----------
          _SectionTitle(t.t('appearance')),
          GlassCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.t('bg_style'), style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                SegmentedButton<BackgroundStyle>(
                  segments: [
                    ButtonSegment(value: BackgroundStyle.ocean, icon: const Icon(Icons.water_drop_outlined), label: Text(t.t('bg_ocean'))),
                    ButtonSegment(value: BackgroundStyle.glass, icon: const Icon(Icons.blur_on_rounded), label: Text(t.t('bg_glass'))),
                  ],
                  selected: {settings.backgroundStyle},
                  onSelectionChanged: (s) => settings.setBackgroundStyle(s.first),
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.t('animations'), style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(t.t('animations_desc'), style: const TextStyle(fontSize: 12)),
                  value: settings.animationsEnabled,
                  onChanged: settings.setAnimationsEnabled,
                ),
                const SizedBox(height: 6),
                Text(t.t('text_size'), style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                SegmentedButton<double>(
                  segments: [
                    ButtonSegment(value: 0.9, label: Text(t.t('text_small'))),
                    ButtonSegment(value: 1.0, label: Text(t.t('text_normal'))),
                    ButtonSegment(value: 1.15, label: Text(t.t('text_large'))),
                  ],
                  selected: {settings.textScale},
                  onSelectionChanged: (s) => settings.setTextScale(s.first),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: settings.resetAppearance,
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: Text(t.t('reset_appearance')),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ---------- Ҳисоб ----------
          if (user != null) ...[
            _SectionTitle(t.t('account')),
            GlassCard(
              child: ListTile(
                leading: const Icon(Icons.lock_reset_rounded, color: AppColors.primary),
                title: Text(t.t('change_password'), style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(t.t('change_password_desc'), style: const TextStyle(fontSize: 12)),
                onTap: () => _sendReset(context, user, t),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ---------- Идоракунӣ ----------
          if (user != null && user.canManageManagers) ...[
            _SectionTitle(t.t('management')),
            GlassCard(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.vpn_key_outlined, color: AppColors.primary),
                    title: Text(t.t('company_code'), style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: SelectableText(user.companyId, style: const TextStyle(fontSize: 12.5)),
                    trailing: IconButton(
                      tooltip: t.t('copy'),
                      icon: const Icon(Icons.copy_rounded),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: user.companyId));
                        if (context.mounted) _toast(context, t.t('copied'));
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.person_add_alt_outlined, color: AppColors.primary),
                    title: Text(t.t('add_manager'), style: const TextStyle(fontWeight: FontWeight.w700)),
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => _AddManagerDialog(
                        companyId: user.companyId,
                        allowAdminRole: user.canManageAdmins,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.groups_outlined, color: AppColors.primary),
                    title: Text(t.t('team'), style: const TextStyle(fontWeight: FontWeight.w700)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeamScreen())),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ---------- Дар бораи барнома ----------
          GlassCard(
            child: ListTile(
              leading: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
              title: Text('Green Home', style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(t.t('about_app_desc'), style: const TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(height: 16),

          // ---------- Баромадан ----------
          GlassCard(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(t.t('logout'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
              onTap: () => _confirmLogout(context, t),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.primaryDark),
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
  final _emailController = TextEditingController();
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
      email: _emailController.text.trim(),
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
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Ном')),
            const SizedBox(height: 8),
            TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: t.t('phone'))),
            const SizedBox(height: 8),
            TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: t.t('email'))),
            const SizedBox(height: 8),
            TextField(controller: _passwordController, decoration: InputDecoration(labelText: t.t('password'))),
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
            if (_error != null) ...[const SizedBox(height: 8), Text(_error!, style: const TextStyle(color: Colors.red))],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.t('cancel'))),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Text(t.t('save')),
        ),
      ],
    );
  }
}
