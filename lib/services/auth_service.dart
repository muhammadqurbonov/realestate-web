import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';

/// Идоракунии воридшавӣ. Менеҷерон/админҳо ХУДАШОН сабти ном намекунанд —
/// суперадмин/админ ҳисоби навро дар "Танзимот" месозад ва рамзи муваққатӣ
/// медиҳад (нигаред ба AuthService.createManagerAccount поён).
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AppUser? currentUser;
  bool loading = true;

  AuthService() {
    _auth.authStateChanges().listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      currentUser = null;
      loading = false;
      notifyListeners();
      return;
    }
    final doc = await _db.collection('users').doc(firebaseUser.uid).get();
    if (doc.exists) {
      currentUser = AppUser.fromMap(firebaseUser.uid, doc.data()!);
    }
    loading = false;
    notifyListeners();
  }

  /// Воридшавӣ бо почтаи "виртуалӣ" сохташуда аз рақами телефон
  /// (Firebase Auth ба таври стандартӣ бо email/password кор мекунад,
  /// пас рақами телефонро ба формати email мубаддал мекунем:
  /// +992xxxxxxxxx -> 992xxxxxxxxx@realestate-app.local).
  Future<String?> login(String phone, String password) async {
    try {
      final email = _phoneToEmail(phone);
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // муваффақ
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Хатои воридшавӣ';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Танҳо суперадмин/админ метавонад ин функсияро истифода барад
  /// (санҷиш дар UI бо currentUser.canManageManagers ва боз ҳам
  /// дар Firestore Security Rules такрор мешавад).
  Future<String?> createManagerAccount({
    required String fullName,
    required String phone,
    required String tempPassword,
    required String companyId,
    UserRole role = UserRole.manager,
  }) async {
    FirebaseApp? secondaryApp;
    try {
      final email = _phoneToEmail(phone);

      // МУҲИМ: createUserWithEmailAndPassword ба таври худкор сессияи
      // ҷориро ба корбари НАВ иваз мекунад. Барои пешгирии ин (то
      // сессияи суперадмин/админи шумо халалдор нашавад), корбари
      // навро дар як нишасти АЛОҲИДАИ муваққатии Firebase месозем.
      secondaryApp = await Firebase.initializeApp(
        name: 'secondary_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: tempPassword,
      );

      final newUser = AppUser(
        uid: credential.user!.uid,
        fullName: fullName,
        phone: phone,
        role: role,
        companyId: companyId,
      );
      await _db.collection('users').doc(newUser.uid).set(newUser.toMap());

      await secondaryAuth.signOut();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Хатои сохтани ҳисоб';
    } catch (e) {
      // Ҳама хатогиҳои дигар (масалан permission-denied аз Firestore)
      // низ гирифта мешаванд, то интерфейс абадӣ нашавад.
      return e.toString();
    } finally {
      if (secondaryApp != null) await secondaryApp.delete();
    }
  }

  String _phoneToEmail(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return '$digits@realestate-app.local';
  }
}
