import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/locale_service.dart';
import '../l10n/app_strings.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../models/property.dart';

const _kPrimary = Color(0xFF0F6B5C);

/// Иловаи хона — раванди қадам ба қадам (як савол дар як саҳифа),
/// мисли боти GreenHomeTaj. Тартиби қадамҳо вобаста ба категория
/// (Фуруши хонаҳо / Фуруши ҳавлӣ ва дача) фарқ мекунад.
class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  int _stepIndex = 0;
  bool _saving = false;
  String? _error;

  // ---- Ҷавобҳо ----
  ListingCategory? _category;
  HouseLandType? _houseLandType;
  final _roomsController = TextEditingController();
  final _houseFloorsController = TextEditingController();
  final _landSotkaController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _areaController = TextEditingController();
  final _floorController = TextEditingController();
  final _totalFloorsController = TextEditingController();
  BuildingForm? _buildingForm;
  RenovationLevel? _renovationLevel;
  ConstructionStatus? _constructionStatus;
  BathroomType? _bathroomType;
  bool? _hasTechPassport;
  final List<XFile> _photos = [];
  final _ownerPhoneController = TextEditingController();
  CommissionType _commissionType = CommissionType.percent;
  final _commissionValueController = TextEditingController();

  final _picker = ImagePicker();
  final _storageService = StorageService();
  final _firestoreService = FirestoreService();

  /// Пайдарпаии қадамҳо вобаста ба категорияи интихобшуда.
  List<String> get _steps {
    if (_category == null) return const ['category'];
    if (_category == ListingCategory.apartment) {
      return const [
        'category',
        'rooms',
        'price',
        'description',
        'address',
        'area',
        'floor',
        'buildingForm',
        'renovation',
        'constructionStatus',
        'bathroom',
        'techPassport',
        'photos',
        'owner',
      ];
    }
    return const [
      'category',
      'houseLandType',
      'houseFloors',
      'landSotka',
      'price',
      'description',
      'address',
      'area',
      'buildingForm',
      'renovation',
      'constructionStatus',
      'bathroom',
      'techPassport',
      'photos',
      'owner',
    ];
  }

  void _goNext() {
    setState(() {
      _error = null;
      if (_stepIndex < _steps.length - 1) _stepIndex++;
    });
  }

  void _goBack() {
    if (_stepIndex == 0) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _error = null;
      _stepIndex--;
    });
  }

  Future<void> _pickPhotos() async {
    final images = await _picker.pickMultiImage();
    setState(() => _photos.addAll(images));
  }

  Future<void> _save() async {
    final t = context.read<LocaleService>().strings;
    final user = context.read<AuthService>().currentUser;
    if (user == null) return;

    if (_ownerPhoneController.text.trim().isEmpty) {
      setState(() => _error = t.t('required_field'));
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final photoUrls = <String>[];
      var mediaUploadFailed = false;
      for (final photo in _photos) {
        try {
          photoUrls.add(await _storageService.uploadPropertyPhoto(user.companyId, photo));
        } catch (_) {
          mediaUploadFailed = true;
        }
      }

      final property = Property(
        id: '',
        companyId: user.companyId,
        addedByUid: user.uid,
        addedByName: user.fullName,
        addedByPhone: user.phone,
        createdAt: DateTime.now(),
        category: _category ?? ListingCategory.apartment,
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
        buildingForm: _buildingForm ?? BuildingForm.old,
        renovationLevel: _renovationLevel ?? RenovationLevel.average,
        constructionStatus: _constructionStatus ?? ConstructionStatus.built,
        bathroomType: _bathroomType ?? BathroomType.separate,
        hasTechPassport: _hasTechPassport ?? false,
        photoUrls: photoUrls,
      );

      final privateInfo = PropertyPrivateInfo(
        ownerPhone: _ownerPhoneController.text.trim(),
        commissionType: _commissionType,
        commissionValue: double.tryParse(_commissionValueController.text) ?? 0,
      );

      await _firestoreService.addProperty(property, privateInfo);

      if (mounted) {
        if (mediaUploadFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Хона сабт шуд, вале баъзе аксҳо бор нашуданд.')),
          );
        }
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleService>().strings;
    final steps = _steps;
    final key = steps[_stepIndex.clamp(0, steps.length - 1)];
    final progress = (_stepIndex + 1) / steps.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goBack),
        title: Text(t.t('add_property')),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            color: _kPrimary,
            minHeight: 3,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildStep(context, key, t),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Сохтани мундариҷаи ҳар қадам
  // ---------------------------------------------------------------------
  Widget _buildStep(BuildContext context, String key, AppStrings t) {
    switch (key) {
      case 'category':
        return _ChoiceStep(
          title: t.t('step_category_title'),
          options: [
            _Option(t.t('category_apartment'), Icons.apartment_rounded),
            _Option(t.t('category_house_land'), Icons.holiday_village_rounded),
          ],
          onSelected: (i) {
            setState(() {
              _category = i == 0 ? ListingCategory.apartment : ListingCategory.houseLand;
            });
            _goNext();
          },
        );

      case 'houseLandType':
        return _ChoiceStep(
          title: t.t('step_houseland_type_title'),
          options: [
            _Option(t.t('houseland_havli'), Icons.house_rounded),
            _Option(t.t('houseland_dacha'), Icons.cottage_rounded),
          ],
          onSelected: (i) {
            setState(() => _houseLandType = i == 0 ? HouseLandType.havli : HouseLandType.dacha);
            _goNext();
          },
        );

      case 'rooms':
        return _NumberStep(
          title: t.t('step_rooms_title'),
          controller: _roomsController,
          error: _error,
          t: t,
          onContinue: _goNext,
        );

      case 'houseFloors':
        return _NumberStep(
          title: t.t('step_house_floors_title'),
          controller: _houseFloorsController,
          error: _error,
          t: t,
          onContinue: _goNext,
        );

      case 'landSotka':
        return _NumberStep(
          title: t.t('step_land_sotka_title'),
          controller: _landSotkaController,
          error: _error,
          t: t,
          onContinue: _goNext,
        );

      case 'price':
        return _NumberStep(
          title: t.t('step_price_title'),
          controller: _priceController,
          suffix: t.t('somoni'),
          error: _error,
          t: t,
          onContinue: () {
            if (_priceController.text.trim().isEmpty) {
              setState(() => _error = t.t('required_field'));
              return;
            }
            _goNext();
          },
        );

      case 'description':
        return _TextAreaStep(
          title: t.t('step_description_title'),
          hint: t.t('step_description_hint'),
          controller: _descriptionController,
          t: t,
          onContinue: _goNext,
        );

      case 'address':
        return _TextFieldStep(
          title: t.t('step_address_title'),
          controller: _addressController,
          error: _error,
          t: t,
          onContinue: () {
            if (_addressController.text.trim().isEmpty) {
              setState(() => _error = t.t('required_field'));
              return;
            }
            _goNext();
          },
        );

      case 'area':
        return _NumberStep(
          title: t.t('step_area_title'),
          controller: _areaController,
          suffix: 'м²',
          error: _error,
          t: t,
          onContinue: _goNext,
        );

      case 'floor':
        return _TwoNumberStep(
          title: t.t('step_floor_title'),
          label1: t.t('floor_label'),
          label2: t.t('total_floors_label'),
          controller1: _floorController,
          controller2: _totalFloorsController,
          t: t,
          onContinue: _goNext,
        );

      case 'buildingForm':
        return _ChoiceStep(
          title: t.t('step_building_form_title'),
          options: [
            _Option(t.t('building_old'), Icons.foundation_rounded),
            _Option(t.t('building_new'), Icons.domain_add_rounded),
          ],
          onSelected: (i) {
            setState(() => _buildingForm = i == 0 ? BuildingForm.old : BuildingForm.newConstruction);
            _goNext();
          },
        );

      case 'renovation':
        return _ChoiceStep(
          title: t.t('step_renovation_title'),
          options: [
            _Option(t.t('renovation_fresh'), Icons.auto_awesome_rounded),
            _Option(t.t('renovation_average'), Icons.build_outlined),
            _Option(t.t('renovation_empty'), Icons.inbox_outlined),
          ],
          onSelected: (i) {
            setState(() => _renovationLevel = [
                  RenovationLevel.fresh,
                  RenovationLevel.average,
                  RenovationLevel.empty,
                ][i]);
            _goNext();
          },
        );

      case 'constructionStatus':
        return _ChoiceStep(
          title: t.t('step_construction_status_title'),
          options: [
            _Option(t.t('construction_built'), Icons.check_circle_outline_rounded),
            _Option(t.t('construction_in_progress'), Icons.construction_rounded),
          ],
          onSelected: (i) {
            setState(() => _constructionStatus =
                i == 0 ? ConstructionStatus.built : ConstructionStatus.underConstruction);
            _goNext();
          },
        );

      case 'bathroom':
        return _ChoiceStep(
          title: t.t('step_bathroom_title'),
          options: [
            _Option(t.t('bathroom_separate'), Icons.door_front_door_outlined),
            _Option(t.t('bathroom_combined'), Icons.bathtub_outlined),
          ],
          onSelected: (i) {
            setState(() => _bathroomType = i == 0 ? BathroomType.separate : BathroomType.combined);
            _goNext();
          },
        );

      case 'techPassport':
        return _ChoiceStep(
          title: t.t('step_tech_passport_title'),
          options: [
            _Option(t.t('yes'), Icons.description_outlined),
            _Option(t.t('no'), Icons.block_outlined),
          ],
          onSelected: (i) {
            setState(() => _hasTechPassport = i == 0);
            _goNext();
          },
        );

      case 'photos':
        return _PhotosStep(
          title: t.t('step_photos_title'),
          photos: _photos,
          onAdd: _pickPhotos,
          t: t,
          onContinue: _goNext,
        );

      case 'owner':
        return _OwnerStep(
          t: t,
          phoneController: _ownerPhoneController,
          commissionValueController: _commissionValueController,
          commissionType: _commissionType,
          onCommissionTypeChanged: (v) => setState(() => _commissionType = v),
          error: _error,
          saving: _saving,
          onSave: _save,
        );

      default:
        return const SizedBox();
    }
  }
}

