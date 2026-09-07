import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/locale_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../l10n/app_strings.dart';
import '../models/property.dart';

const _kPrimary = Color(0xFF0F6B5C);

/// Таҳрири хонаи мавҷуда — ҳама майдонҳо дар як саҳифа (на wizard),
/// то тағйир додани як-ду чиз зуд бошад. Инчунин тугмаи ҳазф дорад.
class EditPropertyScreen extends StatefulWidget {
  final Property property;
  final PropertyPrivateInfo privateInfo;

  const EditPropertyScreen({super.key, required this.property, required this.privateInfo});

  @override
  State<EditPropertyScreen> createState() => _EditPropertyScreenState();
}

class _EditPropertyScreenState extends State<EditPropertyScreen> {
  late ListingCategory _category;
  HouseLandType? _houseLandType;
  late TextEditingController _roomsController;
  late TextEditingController _houseFloorsController;
  late TextEditingController _landSotkaController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _addressController;
  late TextEditingController _areaController;
  late TextEditingController _floorController;
  late TextEditingController _totalFloorsController;
  late BuildingForm _buildingForm;
  late RenovationLevel _renovationLevel;
  late ConstructionStatus _constructionStatus;
  late BathroomType _bathroomType;
  late bool _hasTechPassport;
  late List<String> _existingPhotoUrls;
  final List<XFile> _newPhotos = [];
  late TextEditingController _ownerPhoneController;
  late CommissionType _commissionType;
  late TextEditingController _commissionValueController;

  bool _saving = false;
  bool _deleting = false;
  String? _error;

