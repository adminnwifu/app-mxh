import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/story_model.dart';
import '../models/user_model.dart';

class StoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Tạo Story/Ghi chú mới (Hỗ trợ dạng Ảnh/Video hoặc dạng Văn bản)
  Future<void> createStory({
    required UserModel author,
    required String content,
    String type = 'text', // 'image' hoặc 'text'
    String? mediaUrl,
    String? postContent,
    String? postAuthorName,
  }) async {
    final story = StoryModel(
      storyId: '',
      authorId: author.uid,
      authorName: author.displayName,
      authorAvatar: author.avatarUrl,
      type: type,
      mediaUrl: mediaUrl,
      content: content,
      postContent: postContent,
      postAuthorName: postAuthorName,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('stories').add(story.toMap());
  }

  /// Xóa Story khỏi Firestore
  Future<void> deleteStory(String storyId) async {
    if (storyId.isEmpty) return;
    await _firestore.collection('stories').doc(storyId).delete();
  }

  /// Lấy danh sách Tin (Stories) thời gian thực của bản thân và bạn bè RÀNG BUỘC HIỂN THỊ TRONG 24 GIỜ
  Stream<List<StoryModel>> getActiveStoriesStream({
    required String currentUserId,
    required List<String> currentUserFriendIds,
  }) {
    final allowedUids = [currentUserId, ...currentUserFriendIds];

    return _firestore
        .collection('stories')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      final stories = snapshot.docs.map((doc) {
        return StoryModel.fromMap(doc.data(), doc.id);
      }).toList();

      // RÀNG BUỘC 24 GIỜ
      return stories.where((s) {
        final isAllowedUser = allowedUids.contains(s.authorId);
        final ageInSeconds = now.difference(s.createdAt).inSeconds;
        return isAllowedUser && ageInSeconds >= 0 && ageInSeconds < 86400;
      }).toList();
    }).asBroadcastStream();
  }
}
