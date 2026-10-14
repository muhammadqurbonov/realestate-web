import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';

/// Идоракунии воридшавӣ. Бо email-и ВОҚЕӢ (Gmail) кор мекунад — то
/// Firebase тавонад дар ҳолати фаромӯшшавии рамз, паёми барқарорсозиро
/// воқеан ба email-и корбар фиристад.
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AppUser? currentUser;
  bool loading = true;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;

  /// Забони матнҳои хато (аз main.dart ҳангоми иваз шудани забон навсозӣ мешавад).
  static bool useRussian = false;
  static String tr(String tj, String ru) => useRussian ? ru : tj;

  AuthService() {
    _auth.authStateChanges().listen(_onAuthChanged);
  }

  /// Ҳуҷҷати корбарро зинда мешунавем: вақте админ менеҷерро тасдиқ мекунад
  /// ё нақшро иваз мекунад, дар барнома фавран намоён мешавад.
  void _onAuthChanged(User? firebaseUser) {
    _userSub?.cancel();
    _userSub = null;
    if (firebaseUser == null) {
      currentUser = null;
      loading = false;
      notifyListeners();
      return;
    }
    _userSub = _db.collection('users').doc(firebaseUser.uid).snapshots().listen((doc) {
      currentUser = doc.exists ? AppUser.fromMap(firebaseUser.uid, doc.data()!) : null;
      loading = false;
      notifyListeners();
    }, onError: (Object e) {
      debugPrint('User doc stream error: $e');
      loading = false;
      notifyListeners();
    });
  }

  Future<String?> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      final doc = await _db.collection('users').doc(cred.user!.uid).get();
      if (!doc.exists) {
        // Ҳуҷҷат нест — масалан, админ дархостро рад кардааст.
        await _auth.signOut();
        return tr(
          'Ҳисоби шумо дар система нест ё рад карда шудааст. Бо админ тамос гиред.',
          'Вашего аккаунта нет в системе или заявка отклонена. Свяжитесь с админом.',
        );
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e);
    }
  }

  /// Email-и ҳисоби Firebase Auth (на нусхаи Firestore) — линки барқарорсозӣ
  /// маҳз ба ҳамин суроға меравад.
  String? get authEmail => _auth.currentUser?.email;

  /// Хатои Firebase-ро бо матни фаҳмо ва рамзи хато бармегардонад.
  String _authError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return tr('Email нодуруст навишта шудааст', 'Email указан неверно');
      case 'user-not-found':
        return tr('Корбар бо ин email ёфт нашуд', 'Пользователь с таким email не найден');
      case 'email-already-in-use':
        return tr('Ин email аллакай сабт шудааст', 'Этот email уже зарегистрирован');
      case 'too-many-requests':
        return tr('Дархостҳо аз ҳад зиёданд. Якчанд дақиқа интизор шавед ва боз кӯшиш кунед',
            'Слишком много запросов. Подождите несколько минут и повторите');
      case 'network-request-failed':
        return tr('Пайвастшавӣ ба интернет нест', 'Нет подключения к интернету');
      case 'wrong-password':
      case 'invalid-credential':
        return tr('Email ё рамз нодуруст аст', 'Неверный email или пароль');
      case 'weak-password':
        return tr('Рамз хеле суст аст (камаш 6 аломат)', 'Слишком слабый пароль (минимум 6 символов)');
      case 'requires-recent-login':
        return tr('Барои амният аз ҳисоб баромада, дубора ворид шавед',
            'В целях безопасности выйдите и войдите снова');
      default:
        return '${e.message ?? tr('Хатои номаълум', 'Неизвестная ошибка')} (${e.code})';
    }
  }

  Future<String?> sendPasswordResetEmail(String email) async {
    final address = email.trim();
    if (address.isEmpty) return tr('Email-ро нависед', 'Введите email');
    try {
      await _auth.sendPasswordResetEmail(email: address);
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('sendPasswordResetEmail failed: ${e.code} ${e.message}');
      return _authError(e);
    } catch (e) {
      debugPrint('sendPasswordResetEmail failed: $e');
      return '${tr('Хатои фиристодани паём', 'Ошибка отправки письма')}: $e';
    }
  }

  /// Иваз кардани рамз бе email: аввал рамзи ҷорӣ тасдиқ мешавад.
  Future<String?> changePassword(String currentPassword, String newPassword) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) return tr('Корбар ворид нашудааст', 'Пользователь не вошёл в систему');
    try {
      final cred = EmailAuthProvider.credential(email: email, password: currentPassword);
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e);
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Худсабтномкунии менеҷер.
  Future<String?> registerManager({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required String companyId,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      final newUser = AppUser(
        uid: credential.user!.uid,
        fullName: fullName,
        phone: phone,
        email: email.trim(),
        role: UserRole.manager,
        companyId: companyId,
        approved: false, // то тасдиқи админ хона/муштарӣ илова карда наметавонад
        createdAt: DateTime.now(),
      );
      await _db.collection('users').doc(newUser.uid).set(newUser.toMap());
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e);
    } catch (e) {
      return e.toString();
    }
  }

  /// Танҳо суперадмин/админ — сохтани ҳисоби менеҷер/админ аз "Танзимот".
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
      // МУҲИМ: createUserWithEmailAndPassword сессияи ҷориро ба
      // корбари НАВ иваз мекунад — бинобар ин дар нишасти алоҳидаи
      // муваққатӣ месозем, то сессияи админ халалдор нашавад.
      secondaryApp = await Firebase.initializeApp(
        name: 'secondary_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final credential = await secondaryAuth.createUserWithEmailAndPassword(email: email.trim(), password: tempPassword);

      final newUser = AppUser(
        uid: credential.user!.uid,
        fullName: fullName,
        phone: phone,
        email: email.trim(),
        role: role,
        companyId: companyId,
        approved: true, // ҳисоби админсохта — дарҳол фаъол
        createdAt: DateTime.now(),
      );
      await _db.collection('users').doc(newUser.uid).set(newUser.toMap());

      await secondaryAuth.signOut();
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e);
    } catch (e) {
      return e.toString();
    } finally {
      if (secondaryApp != null) await secondaryApp.delete();
    }
  }

  Future<void> updateUserRole(String uid, UserRole role) =>
      _db.collection('users').doc(uid).update({'role': roleToString(role)});

  /// Админ дархости менеҷерро қабул мекунад.
  Future<void> approveUser(String uid) => _db.collection('users').doc(uid).update({'approved': true});

  /// Админ дархостро рад мекунад (ҳуҷҷат нест мешавад).
  Future<void> rejectUser(String uid) => _db.collection('users').doc(uid).delete();
}
