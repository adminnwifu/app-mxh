import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';
import '../models/story_model.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class DataSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Đồng bộ hồ sơ người dùng hiện tại lên Firebase Firestore
  Future<void> syncCurrentUserProfile() async {
    final firebaseUser = AuthService().currentUser;
    if (firebaseUser == null) return;

    final userRef = _firestore.collection('users').doc(firebaseUser.uid);
    final userSnap = await userRef.get();

    if (!userSnap.exists) {
      final newUser = UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? 'user@minisocial.com',
        displayName: firebaseUser.displayName ??
            (firebaseUser.email?.split('@').first ?? 'Người dùng'),
        avatarUrl: firebaseUser.photoURL ?? '',
        bio: 'Xin chào, tôi mới tham gia MiniSocial!',
        friendIds: [],
      );
      await userRef.set(newUser.toMap());
    }
  }

  /// Đồng bộ khôi phục dữ liệu bài viết & câu chuyện mẫu lên Firebase Firestore nếu bộ sưu tập trống
  Future<int> syncDataFromFirebase() async {
    int syncedCount = 0;
    await syncCurrentUserProfile();

    final firebaseUser = AuthService().currentUser;
    final currentUid = firebaseUser?.uid ?? 'sample_uid_1';
    final currentName = firebaseUser?.displayName ??
        (firebaseUser?.email?.split('@').first ?? 'Network');

    // 1. Kiểm tra và kết nối tài khoản bạn bè (Không tạo ghi đè nếu tài khoản thật đã tồn tại)
    final sampleUsers = [
      UserModel(
        uid: 'an_uid_101',
        email: 'ciel21@gmail.com',
        displayName: 'an',
        avatarUrl: 'https://picsum.photos/200?random=1',
        bio: 'Yêu âm nhạc & du lịch',
        friendIds: [currentUid],
      ),
      UserModel(
        uid: 'tkin_uid_102',
        email: 'tkin@gmail.com',
        displayName: 'TKin',
        avatarUrl: 'https://picsum.photos/200?random=2',
        bio: 'Lập trình viên Flutter',
        friendIds: [currentUid],
      ),
    ];

    for (var u in sampleUsers) {
      final emailQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: u.email)
          .get();

      if (emailQuery.docs.isEmpty) {
        final docRef = _firestore.collection('users').doc(u.uid);
        final snap = await docRef.get();
        if (!snap.exists) {
          await docRef.set(u.toMap());
          syncedCount++;
        }
        if (currentUid.isNotEmpty) {
          await _firestore.collection('users').doc(currentUid).update({
            'friendIds': FieldValue.arrayUnion([u.uid]),
          }).catchError((_) {});
        }
      } else {
        // Đã có tài khoản thật với email ciel21@gmail.com (kèm Avatar ảnh thật): Kết nối UID tài khoản thật vào bạn bè!
        final realUserUid = emailQuery.docs.first.id;
        if (currentUid.isNotEmpty && realUserUid != currentUid) {
          await _firestore.collection('users').doc(currentUid).update({
            'friendIds': FieldValue.arrayUnion([realUserUid]),
          }).catchError((_) {});
        }
      }
    }

    // 2. Kiểm tra bộ sưu tập bài viết
    final postsSnap = await _firestore.collection('posts').get();
    if (postsSnap.docs.isEmpty) {
      final samplePosts = [
        PostModel(
          postId: '',
          authorId: 'an_uid_101',
          authorName: 'an',
          authorAvatar: 'https://picsum.photos/200?random=1',
          content: '🌟 Xin chào mọi người trên MiniSocial! Hôm nay là một ngày thật đẹp trời. Hãy kết nối và chia sẻ thêm nhiều điều hay nhé! 🚀',
          visibility: 'public',
          likes: ['an_uid_101', currentUid],
          reactions: {'an_uid_101': 'love', currentUid: 'like'},
          commentCount: 2,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        PostModel(
          postId: '',
          authorId: 'tkin_uid_102',
          authorName: 'TKin',
          authorAvatar: 'https://picsum.photos/200?random=2',
          content: '🚀 Đã hoàn thiện tính năng thả cảm xúc Facebook và bình luận đính kèm ảnh thời gian thực trên MiniSocial Flutter app! 🎉',
          visibility: 'public',
          likes: [currentUid],
          reactions: {currentUid: 'care'},
          commentCount: 1,
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        PostModel(
          postId: '',
          authorId: currentUid,
          authorName: currentName,
          authorAvatar: firebaseUser?.photoURL ?? '',
          content: 'Chào mừng bạn đến với trang cá nhân của tôi trên MiniSocial! Cùng nhau chia sẻ khoảnh khắc đẹp hàng ngày nhé. ✨',
          visibility: 'public',
          likes: ['an_uid_101'],
          reactions: {'an_uid_101': 'haha'},
          commentCount: 1,
          createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        ),
      ];

      for (var p in samplePosts) {
        final newPostRef = await _firestore.collection('posts').add(p.toMap());
        syncedCount++;

        // Thêm bình luận mẫu
        final sampleComment = CommentModel(
          commentId: '',
          authorId: 'an_uid_101',
          authorName: 'an',
          authorAvatar: 'https://picsum.photos/200?random=1',
          text: 'Ứng dụng chạy mượt mà và giao diện đẹp lắm bạn ơi! 👍',
          likes: [currentUid],
          reactions: {currentUid: 'like'},
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        );
        await newPostRef.collection('comments').add(sampleComment.toMap());
      }
    }

    // 3. Kiểm tra bộ sưu tập Story
    final storiesSnap = await _firestore.collection('stories').get();
    if (storiesSnap.docs.isEmpty) {
      final sampleStory = StoryModel(
        storyId: '',
        authorId: 'an_uid_101',
        authorName: 'an',
        authorAvatar: 'https://picsum.photos/200?random=1',
        type: 'image',
        mediaUrl: 'https://picsum.photos/800/1200?random=101',
        content: 'Chuyến đi dã ngoại cuối tuần thật tuyệt vời 🌄',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );
      await _firestore.collection('stories').add(sampleStory.toMap());
      syncedCount++;
    }

    return syncedCount;
  }
}
