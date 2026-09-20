import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/property.dart';
import '../services/locale_service.dart';
import '../services/whatsapp_share.dart';
import '../l10n/app_strings.dart';
import '../screens/property_detail_screen.dart';

const _kPrimary = Color(0xFF0F6B5C);
const _kPrimaryDark = Color(0xFF0A4A40);

/// Корти хулосавии хона — дар "Хонаҳои ман" ва "Ҳамаи хонаҳо" истифода
/// мешавад. Зер кардан ба саҳифаи пурраи детали мебарад.
class PropertyCard extends StatelessWidget {
  final Property property;
  final bool canSeePrivate;

  const PropertyCard({super.key, required this.property, this.canSeePrivate = false});

  String _typeLabel(AppStrings t) {
    if (property.category == ListingCategory.houseLand) {
      return property.houseLandType == HouseLandType.dacha
          ? t.t('houseland_dacha')
          : t.t('houseland_havli');
    }
    return t.t('category_apartment');
  }

  String _subtitle(AppStrings t) {
    if (property.category == ListingCategory.apartment) {
      return '${property.rooms} ${t.t('property_rooms')} · ${property.area.toStringAsFixed(0)} м²';
    }
    return '${property.houseFloorsCount}-ошёна · ${property.landSotka} сотих';
  }

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d.$m.${dt.year}';
  }

  Future<void> _share(BuildContext context, AppStrings t) async {
    final ok = await shareToWhatsApp(property, t);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WhatsApp кушода нашуд.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleService>().strings;
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PropertyDetailScreen(property: property, canSeePrivate: canSeePrivate),
        ),
      ),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.045), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: ColorFiltered(
                    colorFilter: property.isSold
                        ? const ColorFilter.mode(Colors.black38, BlendMode.darken)
                        : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                    child: property.photoUrls.isNotEmpty
                        ? Image.network(property.photoUrls.first, width: double.infinity, height: 150, fit: BoxFit.cover)
                        : Container(
                            width: double.infinity,
                            height: 150,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFE7F0ED), Color(0xFFF3F7F5)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Icon(Icons.home_rounded, size: 40, color: Color(0xFFB4C2BD)),
                          ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      gradient: LinearGradient(
                        colors: [Colors.black.withOpacity(0.28), Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(20)),
                    child: Text(_typeLabel(t),
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ),
                if (property.isSold)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.red.shade600, borderRadius: BorderRadius.circular(20)),
                      child: Text(t.t('sold_badge'),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(property.address,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(_subtitle(t), style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                  const SizedBox(height: 2),
                  Text(_formatDate(property.createdAt), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text('${property.price.toStringAsFixed(0)} ${t.t('somoni')}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: _kPrimaryDark)),
                      ),
                      InkWell(
                        onTap: () => _share(context, t),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.chat, color: Color(0xFF25D366), size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
