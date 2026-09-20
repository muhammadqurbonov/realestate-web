import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property.dart';
import '../models/client.dart';
import '../models/app_user.dart';
import '../models/app_notification.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _properties => _db.collection('properties');
  CollectionReference get _clients => _db.collection('clients');
  CollectionReference get _users => _db.collection('users');
  CollectionReference get _notifications => _db.collection('notifications');

  // ---------- Хонаҳо ----------

  /// Иловаи хонаи нав. Қисми оммавӣ ва хусусӣ дар ду ҳуҷҷати алоҳида
  /// нигоҳ дошта мешавад. Инчунин барои дигар кормандони ширкат як
  /// огоҳии "хонаи нав илова шуд" сабт мешавад.
  Future<String> addProperty(Property property, PropertyPrivateInfo privateInfo) async {
    final docRef = _properties.doc();
    await docRef.set(property.toMap());
    await docRef.collection('private').doc('contact').set(privateInfo.toMap());

    await _notifications.add(AppNotification(
      id: '',
      companyId: property.companyId,
      propertyId: docRef.id,
      address: property.address,
      managerName: property.addedByName,
      createdAt: DateTime.now(),
    ).toMap());

    return docRef.id;
  }

  Stream<List<Property>> allProperties() {
    return _properties.orderBy('createdAt', descending: true).snapshots().map((snap) => snap.docs
        .map((d) => Property.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList());
  }

  /// "Хонаҳои ман" — мураттабсозӣ дар КЛИЕНТ иҷро мешавад, то ниёз ба
  /// индекси таркибӣ набошад.
  Stream<List<Property>> myProperties(String uid) {
    return _properties.where('addedByUid', isEqualTo: uid).snapshots().map((snap) {
      final list = snap.docs
          .map((d) => Property.fromMap(d.id, d.data() as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<Property?> getProperty(String propertyId) async {
    final doc = await _properties.doc(propertyId).get();
    if (!doc.exists) return null;
    return Property.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  Future<PropertyPrivateInfo?> getPrivateInfo(String propertyId) async {
    final doc = await _properties.doc(propertyId).collection('private').doc('contact').get();
    if (!doc.exists) return null;
    return PropertyPrivateInfo.fromMap(doc.data()!);
  }

  Future<void> updateProperty(
      String propertyId, Property property, PropertyPrivateInfo privateInfo) async {
    await _properties.doc(propertyId).set(property.toMap());
    await _properties.doc(propertyId).collection('private').doc('contact').set(privateInfo.toMap());
  }

  Future<void> setSold(String propertyId, bool isSold) =>
      _properties.doc(propertyId).update({'isSold': isSold});

  Future<void> deleteProperty(String propertyId) async {
    await _properties.doc(propertyId).collection('private').doc('contact').delete();
    await _properties.doc(propertyId).delete();
  }

  // ---------- Муштариён ----------

  Future<String> addClient(Client client) async {
    final docRef = _clients.doc();
    await docRef.set(client.toMap());
    return docRef.id;
  }

  Future<void> deleteClient(String clientId) => _clients.doc(clientId).delete();

  Stream<List<Client>> companyClients(String companyId) {
    return _clients.where('companyId', isEqualTo: companyId).snapshots().map((snap) {
      final list = snap.docs
          .map((d) => Client.fromMap(d.id, d.data() as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<List<Property>> matchPropertiesForClient(Client client) async {
    final snap = await _properties.where('isSold', isEqualTo: false).get();
    final all = snap.docs
        .map((d) => Property.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList();
    return all.where((p) {
      final roomsOk = p.category != ListingCategory.apartment ||
          (p.rooms >= client.minRooms && p.rooms <= client.maxRooms);
      final budgetOk = p.price >= client.minBudget && p.price <= client.maxBudget;
      return roomsOk && budgetOk;
    }).toList();
  }

  // ---------- Идораи кормандон ----------

  Stream<List<AppUser>> companyUsers(String companyId) {
    return _users.where('companyId', isEqualTo: companyId).snapshots().map((snap) {
      final list = snap.docs
          .map((d) => AppUser.fromMap(d.id, d.data() as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => a.fullName.compareTo(b.fullName));
      return list;
    });
  }

  Future<void> deleteUserDoc(String uid) => _users.doc(uid).delete();

  // ---------- Огоҳиномаҳо ----------

  /// 50-тои охирини огоҳиномаҳои ширкат — "фалон менеҷер хонаи нав
  /// илова кард".
  Stream<List<AppNotification>> companyNotifications(String companyId) {
    return _notifications
        .where('companyId', isEqualTo: companyId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppNotification.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList());
  }
}
