import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/locale_service.dart';
import 'services/app_settings_service.dart';
import 'services/notification_center.dart';
import 'services/app_keys.dart';
import 'l10n/app_strings.dart';
import 'models/app_notification.dart';
import 'screens/notifications_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_menu_screen.dart';
import 'theme/app_colors.dart';
import 'widgets/app_background.dart';

const _kPrimary = AppColors.primary;
const _kPrimaryDark = AppColors.primaryDark;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AppRoot());
}

/// Гузариши нарми саҳифаҳо (fade) — бо Scaffold-и шаффоф зебо кор мекунад.
class _FadePageTransitionsBuilder extends PageTransitionsBuilder {
  const _FadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final LocaleService _localeService = LocaleService();
  final AppSettingsService _settingsService = AppSettingsService();

  @override
  void initState() {
    super.initState();
    _localeService.load();
    _settingsService.load();
  }

  /// Вақте огоҳии нав меояд (барнома кушода аст) — SnackBar нишон медиҳем.
  void _showIncoming(AppNotification n, int more) {
    final messenger = rootMessengerKey.currentState;
    if (messenger == null) return;
    final isRu = _localeService.locale == AppLocale.ru;
    var text = n.message(isRu);
    if (more > 0) text += isRu ? '\n+ ещё $more' : '\n+ боз $more огоҳинома';
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text, maxLines: 4, overflow: TextOverflow.ellipsis),
        duration: const Duration(seconds: 7),
        action: SnackBarAction(
          label: isRu ? 'Открыть' : 'Кушодан',
          textColor: Colors.white,
          onPressed: () => rootNavigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
        ),
      ));
  }

  ThemeData _buildTheme() {
    final base = ColorScheme.fromSeed(seedColor: _kPrimary, primary: _kPrimary, surface: Colors.white);
    final textTheme = GoogleFonts.manropeTextTheme();
    return ThemeData(
      useMaterial3: true,
      // Scaffold шаффоф — фони умумии AppBackground аз зери ҳама саҳифаҳо намоён аст.
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: base,
      textTheme: textTheme,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: _FadePageTransitionsBuilder(),
        TargetPlatform.iOS: _FadePageTransitionsBuilder(),
        TargetPlatform.windows: _FadePageTransitionsBuilder(),
        TargetPlatform.macOS: _FadePageTransitionsBuilder(),
        TargetPlatform.linux: _FadePageTransitionsBuilder(),
      }),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _kPrimaryDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: _kPrimaryDark),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glassFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.glassBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.glassBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      cardTheme: CardThemeData(
        color: AppColors.glassFill,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: AppColors.glassBorder)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xF2FFFFFF),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xF5FFFFFF),
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: Color(0xF5FFFFFF),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _kPrimaryDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerColor: Colors.white.withOpacity(0.7),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider.value(value: _localeService),
        ChangeNotifierProvider.value(value: _settingsService),
        ChangeNotifierProxyProvider<AuthService, NotificationCenter>(
          create: (_) => NotificationCenter(),
          update: (_, auth, center) {
            center!.onIncoming = _showIncoming;
            center.attach(auth.currentUser);
            return center;
          },
        ),
      ],
      child: Consumer<AppSettingsService>(
        builder: (context, settings, _) => MaterialApp(
          title: 'Green Home',
          debugShowCheckedModeBanner: false,
          navigatorKey: rootNavigatorKey,
          scaffoldMessengerKey: rootMessengerKey,
          theme: _buildTheme(),
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(textScaler: TextScaler.linear(settings.textScale)),
              child: AppBackground(child: child ?? const SizedBox()),
            );
          },
          home: const _RootGate(),
        ),
      ),
    );
  }
}

class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (auth.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (auth.currentUser == null) {
      return const LoginScreen();
    }
    return const MainMenuScreen();
  }
}
