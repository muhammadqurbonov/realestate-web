import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/locale_service.dart';
import '../services/app_settings_service.dart';
import '../services/auth_service.dart';
import '../services/notification_center.dart';
import '../widgets/app_logo.dart';
import '../l10n/app_strings.dart';
import '../models/app_user.dart';
import 'add_property_screen.dart';
import 'my_properties_screen.dart';
import 'all_properties_screen.dart';
import 'clients_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';
import 'manager_properties_screen.dart';

const _kPrimary = Color(0xFF1E6FD9);

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
        titleSpacing: 16,
        title: Row(
          children: [
            const AppLogo(size: 38, border: false),
            const SizedBox(width: 10),
            Flexible(child: Text(t.t('menu_title'), overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          if (user != null) const _NotificationBell(),
          const SizedBox(width: 4),
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
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kPrimary, Color(0xFF0B3D91)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [BoxShadow(color: _kPrimary.withOpacity(0.28), blurRadius: 20, offset: const Offset(0, 8))],
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
                childAspectRatio: 1.1,
                children: [
                  _MenuTile(
                    icon: Icons.add_home_work_rounded,
                    color: const Color(0xFF1E6FD9),
                    label: t.t('add_property'),
                    order: 0,
                    onTap: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const AddPropertyScreen())),
                  ),
                  _MenuTile(
                    icon: Icons.home_rounded,
                    color: const Color(0xFF2F6FED),
                    label: t.t('my_properties'),
                    order: 1,
                    onTap: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const MyPropertiesScreen())),
                  ),
                  _MenuTile(
                    icon: Icons.apartment_rounded,
                    color: const Color(0xFFB6852C),
                    label: t.t('all_properties'),
                    order: 2,
                    onTap: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const AllPropertiesScreen())),
                  ),
                  _MenuTile(
                    icon: Icons.people_alt_rounded,
                    color: const Color(0xFF9B3FBF),
                    label: t.t('clients'),
                    order: 3,
                    onTap: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const ClientsScreen())),
                  ),
                  _MenuTile(
                    icon: Icons.badge_rounded,
                    color: const Color(0xFF14A0C8),
                    label: t.t('manager_properties_title'),
                    order: 4,
                    onTap: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const ManagerPropertiesScreen())),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _MenuTile(
              icon: Icons.settings_rounded,
              color: Colors.grey.shade700,
              label: t.t('settings'),
              order: 5,
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

/// Иконаи зангӯла бо тегчаи шумораи огоҳиномаҳои надида.
class _NotificationBell extends StatelessWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationCenter>().unreadCount;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
        ),
        if (unread > 0)
          Positioned(
            right: 6,
            top: 6,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  unread > 9 ? '9+' : '$unread',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MenuTile extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  final bool fullWidth;
  final int order;

  const _MenuTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.fullWidth = false,
    this.order = 0,
  });

  @override
  State<_MenuTile> createState() => _MenuTileState();
}

class _MenuTileState extends State<_MenuTile> with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 1800 + widget.order * 220),
  );
  bool _pressed = false;

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animate = context.watch<AppSettingsService>().animationsEnabled;
    if (animate) {
      if (!_float.isAnimating) _float.repeat(reverse: true);
    } else {
      if (_float.isAnimating) _float.stop();
    }

    final tile = AnimatedScale(
      scale: _pressed && animate ? 0.95 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: _buildTile(animate),
    );
    if (!animate) return tile;
    // Пайдошавӣ: ҳар плитка бо таъхир аз поён баромада меояд.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + widget.order * 120),
      curve: Curves.easeOutBack,
      builder: (context, v, child) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, 40 * (1 - v)), child: child),
      ),
      child: tile,
    );
  }

  Widget _buildTile(bool animate) {
    // Иконка оҳиста боло-поён мепарад.
    Widget badge(double size) {
      final b = _IconBadge(icon: widget.icon, color: widget.color, size: size);
      if (!animate) return b;
      return AnimatedBuilder(
        animation: _float,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, -4 * Curves.easeInOut.transform(_float.value)),
          child: child,
        ),
        child: b,
      );
    }

    return InkWell(
      onTap: widget.onTap,
      onHighlightChanged: (v) => setState(() => _pressed = v),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.72),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xCCFFFFFF)),
          boxShadow: [
            BoxShadow(color: _kPrimary.withOpacity(0.10), blurRadius: 18, offset: const Offset(0, 6)),
          ],
        ),
        child: widget.fullWidth
            ? Row(
                children: [
                  badge(38),
                  const SizedBox(width: 12),
                  Text(widget.label,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0B3D91))),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  badge(44),
                  const SizedBox(height: 12),
                  Text(widget.label,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0B3D91))),
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
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(size * 0.32)),
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
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xCCFFFFFF)),
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