// ===========================================================================
// Виҷетҳои ёрирасон барои ҳар навъи қадам
// ===========================================================================

class _Option {
  final String label;
  final IconData icon;
  _Option(this.label, this.icon);
}

class _StepTitle extends StatelessWidget {
  final String title;
  const _StepTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Text(
        title,
        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700, height: 1.3),
      ),
    );
  }
}

/// Қадами интихобӣ — тугмаҳои калон, зер кардан = гузаштани худкор.
class _ChoiceStep extends StatelessWidget {
  final String title;
  final List<_Option> options;
  final void Function(int index) onSelected;

  const _ChoiceStep({required this.title, required this.options, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(title: title),
        ...List.generate(options.length, (i) {
          final o = options[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => onSelected(i),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _kPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(o.icon, color: _kPrimary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(o.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

Widget _continueButton(AppStrings t, VoidCallback onPressed) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(onPressed: onPressed, child: Text(t.t('continue_button'))),
  );
}

class _NumberStep extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final String? suffix;
  final String? error;
  final AppStrings t;
  final VoidCallback onContinue;

  const _NumberStep({
    required this.title,
    required this.controller,
    this.suffix,
    required this.error,
    required this.t,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(title: title),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          decoration: InputDecoration(suffixText: suffix),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(error!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 24),
        _continueButton(t, onContinue),
      ],
    );
  }
}

class _TwoNumberStep extends StatelessWidget {
  final String title;
  final String label1;
  final String label2;
  final TextEditingController controller1;
  final TextEditingController controller2;
  final AppStrings t;
  final VoidCallback onContinue;

  const _TwoNumberStep({
    required this.title,
    required this.label1,
    required this.label2,
    required this.controller1,
    required this.controller2,
    required this.t,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(title: title),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller1,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(labelText: label1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller2,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: label2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _continueButton(t, onContinue),
      ],
    );
  }
}

class _TextFieldStep extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final String? error;
  final AppStrings t;
  final VoidCallback onContinue;

  const _TextFieldStep({
    required this.title,
    required this.controller,
    required this.error,
    required this.t,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(title: title),
        TextField(controller: controller, autofocus: true, style: const TextStyle(fontSize: 17)),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(error!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 24),
        _continueButton(t, onContinue),
      ],
    );
  }
}

class _TextAreaStep extends StatelessWidget {
  final String title;
  final String hint;
  final TextEditingController controller;
  final AppStrings t;
  final VoidCallback onContinue;

  const _TextAreaStep({
    required this.title,
    required this.hint,
    required this.controller,
    required this.t,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(title: title),
        TextField(
          controller: controller,
          maxLines: 5,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
        ),
        const SizedBox(height: 24),
        _continueButton(t, onContinue),
      ],
    );
  }
}

class _PhotosStep extends StatelessWidget {
  final String title;
  final List<XFile> photos;
  final VoidCallback onAdd;
  final AppStrings t;
  final VoidCallback onContinue;

