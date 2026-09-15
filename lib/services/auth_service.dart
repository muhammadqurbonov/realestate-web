import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';

/// Идоракунии воридшавӣ. Акнун бо email-и ВОҚЕӢ (Gmail) кор мекунад —
/// то Firebase тавонад дар ҳолати фаромӯшшавии рамз, паёми
/// барқарорсозиро воқеан ба email-и корбар фиристад.
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

  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      return null; // муваффақ
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Хатои воридшавӣ';
    }
  }

  /// Паёми барқарорсозии рамзро ба email-и воқеии корбар мефиристад.
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Хатои фиристодани паём';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Худсабтномкунии менеҷер — ҳар кас метавонад бо рамзи ширкат
  /// (companyId), ном, рақами телефон, email, ва рамз худаш сабти ном
  /// кунад. Нақши ибтидоӣ ҳамеша "manager" аст — суперадмин баъдан
  /// метавонад ба админ табдил диҳад.
  Future<String?> registerManager({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required String companyId,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final newUser = AppUser(
        uid: credential.user!.uid,
        fullName: fullName,
        phone: phone,
        email: email.trim(),
        role: UserRole.manager,
        companyId: companyId,
      );
      await _db.collection('users').doc(newUser.uid).set(newUser.toMap());
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Хатои сабти ном';
    } catch (e) {
      return e.toString();
    }
  }

  /// Танҳо суперадмин/админ метавонад ин функсияро истифода барад —
  /// сохтани ҳисоби менеҷер/админ аз дохили "Танзимот".
  Future<String?> createManagerAccount({
    required String fullName,
    required String phone,
    required String email,
    required String tempPassword,
    required String companyId,
    UserRole role = UserRole.manager,
  }) async {
    FirebaseApp? secondaryApp;
    try {
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
        email: email.trim(),
        password: tempPassword,
      );

      final newUser = AppUser(
        uid: credential.user!.uid,
        fullName: fullName,
        phone: phone,
        email: email.trim(),
        role: role,
        companyId: companyId,
      );
      await _db.collection('users').doc(newUser.uid).set(newUser.toMap());

      await secondaryAuth.signOut();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Хатои сохтани ҳисоб';
    } catch (e) {
      return e.toString();
    } finally {
      if (secondaryApp != null) await secondaryApp.delete();
    }
  }

  /// Тағйири нақши корбар (масалан манеҷер → админ). Танҳо суперадмин.
  Future<void> updateUserRole(String uid, UserRole role) =>
      _db.collection('users').doc(uid).update({'role': roleToString(role)});
}
