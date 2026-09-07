import 'package:url_launcher/url_launcher.dart';
import '../models/property.dart';
import '../l10n/app_strings.dart';

/// Сохтани матни хабар барои WhatsApp аз рӯи маълумоти хона (маълумоти
/// оммавӣ танҳо — "маслиҳат бо соҳибхона" ҳаргиз ба ин ҷо намеояд).
String buildWhatsAppMessage(Property p, AppStrings t) {
  final buffer = StringBuffer();

  final categoryLabel = p.category == ListingCategory.houseLand
      ? (p.houseLandType == HouseLandType.dacha ? t.t('houseland_dacha') : t.t('houseland_havli'))
      : t.t('category_apartment');

  buffer.writeln('🏠 *$categoryLabel*');
  buffer.writeln();
  buffer.writeln('💰 ${p.price.toStringAsFixed(0)} ${t.t('somoni')}');
  buffer.writeln('📍 ${p.address}');

  if (p.category == ListingCategory.apartment) {
    buffer.writeln('🚪 ${p.rooms} ${t.t('property_rooms')}');
    if (p.totalFloors > 0) buffer.writeln('🏢 ${p.floor}/${p.totalFloors}');
  } else {
    if (p.houseFloorsCount > 0) buffer.writeln('🏢 ${p.houseFloorsCount}-ошёна');
    if (p.landSotka > 0) buffer.writeln('🌳 ${p.landSotka} сотих');
  }
  if (p.area > 0) buffer.writeln('📐 ${p.area.toStringAsFixed(0)} м²');

  buffer.writeln(p.buildingForm == BuildingForm.newConstruction ? t.t('building_new') : t.t('building_old'));
  buffer.writeln(switch (p.renovationLevel) {
    RenovationLevel.fresh => t.t('renovation_fresh'),
    RenovationLevel.average => t.t('renovation_average'),
    RenovationLevel.empty => t.t('renovation_empty'),
  });

  if (p.description.isNotEmpty) {
    buffer.writeln();
    buffer.writeln(p.description);
  }

  if (p.photoUrls.isNotEmpty) {
    buffer.writeln();
    buffer.writeln('📷 ${t.t('step_photos_title')}:');
    for (final url in p.photoUrls.take(10)) {
      buffer.writeln(url);
    }
  }

  buffer.writeln();
  buffer.writeln('☎️ ${p.addedByName}: ${p.addedByPhone}');

  return buffer.toString();
}

Future<bool> shareToWhatsApp(Property p, AppStrings t) async {
  final message = buildWhatsAppMessage(p, t);
  final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
