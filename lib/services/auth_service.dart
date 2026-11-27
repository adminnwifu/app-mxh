import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = credential.user;

      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists || doc.data() == null) {
          final newUser = UserModel(
            uid: user.uid,
            email: user.email ?? email,
            displayName: (user.displayName != null && user.displayName!.isNotEmpty)
                ? user.displayName!
                : email.split('@').first,
            bio: 'Xin chào, tôi mới tham gia MiniSocial!',
            avatarUrl: '',
            friendIds: const [],
          );
          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(newUser.toMap(), SetOptions(merge: true));
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-email') {
        throw Exception('Email hoặc mật khẩu không chính xác. Vui lòng kiểm tra lại!');
      } else if (e.code == 'user-disabled') {
        throw Exception('Tài khoản này đã bị vô hiệu hóa.');
      } else if (e.code == 'too-many-requests') {
        throw Exception('Bạn đã thử đăng nhập sai quá nhiều lần. Vui lòng thử lại sau ít phút.');
      } else {
        throw Exception(e.message ?? 'Email hoặc mật khẩu không chính xác. Vui lòng kiểm tra lại!');
      }
    } catch (e) {
      throw Exception('Email hoặc mật khẩu không chính xác. Vui lòng kiểm tra lại!');
    }
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    // KIỂM TRA NGHIÊM NGẶT: Mỗi Gmail chỉ dùng được 1 tài khoản duy nhất trên hệ thống
    final existingUserQuery = await _firestore
        .collection('users')
        .where('email', isEqualTo: cleanEmail)
        .get();

    if (existingUserQuery.docs.isNotEmpty) {
      throw Exception('Mỗi Gmail chỉ dùng được 1 tài khoản! Email "$cleanEmail" đã được đăng ký.');
    }

    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      User? user = credential.user;
      if (user != null) {
        try {
          await user.updateDisplayName(displayName);
        } catch (_) {}

        UserModel newUser = UserModel(
          uid: user.uid,
          email: cleanEmail,
          displayName: displayName,
          bio: 'Xin chào, tôi mới tham gia MiniSocial!',
          avatarUrl: '',
          friendIds: const [],
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(newUser.toMap(), SetOptions(merge: true));
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('Mỗi Gmail chỉ dùng được 1 tài khoản! Email "$cleanEmail" đã tồn tại trên hệ thống.');
      } else if (e.code == 'invalid-email') {
        throw Exception('Địa chỉ email không hợp lệ. Vui lòng kiểm tra lại!');
      } else if (e.code == 'weak-password') {
        throw Exception('Mật khẩu quá yếu. Vui lòng nhập mật khẩu từ 6 ký tự trở lên!');
      } else {
        throw Exception(e.message ?? 'Đăng ký không thành công. Vui lòng kiểm tra lại thông tin!');
      }
    } catch (e) {
      if (e.toString().contains('Mỗi Gmail chỉ dùng')) rethrow;
      throw Exception('Đăng ký không thành công: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
