/// Нақшҳои корбар. Тартиби иерархия:
/// superAdmin > admin > manager
enum UserRole { superAdmin, admin, manager }

UserRole roleFromString(String value) {
  switch (value) {
    case 'superAdmin':
      return UserRole.superAdmin;
    case 'admin':
      return UserRole.admin;
    default:
      return UserRole.manager;
  }
}

String roleToString(UserRole role) {
  switch (role) {
    case UserRole.superAdmin:
      return 'superAdmin';
    case UserRole.admin:
      return 'admin';
    case UserRole.manager:
      return 'manager';
  }
}

class AppUser {
  final String uid;
  final String fullName;
  final String phone;
  final UserRole role;
  final String companyId;

  AppUser({
    required this.uid,
    required this.fullName,
    required this.phone,
    required this.role,
    required this.companyId,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      fullName: map['fullName'] ?? '',
      phone: map['phone'] ?? '',
      role: roleFromString(map['role'] ?? 'manager'),
      companyId: map['companyId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'phone': phone,
      'role': roleToString(role),
      'companyId': companyId,
    };
  }

  bool get canManageManagers => role == UserRole.superAdmin || role == UserRole.admin;
  bool get canManageAdmins => role == UserRole.superAdmin;
}