  const _PhotosStep({
    required this.title,
    required this.photos,
    required this.onAdd,
    required this.t,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(title: title),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ...photos.map((f) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _XFileThumb(file: f, size: 92),
                )),
            InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 92,
                height: 92,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  color: Colors.white,
                ),
                child: Icon(Icons.add_a_photo_outlined, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _continueButton(t, onContinue),
      ],
    );
  }
}

class _OwnerStep extends StatelessWidget {
  final AppStrings t;
  final TextEditingController phoneController;
  final TextEditingController commissionValueController;
  final CommissionType commissionType;
  final ValueChanged<CommissionType> onCommissionTypeChanged;
  final String? error;
  final bool saving;
  final VoidCallback onSave;

  const _OwnerStep({
    required this.t,
    required this.phoneController,
    required this.commissionValueController,
    required this.commissionType,
    required this.onCommissionTypeChanged,
    required this.error,
    required this.saving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(title: t.t('step_owner_title')),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
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
        const SizedBox(height: 16),
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(labelText: t.t('owner_phone')),
        ),
        const SizedBox(height: 16),
        Text(t.t('commission_type'), style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _RadioCard(
          label: t.t('commission_percent'),
          selected: commissionType == CommissionType.percent,
          onTap: () => onCommissionTypeChanged(CommissionType.percent),
        ),
        const SizedBox(height: 8),
        _RadioCard(
          label: t.t('commission_margin'),
          selected: commissionType == CommissionType.margin,
          onTap: () => onCommissionTypeChanged(CommissionType.margin),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: commissionValueController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: t.t('commission_value'),
            suffixText: commissionType == CommissionType.percent ? '%' : t.t('somoni'),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: saving ? null : onSave,
            child: saving
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(t.t('save')),
          ),
        ),
      ],
    );
  }
}

class _RadioCard extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RadioCard({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? _kPrimary.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? _kPrimary : Colors.grey.shade300, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? _kPrimary : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13.5))),
          ],
        ),
      ),
    );
  }
}

/// Пешнамоиши расм аз XFile — дар ҳама платформаҳо (Android, iOS, Web)
/// кор мекунад, зеро аз readAsBytes() + Image.memory истифода мебарад.
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
          return Container(
            width: size,
            height: size,
            color: Colors.grey.shade200,
          );
        }
        return Image.memory(snapshot.data!, width: size, height: size, fit: BoxFit.cover);
      },
    );
  }
}
