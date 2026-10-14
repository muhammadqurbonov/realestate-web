/// Навъҳои огоҳинома.
const String kNotifNewProperty = 'new_property';
const String kNotifClientMatch = 'client_match';

/// Танҳо барои админҳо: менеҷери нав интизори тасдиқ аст.
/// (managerName — ном, address — телефон, propertyId/addedByUid — uid-и корбар)
const String kNotifJoinRequest = 'join_request';

class AppNotification {
  final String id;
  final String companyId;
  final String propertyId;
  final String address;
  final String managerName;
  final DateTime createdAt;

  /// 'new_property' — менеҷер хонаи нав илова кард;
  /// 'client_match' — хонаи нав ба муштарии ҳамин менеҷер мувофиқ аст.
  final String type;

  /// UID-и менеҷере, ки хонаро илова кардааст (барои пинҳон кардани огоҳии худӣ).
  final String addedByUid;

  /// Танҳо барои 'client_match'.
  final String clientName;

  AppNotification({
    required this.id,
    required this.companyId,
    required this.propertyId,
    required this.address,
    required this.managerName,
    required this.createdAt,
    this.type = kNotifNewProperty,
    this.addedByUid = '',
    this.clientName = '',
  });

  bool get isClientMatch => type == kNotifClientMatch;
  bool get isJoinRequest => type == kNotifJoinRequest;

  /// Сарлавҳаи кӯтоҳ.
  String title(bool isRu) {
    if (isJoinRequest) {
      return isRu ? '$managerName хочет войти в приложение' : '$managerName мехоҳад ба барнома дохил шавад';
    }
    if (isClientMatch) {
      return isRu ? 'Подходит вашему клиенту «$clientName»' : 'Ба муштарии шумо «$clientName» мувофиқ аст';
    }
    return isRu ? '$managerName добавил(а) новый объект' : '$managerName хонаи нав илова кард';
  }

  /// Матни пурра (барои SnackBar).
  String message(bool isRu) {
    if (isJoinRequest) {
      return isRu
          ? 'Новая заявка на вход: $managerName ($address)'
          : 'Дархости нави воридшавӣ: $managerName ($address)';
    }
    if (isClientMatch) {
      return isRu
          ? 'Новый объект подходит клиенту «$clientName»: $address (добавил(а) $managerName)'
          : 'Хонаи нав ба муштарии «$clientName» мувофиқ аст: $address (илова кард: $managerName)';
    }
    return isRu
        ? '$managerName добавил(а) новый объект: $address'
        : '$managerName хонаи нав илова кард: $address';
  }

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) {
    return AppNotification(
      id: id,
      companyId: map['companyId'] ?? '',
      propertyId: map['propertyId'] ?? '',
      address: map['address'] ?? '',
      managerName: map['managerName'] ?? '',
      type: map['type'] ?? kNotifNewProperty,
      addedByUid: map['addedByUid'] ?? '',
      clientName: map['clientName'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'propertyId': propertyId,
      'address': address,
      'managerName': managerName,
      'type': type,
      'addedByUid': addedByUid,
      'clientName': clientName,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
