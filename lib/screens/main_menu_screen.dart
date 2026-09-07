import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/locale_service.dart';
import '../services/auth_service.dart';
import '../l10n/app_strings.dart';
import '../models/app_user.dart';
import 'add_property_screen.dart';
import 'my_properties_screen.dart';
import 'all_properties_screen.dart';
import 'clients_screen.dart';
import 'settings_screen.dart';

const _kPrimary = Color(0xFF0F6B5C);

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  String _roleLabel(UserRole role, AppLocale locale) {
    switch (role) {
      case UserRole.superAdmin:
        return 'Суперадмин';
      case UserRole.admin:
        return 'Админ';
      case UserRole.manager:
        return locale == AppLocale.ru ? 'Менеджер' : 'Менеҷер';
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeService = context.watch<LocaleService>();
    final t = localeService.strings;
    final user = context.watch<AuthService>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('menu_title')),
        actions: [
          _LanguageSwitch(localeService: localeService),
          const SizedBox(width: 12),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          children: [
            if (user != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kPrimary, Color(0xFF0A4A40)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white.withOpacity(0.18),
                      child: Text(
                        user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.fullName,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                          Text(_roleLabel(user.role, localeService.locale),
                              style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.25,
                children: [
                  _MenuTile(
                    icon: Icons.add_home_work_rounded,
                    color: const Color(0xFF0F6B5C),
                    label: t.t('add_property'),
                    onTap: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const AddPropertyScreen())),
                  ),
                  _MenuTile(
                    icon: Icons.home_rounded,
                    color: const Color(0xFF2F6FED),
                    label: t.t('my_properties'),
                    onTap: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const MyPropertiesScreen())),
                  ),
                  _MenuTile(
                    icon: Icons.apartment_rounded,
                    color: const Color(0xFFB6852C),
                    label: t.t('all_properties'),
                    onTap: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const AllPropertiesScreen())),
                  ),
                  _MenuTile(
                    icon: Icons.people_alt_rounded,
                    color: const Color(0xFF9B3FBF),
                    label: t.t('clients'),
                    onTap: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const ClientsScreen())),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _MenuTile(
              icon: Icons.settings_rounded,
              color: Colors.grey.shade700,
              label: t.t('settings'),
              fullWidth: true,
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  final bool fullWidth;

  const _MenuTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: fullWidth
            ? Row(
                children: [
                  _IconBadge(icon: icon, color: color, size: 38),
                  const SizedBox(width: 12),
                  Text(label,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _IconBadge(icon: icon, color: color, size: 44),
                  const SizedBox(height: 12),
                  Text(label,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const _IconBadge({required this.icon, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, color: color, size: size * 0.55),
    );
  }
}

class _LanguageSwitch extends StatelessWidget {
  final LocaleService localeService;
  const _LanguageSwitch({required this.localeService});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: DropdownButton<AppLocale>(
        value: localeService.locale,
        underline: const SizedBox(),
        style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600, fontSize: 13),
        items: const [
          DropdownMenuItem(value: AppLocale.tj, child: Text('ТҶ')),
          DropdownMenuItem(value: AppLocale.ru, child: Text('РУ')),
        ],
        onChanged: (value) {
          if (value != null) localeService.setLocale(value);
        },
      ),
    );
  }
}
