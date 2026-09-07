import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property.dart';
import '../models/client.dart';
import '../models/app_user.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _properties => _db.collection('properties');
  CollectionReference get _clients => _db.collection('clients');
  CollectionReference get _users => _db.collection('users');

  /// Иловаи хонаи нав. Қисми оммавӣ ва хусусӣ дар ду ҳуҷҷати алоҳида
  /// нигоҳ дошта мешавад, то Security Rules тавонанд онҳоро алоҳида
  /// маҳдуд кунанд.
  Future<String> addProperty(Property property, PropertyPrivateInfo privateInfo) async {
    final docRef = _properties.doc();
    await docRef.set(property.toMap());
    await docRef.collection('private').doc('contact').set(privateInfo.toMap());
    return docRef.id;
  }

  /// "Ҳамаи хонаҳо" — ҳама менеҷерони ҳамаи ширкатҳо мебинанд,
  /// танҳо майдонҳои оммавӣ (managerPrice, на нархи соҳибхона).
  Stream<List<Property>> allProperties() {
    return _properties
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Property.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  /// "Хонаҳои ман" — танҳо хонаҳое, ки худи менеҷер илова кардааст.
  /// Мураттабсозӣ дар КЛИЕНТ иҷро мешавад (на дар дархости Firestore),
  /// то ниёз ба сохтани индекси таркибӣ (composite index) набошад.
  Stream<List<Property>> myProperties(String uid) {
    return _properties.where('addedByUid', isEqualTo: uid).snapshots().map((snap) {
      final list = snap.docs
          .map((d) => Property.fromMap(d.id, d.data() as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Гирифтани маълумоти хусусӣ — Security Rules тасдиқ мекунад, ки
  /// танҳо addedByUid ё админ/суперадмини ҳамон companyId иҷозат дорад.
  Future<PropertyPrivateInfo?> getPrivateInfo(String propertyId) async {
    final doc = await _properties.doc(propertyId).collection('private').doc('contact').get();
    if (!doc.exists) return null;
    return PropertyPrivateInfo.fromMap(doc.data()!);
  }

  /// Таҳрири хонаи мавҷуда — ҳарду ҳуҷҷат (оммавӣ ва хусусӣ) нав мешаванд.
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

  /// Мувофиқасозии оддии худкор: хонаҳое, ки бо буҷа ва шумораи
  /// ҳуҷраҳои муштарӣ мувофиқанд. Барои маҷмӯи калон беҳтар аст ин
  /// корро Cloud Function иҷро кунад, вале барои оғоз кофист дар client.
  // ---------- Идораи кормандон (менеҷерон/админҳо) ----------

  Stream<List<AppUser>> companyUsers(String companyId) {
    return _users.where('companyId', isEqualTo: companyId).snapshots().map((snap) {
      final list = snap.docs
          .map((d) => AppUser.fromMap(d.id, d.data() as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => a.fullName.compareTo(b.fullName));
      return list;
    });
  }

  /// Ҳазфи ҳуҷҷати корбар — дастрасии ӯро ба барнома қатъ мекунад.
  /// Диққат: ин ҳисоби Firebase Authentication-ро худаш ҳазф намекунад
  /// (Client SDK иҷозаи ҳазфи ҳисоби корбари дигарро надорад) — танҳо
  /// ҳуҷҷати нақшу дастрасии ӯро дар Firestore нест мекунад.
  Future<void> deleteUserDoc(String uid) => _users.doc(uid).delete();

  Future<List<Property>> matchPropertiesForClient(Client client) async {
    final snap = await _properties
        .where('isSold', isEqualTo: false)
        .get();
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
}
