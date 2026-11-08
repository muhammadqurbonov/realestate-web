import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_strings.dart';
import '../models/property.dart';
import 'app_install.dart';
import 'share_support.dart';
import 'whatsapp_share.dart';

/// Хонаро ба WhatsApp (ва ҳар барномаи дигар) бо АКСҲО ҳамчун файл мефиристад:
///  1) аксҳо фуруд меоянд (бо нишондиҳандаи пешрафт);
///  2) менюи мубодилаи телефон кушода мешавад — WhatsApp-ро интихоб мекунед;
///  3) аксҳо дар чат кушода (албом) мераванд ва матн ҳамчун тавзеҳ.
/// Агар ин имкон набошад (масалан, браузери компютерӣ), линкҳои аксҳо дар матн меравад.
Future<void> sharePropertyToWhatsApp(BuildContext context, Property p, AppStrings t) async {
  final messenger = ScaffoldMessenger.of(context);
  final isRu = t.locale == AppLocale.ru;

  Future<void> fallbackLinks() async {
    final ok = await shareToWhatsApp(p, t);
    if (!ok) messenger.showSnackBar(SnackBar(content: Text(t.t('whatsapp_failed'))));
  }

  if (p.photoUrls.isEmpty || !canShareFilesNow()) {
    await fallbackLinks();
    return;
  }

  // 1) Аксҳоро мефурорем
  final total = p.photoUrls.length > kShareMaxPhotos ? kShareMaxPhotos : p.photoUrls.length;
  final progress = ValueNotifier<int>(0);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: ValueListenableBuilder<int>(
          valueListenable: progress,
          builder: (_, done, __) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),
              LinearProgressIndicator(value: total == 0 ? null : done / total),
              const SizedBox(height: 14),
              Text(
                isRu ? 'Подготовка фото: $done / $total' : 'Аксҳо омода мешаванд: $done / $total',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  List<XFile> files;
  try {
    files = await fetchPhotosForShare(p, onProgress: (d) => progress.value = d);
  } catch (_) {
    files = [];
  }
  if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  progress.dispose();

  if (files.isEmpty) {
    await fallbackLinks();
    return;
  }

  final text = buildWhatsAppMessage(p, t, includePhotoLinks: false);

  // 2) Дар веб браузер барои мубодила зеркунии НАВ талаб мекунад
  if (kIsWeb) {
    if (!context.mounted) return;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.photo_library_rounded, size: 34, color: Color(0xFF25D366)),
        title: Text(isRu ? 'Фото готовы' : 'Аксҳо тайёранд', textAlign: TextAlign.center),
        content: Text(
          isRu
              ? '${files.length} фото. Нажмите «Отправить» и выберите WhatsApp.'
              : '${files.length} акс. «Фиристодан»-ро зер карда, WhatsApp-ро интихоб кунед.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.t('cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isRu ? 'Отправить' : 'Фиристодан'),
          ),
        ],
      ),
    );
    if (go != true) return;
  }

  // iPhone: WhatsApp гоҳо матнро бо аксҳо қабул намекунад — матнро нусха мекунем.
  final copyText = kIsWeb && AppInstall.isIOS;
  if (copyText) await Clipboard.setData(ClipboardData(text: text));

  try {
    await Share.shareXFiles(files, text: text);
    if (copyText) {
      messenger.showSnackBar(SnackBar(
        content: Text(isRu
            ? 'Если текст не появился, он скопирован — вставьте его в чат.'
            : 'Агар матн наомад, он нусха шудааст — дар чат часпонед.'),
        duration: const Duration(seconds: 6),
      ));
    }
  } catch (_) {
    await fallbackLinks();
  }
}
