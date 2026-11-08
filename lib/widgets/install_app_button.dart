import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_install.dart';
import '../services/locale_service.dart';
import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';

/// Тугмаи «Барномаро насб кардан».
///  - Android/Chrome/Edge: насби мустақим бо як зеркунӣ.
///  - iPhone/iPad: дастури қадам ба қадам барои «Илова ба экрани асосӣ».
///  - Агар барнома аллакай насб шуда бошад ё на дар веб бошад, пинҳон аст.
class InstallAppButton extends StatefulWidget {
  /// true — шакли корти васеъ (барои Танзимот), false — тугмаи ихчам.
  final bool card;
  const InstallAppButton({super.key, this.card = false});

  @override
  State<InstallAppButton> createState() => _InstallAppButtonState();
}

class _InstallAppButtonState extends State<InstallAppButton> {
  @override
  void initState() {
    super.initState();
    AppInstall.listen(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _onTap(AppStrings t) async {
    if (AppInstall.canPrompt) {
      final ok = await AppInstall.prompt();
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.t('install_done'))));
      }
      setState(() {});
      return;
    }
    // Насби мустақим дастрас нест (iPhone, Firefox ва ғ.) — дастур нишон медиҳем.
    final ios = AppInstall.isIOS;
    final steps = ios
        ? [t.t('install_ios_1'), t.t('install_ios_2'), t.t('install_ios_3'), t.t('install_ios_4')]
        : [t.t('install_other_1'), t.t('install_other_2')];
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(ios ? Icons.ios_share_rounded : Icons.install_mobile_rounded, size: 34, color: AppColors.primary),
        title: Text(ios ? t.t('install_ios_title') : t.t('install_other_title'), textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 11,
                        backgroundColor: AppColors.primary,
                        child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(steps[i], style: const TextStyle(fontSize: 14))),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!AppInstall.isWeb || AppInstall.isStandalone) return const SizedBox.shrink();
    final t = context.watch<LocaleService>().strings;

    if (widget.card) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.glassFill,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: ListTile(
          leading: const Icon(Icons.install_mobile_rounded, color: AppColors.primary),
          title: Text(t.t('install_app'), style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(t.t('install_app_desc'), style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _onTap(t),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _onTap(t),
        icon: const Icon(Icons.install_mobile_rounded),
        label: Text(t.t('install_app')),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          backgroundColor: AppColors.glassFill,
          side: const BorderSide(color: AppColors.glassBorder, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
        ),
      ),
    );
  }
}
