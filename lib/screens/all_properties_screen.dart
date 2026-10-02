import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/locale_service.dart';
import '../models/property.dart';
import '../widgets/property_card.dart';
import '../l10n/app_strings.dart';

const _kPrimary = Color(0xFF0F6B5C);

class AllPropertiesScreen extends StatefulWidget {
  const AllPropertiesScreen({super.key});

  @override
  State<AllPropertiesScreen> createState() => _AllPropertiesScreenState();
}

class _AllPropertiesScreenState extends State<AllPropertiesScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  ListingCategory? _filterCategory;
  double? _minPrice;
  double? _maxPrice;
  int? _minRooms;
  int? _maxRooms;
  RenovationLevel? _filterRenovation;
  ConstructionStatus? _filterConstruction;

  bool get _hasActiveFilters =>
      _filterCategory != null ||
      _minPrice != null ||
      _maxPrice != null ||
      _minRooms != null ||
      _maxRooms != null ||
      _filterRenovation != null ||
      _filterConstruction != null;

  List<Property> _applyFilters(List<Property> all) {
    return all.where((p) {
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        final matchesAddress = p.address.toLowerCase().contains(q);
        final matchesLandmark = p.landmark.toLowerCase().contains(q);
        if (!matchesAddress && !matchesLandmark) return false;
      }
      if (_filterCategory != null && p.category != _filterCategory) return false;
      if (_minPrice != null && p.price < _minPrice!) return false;
      if (_maxPrice != null && p.price > _maxPrice!) return false;
      if (_filterRenovation != null && p.renovationLevel != _filterRenovation) return false;
      if (_filterConstruction != null && p.constructionStatus != _filterConstruction) return false;
      if (p.category == ListingCategory.apartment) {
        if (_minRooms != null && p.rooms < _minRooms!) return false;
        if (_maxRooms != null && p.rooms > _maxRooms!) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _openFilters() async {
    final t = context.read<LocaleService>().strings;
    final result = await showModalBottomSheet<_FilterResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FilterSheet(
        t: t,
        initialCategory: _filterCategory,
        initialMinPrice: _minPrice,
        initialMaxPrice: _maxPrice,
        initialMinRooms: _minRooms,
        initialMaxRooms: _maxRooms,
        initialRenovation: _filterRenovation,
        initialConstruction: _filterConstruction,
      ),
    );
    if (result != null) {
      setState(() {
        _filterCategory = result.category;
        _minPrice = result.minPrice;
        _maxPrice = result.maxPrice;
        _minRooms = result.minRooms;
        _maxRooms = result.maxRooms;
        _filterRenovation = result.renovation;
        _filterConstruction = result.construction;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleService>().strings;
    final user = context.watch<AuthService>().currentUser;
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: Text(t.t('all_properties'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(hintText: t.t('search_hint'), prefixIcon: const Icon(Icons.search), isDense: true),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: _openFilters,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _hasActiveFilters ? _kPrimary : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _hasActiveFilters ? _kPrimary : Colors.grey.shade300),
                    ),
                    child: Icon(Icons.tune_rounded, color: _hasActiveFilters ? Colors.white : Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Property>>(
              stream: firestoreService.allProperties(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('${snapshot.error}', style: const TextStyle(color: Colors.red)),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final properties = _applyFilters(snapshot.data!);
                if (properties.isEmpty) {
                  return Center(child: Text(t.t('no_results'), style: const TextStyle(color: Colors.grey)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: properties.length,
                  itemBuilder: (context, index) {
                    final property = properties[index];
                    final canSeePrivate = user != null &&
                        (user.uid == property.addedByUid || (user.canManageManagers && user.companyId == property.companyId));
                    return PropertyCard(property: property, canSeePrivate: canSeePrivate);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterResult {
  final ListingCategory? category;
  final double? minPrice;
  final double? maxPrice;
  final int? minRooms;
  final int? maxRooms;
  final RenovationLevel? renovation;
  final ConstructionStatus? construction;
  _FilterResult({this.category, this.minPrice, this.maxPrice, this.minRooms, this.maxRooms, this.renovation, this.construction});
}

class _FilterSheet extends StatefulWidget {
  final AppStrings t;
  final ListingCategory? initialCategory;
  final double? initialMinPrice;
  final double? initialMaxPrice;
  final int? initialMinRooms;
  final int? initialMaxRooms;
  final RenovationLevel? initialRenovation;
  final ConstructionStatus? initialConstruction;

  const _FilterSheet({
    required this.t,
    required this.initialCategory,
    required this.initialMinPrice,
    required this.initialMaxPrice,
    required this.initialMinRooms,
    required this.initialMaxRooms,
    required this.initialRenovation,
    required this.initialConstruction,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  ListingCategory? _category;
  RenovationLevel? _renovation;
  ConstructionStatus? _construction;
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  late TextEditingController _minRoomsController;
  late TextEditingController _maxRoomsController;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _renovation = widget.initialRenovation;
    _construction = widget.initialConstruction;
    _minPriceController = TextEditingController(text: widget.initialMinPrice?.toStringAsFixed(0) ?? '');
    _maxPriceController = TextEditingController(text: widget.initialMaxPrice?.toStringAsFixed(0) ?? '');
    _minRoomsController = TextEditingController(text: widget.initialMinRooms?.toString() ?? '');
    _maxRoomsController = TextEditingController(text: widget.initialMaxRooms?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t.t('filters'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _category = null;
                      _renovation = null;
                      _construction = null;
                      _minPriceController.clear();
                      _maxPriceController.clear();
                      _minRoomsController.clear();
                      _maxRoomsController.clear();
                    });
                  },
                  child: Text(t.t('filter_reset')),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(t.t('filter_category'), style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(label: Text(t.t('filter_all')), selected: _category == null, onSelected: (_) => setState(() => _category = null)),
                ChoiceChip(label: Text(t.t('category_apartment')), selected: _category == ListingCategory.apartment, onSelected: (_) => setState(() => _category = ListingCategory.apartment)),
                ChoiceChip(label: Text(t.t('category_house_land')), selected: _category == ListingCategory.houseLand, onSelected: (_) => setState(() => _category = ListingCategory.houseLand)),
              ],
            ),
            const SizedBox(height: 16),
            Text(t.t('filter_price_range'), style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextField(controller: _minPriceController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: t.t('filter_min')))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _maxPriceController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: t.t('filter_max')))),
              ],
            ),
            const SizedBox(height: 16),
            Text(t.t('filter_rooms'), style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextField(controller: _minRoomsController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: t.t('filter_min')))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _maxRoomsController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: t.t('filter_max')))),
              ],
            ),
            const SizedBox(height: 16),
            Text(t.t('filter_renovation'), style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(label: Text(t.t('filter_all')), selected: _renovation == null, onSelected: (_) => setState(() => _renovation = null)),
                ChoiceChip(label: Text(t.t('renovation_fresh')), selected: _renovation == RenovationLevel.fresh, onSelected: (_) => setState(() => _renovation = RenovationLevel.fresh)),
                ChoiceChip(label: Text(t.t('renovation_average')), selected: _renovation == RenovationLevel.average, onSelected: (_) => setState(() => _renovation = RenovationLevel.average)),
                ChoiceChip(label: Text(t.t('renovation_empty')), selected: _renovation == RenovationLevel.empty, onSelected: (_) => setState(() => _renovation = RenovationLevel.empty)),
              ],
            ),
            const SizedBox(height: 16),
            Text(t.t('filter_construction'), style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(label: Text(t.t('filter_all')), selected: _construction == null, onSelected: (_) => setState(() => _construction = null)),
                ChoiceChip(label: Text(t.t('construction_built')), selected: _construction == ConstructionStatus.built, onSelected: (_) => setState(() => _construction = ConstructionStatus.built)),
                ChoiceChip(label: Text(t.t('construction_in_progress')), selected: _construction == ConstructionStatus.underConstruction, onSelected: (_) => setState(() => _construction = ConstructionStatus.underConstruction)),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  _FilterResult(
                    category: _category,
                    minPrice: double.tryParse(_minPriceController.text),
                    maxPrice: double.tryParse(_maxPriceController.text),
                    minRooms: int.tryParse(_minRoomsController.text),
                    maxRooms: int.tryParse(_maxRoomsController.text),
                    renovation: _renovation,
                    construction: _construction,
                  ),
                );
              },
              child: Text(t.t('filter_apply')),
            ),
          ],
        ),
      ),
    );
  }
}
