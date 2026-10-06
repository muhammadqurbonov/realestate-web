import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../services/auth_service.dart';

/// Баъд аз фиристодани линк — равшан мегӯем, ки ба кадом email фиристода шуд
/// ва ки агар паём наояд, куҷоро санҷидан лозим.
Future<void> showResetSentDialog(BuildContext context, AppStrings t, String email) {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.mark_email_read_outlined, size: 36),
      title: Text(t.t('reset_sent_title')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SelectableText(email, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text(t.t('reset_sent_hint'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
        ],
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
    ),
  );
}

/// Иваз кардани рамз бо тасдиқи рамзи ҷорӣ (email лозим нест).
class ChangePasswordDialog extends StatefulWidget {
  final AppStrings t;
  const ChangePasswordDialog({super.key, required this.t});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _repeat = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _repeat.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = widget.t;
    if (_current.text.isEmpty || _new.text.isEmpty) {
      setState(() => _error = t.t('required_field'));
      return;
    }
    if (_new.text.length < 6) {
      setState(() => _error = t.t('password_too_short'));
      return;
    }
    if (_new.text != _repeat.text) {
      setState(() => _error = t.t('passwords_dont_match'));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await context.read<AuthService>().changePassword(_current.text, _new.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return AlertDialog(
      title: Text(t.t('change_password')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _current, obscureText: true, decoration: InputDecoration(labelText: t.t('current_password'))),
            const SizedBox(height: 10),
            TextField(controller: _new, obscureText: true, decoration: InputDecoration(labelText: t.t('new_password'))),
            const SizedBox(height: 10),
            TextField(controller: _repeat, obscureText: true, decoration: InputDecoration(labelText: t.t('repeat_password'))),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: Text(t.t('cancel'))),
        ElevatedButton(
          onPressed: _busy ? null : _submit,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
          child: _busy
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(t.t('save')),
        ),
      ],
    );
  }
}
