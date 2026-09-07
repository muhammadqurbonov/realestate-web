/// Категорияи эълон: фуруши хонаҳо/квартираҳо ё фуруши ҳавлӣ/дача.
enum ListingCategory { apartment, houseLand }

ListingCategory listingCategoryFromString(String value) =>
    value == 'houseLand' ? ListingCategory.houseLand : ListingCategory.apartment;

String listingCategoryToString(ListingCategory value) =>
    value == ListingCategory.houseLand ? 'houseLand' : 'apartment';

/// Навъи амволи ҳавлӣ/дача (танҳо агар category == houseLand).
enum HouseLandType { havli, dacha }

HouseLandType houseLandTypeFromString(String value) =>
    value == 'dacha' ? HouseLandType.dacha : HouseLandType.havli;

String houseLandTypeToString(HouseLandType value) =>
    value == HouseLandType.dacha ? 'dacha' : 'havli';

/// Шакли бино: пешина ё навсохт.
enum BuildingForm { old, newConstruction }

BuildingForm buildingFormFromString(String value) =>
    value == 'newConstruction' ? BuildingForm.newConstruction : BuildingForm.old;

String buildingFormToString(BuildingForm value) =>
    value == BuildingForm.newConstruction ? 'newConstruction' : 'old';

/// Ҳолати таъмир: нав, миёна, бетаъмир (қуттии холӣ).
enum RenovationLevel { fresh, average, empty }

RenovationLevel renovationLevelFromString(String value) {
  switch (value) {
    case 'fresh':
      return RenovationLevel.fresh;
    case 'empty':
      return RenovationLevel.empty;
    default:
      return RenovationLevel.average;
  }
}

String renovationLevelToString(RenovationLevel value) {
  switch (value) {
    case RenovationLevel.fresh:
      return 'fresh';
    case RenovationLevel.empty:
      return 'empty';
    case RenovationLevel.average:
      return 'average';
  }
}

/// Ҳолати бино: сохташуда ё дар марҳилаи сохтмон.
enum ConstructionStatus { built, underConstruction }

ConstructionStatus constructionStatusFromString(String value) =>
    value == 'underConstruction' ? ConstructionStatus.underConstruction : ConstructionStatus.built;

String constructionStatusToString(ConstructionStatus value) =>
    value == ConstructionStatus.underConstruction ? 'underConstruction' : 'built';

/// Ҳаммом/ҳоҷатхона: алоҳида ё якҷоя.
enum BathroomType { separate, combined }

BathroomType bathroomTypeFromString(String value) =>
    value == 'combined' ? BathroomType.combined : BathroomType.separate;

String bathroomTypeToString(BathroomType value) =>
    value == BathroomType.combined ? 'combined' : 'separate';

/// Навъи маслиҳат бо соҳибхона (комиссия):
/// - percent: соҳибхона фоизе аз маблағи фурӯш мегирад
/// - margin: соҳибхона маблағи собит мехоҳад, фарқият фоидаи менеҷер аст
enum CommissionType { percent, margin }

CommissionType commissionTypeFromString(String value) =>
    value == 'margin' ? CommissionType.margin : CommissionType.percent;

String commissionTypeToString(CommissionType type) =>
    type == CommissionType.margin ? 'margin' : 'percent';

/// Қисми ОММАВӢ — ҳама менеҷерони ҳамаи ширкатҳо инро мебинанд.
/// Ҳама маълумот ба ҷуз "маслиҳат бо соҳибхона" (рақами соҳибхона +
/// навъи комиссия) дар ин ҷо аст.
class Property {
  final String id;
  final String companyId;
  final String addedByUid;
  final String addedByName;
  final String addedByPhone;
  final DateTime createdAt;
  final bool isSold;

  final ListingCategory category;
  final HouseLandType? houseLandType; // танҳо агар category == houseLand

  final int rooms; // танҳо барои apartment
  final int houseFloorsCount; // "миқдори ошёнаҳо" — танҳо барои houseLand
  final double landSotka; // "сотиқи замин" — танҳо барои houseLand

  final double price;
  final String description;
  final String address;
  final double area;
  final int floor; // ошёна — танҳо барои apartment
  final int totalFloors; // шумораи ошёнаҳои бино — танҳо барои apartment

