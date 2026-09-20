class AppNotification {
  final String id;
  final String companyId;
  final String propertyId;
  final String address;
  final String managerName;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.companyId,
    required this.propertyId,
    required this.address,
    required this.managerName,
    required this.createdAt,
  });

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) {
    return AppNotification(
      id: id,
      companyId: map['companyId'] ?? '',
      propertyId: map['propertyId'] ?? '',
      address: map['address'] ?? '',
      managerName: map['managerName'] ?? '',
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
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
