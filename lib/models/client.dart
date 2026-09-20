/// Талаботи муштарӣ — барои мувофиқасозии худкор бо properties.
class Client {
  final String id;
  final String companyId;
  final String addedByUid;
  final String fullName;
  final String phone;
  final int minRooms;
  final int maxRooms;
  final double minBudget;
  final double maxBudget;
  final String preferredArea;
  final DateTime createdAt;

  Client({
    required this.id,
    required this.companyId,
    required this.addedByUid,
    required this.fullName,
    required this.phone,
    required this.minRooms,
    required this.maxRooms,
    required this.minBudget,
    required this.maxBudget,
    required this.preferredArea,
    required this.createdAt,
  });

  factory Client.fromMap(String id, Map<String, dynamic> map) {
    return Client(
      id: id,
      companyId: map['companyId'] ?? '',
      addedByUid: map['addedByUid'] ?? '',
      fullName: map['fullName'] ?? '',
      phone: map['phone'] ?? '',
      minRooms: map['minRooms'] ?? 0,
      maxRooms: map['maxRooms'] ?? 99,
      minBudget: (map['minBudget'] ?? 0).toDouble(),
      maxBudget: (map['maxBudget'] ?? 0).toDouble(),
      preferredArea: map['preferredArea'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'addedByUid': addedByUid,
      'fullName': fullName,
      'phone': phone,
      'minRooms': minRooms,
      'maxRooms': maxRooms,
      'minBudget': minBudget,
      'maxBudget': maxBudget,
      'preferredArea': preferredArea,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