  final BuildingForm buildingForm;
  final RenovationLevel renovationLevel;
  final ConstructionStatus constructionStatus;
  final BathroomType bathroomType;
  final bool hasTechPassport;

  final List<String> photoUrls;

  Property({
    required this.id,
    required this.companyId,
    required this.addedByUid,
    required this.addedByName,
    required this.addedByPhone,
    required this.createdAt,
    this.isSold = false,
    required this.category,
    this.houseLandType,
    this.rooms = 0,
    this.houseFloorsCount = 0,
    this.landSotka = 0,
    required this.price,
    required this.description,
    required this.address,
    required this.area,
    this.floor = 0,
    this.totalFloors = 0,
    required this.buildingForm,
    required this.renovationLevel,
    required this.constructionStatus,
    required this.bathroomType,
    required this.hasTechPassport,
    required this.photoUrls,
  });

  factory Property.fromMap(String id, Map<String, dynamic> map) {
    return Property(
      id: id,
      companyId: map['companyId'] ?? '',
      addedByUid: map['addedByUid'] ?? '',
      addedByName: map['addedByName'] ?? '',
      addedByPhone: map['addedByPhone'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      isSold: map['isSold'] ?? false,
      category: listingCategoryFromString(map['category'] ?? 'apartment'),
      houseLandType: map['houseLandType'] != null
          ? houseLandTypeFromString(map['houseLandType'])
          : null,
      rooms: map['rooms'] ?? 0,
      houseFloorsCount: map['houseFloorsCount'] ?? 0,
      landSotka: (map['landSotka'] ?? 0).toDouble(),
      price: (map['price'] ?? 0).toDouble(),
      description: map['description'] ?? '',
      address: map['address'] ?? '',
      area: (map['area'] ?? 0).toDouble(),
      floor: map['floor'] ?? 0,
      totalFloors: map['totalFloors'] ?? 0,
      buildingForm: buildingFormFromString(map['buildingForm'] ?? 'old'),
      renovationLevel: renovationLevelFromString(map['renovationLevel'] ?? 'average'),
      constructionStatus: constructionStatusFromString(map['constructionStatus'] ?? 'built'),
      bathroomType: bathroomTypeFromString(map['bathroomType'] ?? 'separate'),
      hasTechPassport: map['hasTechPassport'] ?? false,
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'addedByUid': addedByUid,
      'addedByName': addedByName,
      'addedByPhone': addedByPhone,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isSold': isSold,
      'category': listingCategoryToString(category),
      'houseLandType': houseLandType != null ? houseLandTypeToString(houseLandType!) : null,
      'rooms': rooms,
      'houseFloorsCount': houseFloorsCount,
      'landSotka': landSotka,
      'price': price,
      'description': description,
      'address': address,
      'area': area,
      'floor': floor,
      'totalFloors': totalFloors,
      'buildingForm': buildingFormToString(buildingForm),
      'renovationLevel': renovationLevelToString(renovationLevel),
      'constructionStatus': constructionStatusToString(constructionStatus),
      'bathroomType': bathroomTypeToString(bathroomType),
      'hasTechPassport': hasTechPassport,
      'photoUrls': photoUrls,
    };
  }
}

/// Қисми ХУСУСӢ (private subcollection: properties/{id}/private/contact).
/// "Маслиҳат бо соҳибхона" — танҳо менеҷери иловакунанда ё
/// админ/суперадмини ҳамон ширкат мебинад.
class PropertyPrivateInfo {
  final String ownerPhone;
  final CommissionType commissionType;
  final double commissionValue; // фоиз агар percent, маблағи собит агар margin

  PropertyPrivateInfo({
    required this.ownerPhone,
    required this.commissionType,
    required this.commissionValue,
  });

  factory PropertyPrivateInfo.fromMap(Map<String, dynamic> map) {
    return PropertyPrivateInfo(
      ownerPhone: map['ownerPhone'] ?? '',
      commissionType: commissionTypeFromString(map['commissionType'] ?? 'percent'),
      commissionValue: (map['commissionValue'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerPhone': ownerPhone,
      'commissionType': commissionTypeToString(commissionType),
      'commissionValue': commissionValue,
    };
  }
}
