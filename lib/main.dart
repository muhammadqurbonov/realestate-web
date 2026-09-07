import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/locale_service.dart';
import 'screens/login_screen.dart';
import 'screens/main_menu_screen.dart';

// Рангҳои асосии барнома — сабзи амиқ (эмералд), рӯҳияи "амволи бонуфуз".
const _kPrimary = Color(0xFF0F6B5C);
const _kPrimaryDark = Color(0xFF0A4A40);
const _kBackground = Color(0xFFF6F8F7);
const _kSurface = Color(0xFFFFFFFF);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AppRoot());
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final LocaleService _localeService = LocaleService();

  @override
  void initState() {
    super.initState();
    _localeService.load();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider.value(value: _localeService),
      ],
      child: MaterialApp(
        title: 'Real Estate App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: _kBackground,
          colorScheme: ColorScheme.fromSeed(
            seedColor: _kPrimary,
            primary: _kPrimary,
            surface: _kSurface,
          ),
          textTheme: GoogleFonts.manropeTextTheme(),
          appBarTheme: AppBarTheme(
            backgroundColor: _kBackground,
            foregroundColor: _kPrimaryDark,
            elevation: 0,
            centerTitle: false,
            titleTextStyle: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _kPrimaryDark,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: _kSurface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _kPrimary, width: 1.5),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          cardTheme: CardThemeData(
            color: _kSurface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          dividerColor: Colors.grey.shade200,
        ),
        home: const _RootGate(),
      ),
    );
  }
}

/// Дар асоси ҳолати воридшавӣ, ё LoginScreen ё MainMenuScreen нишон
/// дода мешавад.
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
