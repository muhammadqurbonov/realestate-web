import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/locale_service.dart';
import 'register_screen.dart';

const _kPrimary = Color(0xFF0F6B5C);
const _kPrimaryDark = Color(0xFF0A4A40);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;
  bool _loading = false;
  bool _obscure = true;

  Future<void> _submit() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = context.read<LocaleService>().strings.t('required_field'));
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthService>();
    final result = await auth.login(_emailController.text.trim(), _passwordController.text);
    setState(() {
      _loading = false;
      _error = result;
    });
  }

  Future<void> _forgotPassword() async {
    final t = context.read<LocaleService>().strings;
    final emailController = TextEditingController(text: _emailController.text.trim());
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.t('reset_password_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.t('reset_password_desc'), style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: t.t('email'))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Бекор')),
          ElevatedButton(onPressed: () => Navigator.pop(context, emailController.text.trim()), child: Text(t.t('send'))),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      final auth = context.read<AuthService>();
      final error = await auth.sendPasswordResetEmail(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? t.t('reset_password_sent'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleService>().strings;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_kPrimary, _kPrimaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                    child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text(t.t('menu_title'), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(t.t('login'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(labelText: t.t('email'), prefixIcon: const Icon(Icons.email_outlined)),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: t.t('password'),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(onPressed: _forgotPassword, child: Text(t.t('forgot_password'), style: const TextStyle(color: _kPrimary))),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 4),
                        Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                      ],
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(t.t('login_button')),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                        child: Text(t.t('no_account_register')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