  final _picker = ImagePicker();
  final _storageService = StorageService();
  final _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    final p = widget.property;
    _category = p.category;
    _houseLandType = p.houseLandType;
    _roomsController = TextEditingController(text: p.rooms == 0 ? '' : '${p.rooms}');
    _houseFloorsController = TextEditingController(text: p.houseFloorsCount == 0 ? '' : '${p.houseFloorsCount}');
    _landSotkaController = TextEditingController(text: p.landSotka == 0 ? '' : '${p.landSotka}');
    _priceController = TextEditingController(text: p.price == 0 ? '' : '${p.price}');
    _descriptionController = TextEditingController(text: p.description);
    _addressController = TextEditingController(text: p.address);
    _areaController = TextEditingController(text: p.area == 0 ? '' : '${p.area}');
    _floorController = TextEditingController(text: p.floor == 0 ? '' : '${p.floor}');
    _totalFloorsController = TextEditingController(text: p.totalFloors == 0 ? '' : '${p.totalFloors}');
    _buildingForm = p.buildingForm;
    _renovationLevel = p.renovationLevel;
    _constructionStatus = p.constructionStatus;
    _bathroomType = p.bathroomType;
    _hasTechPassport = p.hasTechPassport;
    _existingPhotoUrls = List.of(p.photoUrls);
    _ownerPhoneController = TextEditingController(text: widget.privateInfo.ownerPhone);
    _commissionType = widget.privateInfo.commissionType;
    _commissionValueController =
        TextEditingController(text: widget.privateInfo.commissionValue == 0 ? '' : '${widget.privateInfo.commissionValue}');
  }

  Future<void> _pickPhotos() async {
    final images = await _picker.pickMultiImage();
    setState(() => _newPhotos.addAll(images));
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final photoUrls = List<String>.from(_existingPhotoUrls);
      for (final photo in _newPhotos) {
        try {
          photoUrls.add(await _storageService.uploadPropertyPhoto(widget.property.companyId, photo));
        } catch (_) {
          // Агар Storage дастрас набошад, акси нав гузашта мешавад, аксҳои кӯҳна мемонанд.
        }
      }

      final updated = Property(
        id: widget.property.id,
        companyId: widget.property.companyId,
        addedByUid: widget.property.addedByUid,
        addedByName: widget.property.addedByName,
        addedByPhone: widget.property.addedByPhone,
        createdAt: widget.property.createdAt,
        isSold: widget.property.isSold,
        category: _category,
        houseLandType: _houseLandType,
        rooms: int.tryParse(_roomsController.text) ?? 0,
        houseFloorsCount: int.tryParse(_houseFloorsController.text) ?? 0,
        landSotka: double.tryParse(_landSotkaController.text) ?? 0,
        price: double.tryParse(_priceController.text) ?? 0,
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        area: double.tryParse(_areaController.text) ?? 0,
        floor: int.tryParse(_floorController.text) ?? 0,
        totalFloors: int.tryParse(_totalFloorsController.text) ?? 0,
        buildingForm: _buildingForm,
        renovationLevel: _renovationLevel,
        constructionStatus: _constructionStatus,
        bathroomType: _bathroomType,
        hasTechPassport: _hasTechPassport,
        photoUrls: photoUrls,
      );

      final updatedPrivate = PropertyPrivateInfo(
        ownerPhone: _ownerPhoneController.text.trim(),
        commissionType: _commissionType,
        commissionValue: double.tryParse(_commissionValueController.text) ?? 0,
      );

      await _firestoreService.updateProperty(widget.property.id, updated, updatedPrivate);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final t = context.read<LocaleService>().strings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.locale == AppLocale.ru ? 'Удалить объект?' : 'Хонаро ҳазф кунем?'),
        content: Text(t.locale == AppLocale.ru
            ? 'Это действие нельзя отменить.'
            : 'Ин амалро баргардонидан мумкин нест.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Бекор')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ҳазф', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await _firestoreService.deleteProperty(widget.property.id);
      if (mounted) {
        Navigator.pop(context); // EditPropertyScreen
        Navigator.pop(context); // PropertyDetailScreen
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _deleting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleService>().strings;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('add_property')),
        actions: [
          IconButton(
            icon: _deleting
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _deleting ? null : _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Категория (танҳо намоиш — тағйир додани категория пас аз сохтан мураккаб аст)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _kPrimary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _category == ListingCategory.apartment
                    ? t.t('category_apartment')
                    : (_houseLandType == HouseLandType.dacha ? t.t('houseland_dacha') : t.t('houseland_havli')),
                style: const TextStyle(fontWeight: FontWeight.w700, color: _kPrimary),
              ),
            ),
            const SizedBox(height: 16),

            if (_category == ListingCategory.apartment) ...[
              TextField(
                controller: _roomsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: t.t('step_rooms_title')),
              ),
              const SizedBox(height: 12),
            ] else ...[
              TextField(
                controller: _houseFloorsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: t.t('step_house_floors_title')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _landSotkaController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: t.t('step_land_sotka_title')),
              ),
              const SizedBox(height: 12),
            ],

            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: t.t('step_price_title'), suffixText: t.t('somoni')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(labelText: t.t('step_description_title')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(labelText: t.t('step_address_title')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _areaController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: t.t('step_area_title'), suffixText: 'м²'),
            ),
            if (_category == ListingCategory.apartment) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _floorController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: t.t('floor_label')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _totalFloorsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: t.t('total_floors_label')),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<BuildingForm>(
              value: _buildingForm,
              decoration: InputDecoration(labelText: t.t('step_building_form_title')),
              items: [
                DropdownMenuItem(value: BuildingForm.old, child: Text(t.t('building_old'))),
                DropdownMenuItem(value: BuildingForm.newConstruction, child: Text(t.t('building_new'))),
              ],
              onChanged: (v) => setState(() => _buildingForm = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<RenovationLevel>(
              value: _renovationLevel,
              decoration: InputDecoration(labelText: t.t('step_renovation_title')),
              items: [
                DropdownMenuItem(value: RenovationLevel.fresh, child: Text(t.t('renovation_fresh'))),
                DropdownMenuItem(value: RenovationLevel.average, child: Text(t.t('renovation_average'))),
                DropdownMenuItem(value: RenovationLevel.empty, child: Text(t.t('renovation_empty'))),
              ],
              onChanged: (v) => setState(() => _renovationLevel = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ConstructionStatus>(
              value: _constructionStatus,
              decoration: InputDecoration(labelText: t.t('step_construction_status_title')),
              items: [
                DropdownMenuItem(value: ConstructionStatus.built, child: Text(t.t('construction_built'))),
                DropdownMenuItem(
                    value: ConstructionStatus.underConstruction, child: Text(t.t('construction_in_progress'))),
              ],
              onChanged: (v) => setState(() => _constructionStatus = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<BathroomType>(
              value: _bathroomType,
              decoration: InputDecoration(labelText: t.t('step_bathroom_title')),
              items: [
                DropdownMenuItem(value: BathroomType.separate, child: Text(t.t('bathroom_separate'))),
                DropdownMenuItem(value: BathroomType.combined, child: Text(t.t('bathroom_combined'))),
              ],
              onChanged: (v) => setState(() => _bathroomType = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<bool>(
              value: _hasTechPassport,
              decoration: InputDecoration(labelText: t.t('step_tech_passport_title')),
              items: [
                DropdownMenuItem(value: true, child: Text(t.t('yes'))),
                DropdownMenuItem(value: false, child: Text(t.t('no'))),
              ],
              onChanged: (v) => setState(() => _hasTechPassport = v!),
            ),

            const SizedBox(height: 16),
            Text(t.t('step_photos_title'), style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._existingPhotoUrls.map((url) => Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(url, width: 84, height: 84, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: InkWell(
                            onTap: () => setState(() => _existingPhotoUrls.remove(url)),
                            child: const CircleAvatar(
                              radius: 11,
                              backgroundColor: Colors.black54,
                              child: Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    )),
                ..._newPhotos.map((f) => ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _XFileThumb(file: f, size: 84),
                    )),
                InkWell(
                  onTap: _pickPhotos,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 84,
                    height: 84,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.add_a_photo_outlined, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),

            const Divider(height: 32),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, size: 18, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(t.t('private_note'), style: const TextStyle(fontSize: 12, color: Colors.orange)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ownerPhoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: t.t('owner_phone')),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CommissionType>(
              value: _commissionType,
              decoration: InputDecoration(labelText: t.t('commission_type')),
              items: [
                DropdownMenuItem(value: CommissionType.percent, child: Text(t.t('commission_percent'))),
                DropdownMenuItem(value: CommissionType.margin, child: Text(t.t('commission_margin'))),
              ],
              onChanged: (v) => setState(() => _commissionType = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commissionValueController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: t.t('commission_value'),
                suffixText: _commissionType == CommissionType.percent ? '%' : t.t('somoni'),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(t.t('save')),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Пешнамоиши расм аз XFile — дар ҳама платформаҳо (Android, iOS, Web)
/// кор мекунад.
class _XFileThumb extends StatelessWidget {
  final XFile file;
  final double size;
  const _XFileThumb({required this.file, required this.size});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: file.readAsBytes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(width: size, height: size, color: Colors.grey.shade200);
        }
        return Image.memory(snapshot.data!, width: size, height: size, fit: BoxFit.cover);
      },
    );
  }
}
