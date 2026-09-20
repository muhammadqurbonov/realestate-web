import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/property.dart';
import '../services/locale_service.dart';
import '../services/firestore_service.dart';
import '../l10n/app_strings.dart';
import '../services/whatsapp_share.dart';
import 'edit_property_screen.dart';
import 'photo_gallery_screen.dart';

const _kPrimary = Color(0xFF0F6B5C);

/// Саҳифаи пурраи деталии хона.
class PropertyDetailScreen extends StatefulWidget {
  final Property property;
  final bool canSeePrivate;

  const PropertyDetailScreen({
    super.key,
    required this.property,
    required this.canSeePrivate,
  });

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  late bool _isSold;
  bool _togglingSold = false;
  final _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _isSold = widget.property.isSold;
  }

  String _categoryLabel(AppStrings t) {
    final property = widget.property;
    if (property.category == ListingCategory.houseLand) {
      return property.houseLandType == HouseLandType.dacha
          ? t.t('houseland_dacha')
          : t.t('houseland_havli');
    }
    return t.t('category_apartment');
  }

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d.$m.${dt.year}';
  }

  Future<void> _toggleSold() async {
    setState(() => _togglingSold = true);
    try {
      await _firestoreService.setSold(widget.property.id, !_isSold);
      if (mounted) setState(() => _isSold = !_isSold);
    } finally {
      if (mounted) setState(() => _togglingSold = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleService>().strings;
    final property = widget.property;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 260,
            backgroundColor: _kPrimary,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              if (widget.canSeePrivate)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  onPressed: () async {
                    final privateInfo = await FirestoreService().getPrivateInfo(property.id);
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditPropertyScreen(
                            property: property,
                            privateInfo: privateInfo ??
                                PropertyPrivateInfo(
                                  ownerPhone: '',
                                  commissionType: CommissionType.percent,
                                  commissionValue: 0,
                                ),
                          ),
                        ),
                      );
                    }
                  },
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: property.photoUrls.isNotEmpty
                  ? PageView.builder(
                      itemCount: property.photoUrls.length,
                      itemBuilder: (context, index) => GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PhotoGalleryScreen(photoUrls: property.photoUrls, initialIndex: index),
                          ),
                        ),
                        child: Image.network(property.photoUrls[index], fit: BoxFit.cover),
                      ),
                    )
                  : Container(
                      color: _kPrimary.withOpacity(0.15),
                      child: Icon(Icons.home_rounded, size: 64, color: _kPrimary.withOpacity(0.4)),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _kPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _categoryLabel(t),
                          style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ),
                      if (_isSold) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            t.t('sold_badge'),
                            style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w800, fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${property.price.toStringAsFixed(0)} ${t.t('somoni')}',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _kPrimary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(child: Text(property.address, style: const TextStyle(color: Colors.grey))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(_formatDate(property.createdAt),
                          style: const TextStyle(color: Colors.grey, fontSize: 12.5)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _DetailGrid(property: property, t: t),
                  if (property.description.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(property.description, style: const TextStyle(fontSize: 14.5, height: 1.5)),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final ok = await shareToWhatsApp(property, t);
                        if (!ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('WhatsApp кушода нашуд.')),
                          );
                        }
                      },
                      icon: const Icon(Icons.chat, size: 20),
                      label: Text(t.locale == AppLocale.ru ? 'Отправить в WhatsApp' : 'Ба WhatsApp равон кардан'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: Color(0xFFEFF3F1),
                        child: Icon(Icons.person_outline, color: _kPrimary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.t('added_by'), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            Text(property.addedByName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Text(property.addedByPhone, style: const TextStyle(color: _kPrimary)),
                    ],
                  ),
                  if (widget.canSeePrivate) ...[
                    const SizedBox(height: 16),
                    _PrivateSection(propertyId: property.id, t: t),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _togglingSold ? null : _toggleSold,
                        icon: _togglingSold
                            ? const SizedBox(
                                height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : Icon(_isSold ? Icons.undo_rounded : Icons.check_circle_outline_rounded),
                        label: Text(_isSold ? t.t('unmark_sold') : t.t('mark_sold')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _isSold ? _kPrimary : Colors.red.shade700,
                          side: BorderSide(color: _isSold ? _kPrimary : Colors.red.shade200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailGrid extends StatelessWidget {
  final Property property;
  final AppStrings t;
  const _DetailGrid({required this.property, required this.t});

  @override
  Widget build(BuildContext context) {
    final items = <_GridItem>[];

    if (property.category == ListingCategory.apartment) {
      items.add(_GridItem(Icons.meeting_room_outlined, t.t('step_rooms_title').split('?').first, '${property.rooms}'));
      items.add(_GridItem(Icons.layers_outlined, t.t('floor_label'), '${property.floor}/${property.totalFloors}'));
    } else {
      items.add(_GridItem(Icons.layers_outlined, t.t('step_house_floors_title'), '${property.houseFloorsCount}'));
      items.add(_GridItem(Icons.landscape_outlined, t.t('step_land_sotka_title'), '${property.landSotka} сотих'));
    }
    items.add(_GridItem(Icons.square_foot_outlined, 'м²', '${property.area.toStringAsFixed(0)} м²'));
    items.add(_GridItem(
      Icons.foundation_outlined,
      t.t('step_building_form_title'),
      property.buildingForm == BuildingForm.newConstruction ? t.t('building_new') : t.t('building_old'),
    ));
    items.add(_GridItem(
      Icons.brush_outlined,
      t.t('step_renovation_title'),
      switch (property.renovationLevel) {
        RenovationLevel.fresh => t.t('renovation_fresh'),
        RenovationLevel.average => t.t('renovation_average'),
        RenovationLevel.empty => t.t('renovation_empty'),
      },
    ));
    items.add(_GridItem(
      Icons.construction_outlined,
      t.t('step_construction_status_title'),
      property.constructionStatus == ConstructionStatus.built
          ? t.t('construction_built')
          : t.t('construction_in_progress'),
    ));
    items.add(_GridItem(
      Icons.bathtub_outlined,
      t.t('step_bathroom_title'),
      property.bathroomType == BathroomType.separate ? t.t('bathroom_separate') : t.t('bathroom_combined'),
    ));
    items.add(_GridItem(
      Icons.description_outlined,
      t.t('step_tech_passport_title'),
      property.hasTechPassport ? t.t('yes') : t.t('no'),
    ));

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.6,
      children: items
          .map((item) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFFF6F8F7), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(item.icon, size: 18, color: _kPrimary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(item.label,
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          Text(item.value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _GridItem {
  final IconData icon;
  final String label;
  final String value;
  _GridItem(this.icon, this.label, this.value);
}

class _PrivateSection extends StatelessWidget {
  final String propertyId;
  final AppStrings t;
  const _PrivateSection({required this.propertyId, required this.t});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PropertyPrivateInfo?>(
      future: FirestoreService().getPrivateInfo(propertyId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: CircularProgressIndicator());
        }
        final info = snapshot.data;
        if (info == null) return const SizedBox();
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.amber.withOpacity(0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lock_outline, size: 16, color: Colors.orange),
                  const SizedBox(width: 6),
                  Text(t.t('step_owner_title'),
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.orange, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 10),
              _kv(t.t('owner_phone'), info.ownerPhone),
              const SizedBox(height: 6),
              _kv(
                t.t('commission_type'),
                info.commissionType == CommissionType.percent
                    ? '${t.t('commission_percent')} — ${info.commissionValue}%'
                    : '${t.t('commission_margin')} — ${info.commissionValue.toStringAsFixed(0)} ${t.t('somoni')}',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _kv(String k, String v) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 110, child: Text(k, style: const TextStyle(fontSize: 12.5, color: Colors.grey))),
        Expanded(child: Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
      ],
    );
  }
}
