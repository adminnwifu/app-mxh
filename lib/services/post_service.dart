import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import 'notification_service.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createPost({
    required UserModel author,
    required String content,
    required String visibility,
  }) async {
    final post = PostModel(
      postId: '',
      authorId: author.uid,
      authorName: author.displayName,
      authorAvatar: author.avatarUrl,
      content: content,
      visibility: visibility,
      likes: [],
      commentCount: 0,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('posts').add(post.toMap());
  }

  Stream<List<PostModel>> getHomeFeedStream({
    required String currentUserId,
    required List<String> currentUserFriendIds,
  }) {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final allPosts = snapshot.docs.map((doc) {
        return PostModel.fromMap(doc.data(), doc.id);
      }).toList();

      return allPosts.where((post) {
        if (post.authorId == currentUserId) return true;
        if (post.visibility == 'private') return false;
        if (post.visibility == 'public') return true;
        if (post.visibility == 'friends') {
          return currentUserFriendIds.contains(post.authorId);
        }
        return false;
      }).toList();
    }).asBroadcastStream();
  }

  Stream<List<PostModel>> getUserPostsStream(
    String userId, {
    String? viewerId,
    List<String>? viewerFriendIds,
  }) {
    return _firestore
        .collection('posts')
        .where('authorId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final posts = snapshot.docs.map((doc) {
        return PostModel.fromMap(doc.data(), doc.id);
      }).toList();
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (viewerId != null && viewerId != userId) {
        final isFriend = viewerFriendIds?.contains(userId) ?? false;
        return posts.where((p) {
          if (p.visibility == 'private') return false;
          if (p.visibility == 'public') return true;
          if (p.visibility == 'friends') return isFriend;
          return false;
        }).toList();
      }

      return posts;
    }).asBroadcastStream();
  }

  Future<void> toggleLike({
    required String postId,
    required String postAuthorId,
    required UserModel currentUser,
    required bool isCurrentlyLiked,
  }) async {
    if (isCurrentlyLiked) {
      await setReaction(
        postId: postId,
        postAuthorId: postAuthorId,
        currentUser: currentUser,
        reactionType: null,
      );
    } else {
      await setReaction(
        postId: postId,
        postAuthorId: postAuthorId,
        currentUser: currentUser,
        reactionType: 'like',
      );
    }
  }

  Future<void> setReaction({
    required String postId,
    required String postAuthorId,
    required UserModel currentUser,
    required String? reactionType,
  }) async {
    final postRef = _firestore.collection('posts').doc(postId);

    if (reactionType == null) {
      await postRef.update({
        'reactions.${currentUser.uid}': FieldValue.delete(),
        'likes': FieldValue.arrayRemove([currentUser.uid]),
      });
    } else {
      await postRef.update({
        'reactions.${currentUser.uid}': reactionType,
        'likes': FieldValue.arrayUnion([currentUser.uid]),
      });

      final String emojiText = reactionType == 'love'
          ? '❤️ Yêu thích'
          : reactionType == 'care'
              ? '🥰 Thương thương'
              : reactionType == 'haha'
                  ? '😆 Haha'
                  : reactionType == 'wow'
                      ? '😲 Wow'
                      : reactionType == 'sad'
                          ? '😢 Buồn'
                          : reactionType == 'angry'
                              ? '😡 Phẫn nộ'
                              : '👍 Thích';

      await NotificationService().sendNotification(
        recipientId: postAuthorId,
        sender: currentUser,
        type: 'like',
        postId: postId,
        text: 'đã bày tỏ cảm xúc $emojiText cho bài viết của bạn',
      );
    }
  }

  Stream<List<CommentModel>> getCommentsStream(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CommentModel.fromMap(doc.data(), doc.id);
      }).toList();
    }).asBroadcastStream();
  }

  /// Bật/tắt thả tim cho từng bình luận
  Future<void> toggleCommentLike({
    required String postId,
    required String commentId,
    required UserModel currentUser,
    required bool isCurrentlyLiked,
  }) async {
    if (isCurrentlyLiked) {
      await setCommentReaction(
        postId: postId,
        commentId: commentId,
        currentUser: currentUser,
        reactionType: null,
      );
    } else {
      await setCommentReaction(
        postId: postId,
        commentId: commentId,
        currentUser: currentUser,
        reactionType: 'like',
      );
    }
  }

  /// Bày tỏ cảm xúc cho bình luận (like, love, care, haha, wow, sad, angry)
  Future<void> setCommentReaction({
    required String postId,
    required String commentId,
    required UserModel currentUser,
    required String? reactionType,
  }) async {
    final commentRef = _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId);

    if (reactionType == null) {
      await commentRef.update({
        'reactions.${currentUser.uid}': FieldValue.delete(),
        'likes': FieldValue.arrayRemove([currentUser.uid]),
      });
    } else {
      await commentRef.update({
        'reactions.${currentUser.uid}': reactionType,
        'likes': FieldValue.arrayUnion([currentUser.uid]),
      });
    }
  }

  /// Thêm bình luận mới (hỗ trợ kèm ảnh & trả lời từng bình luận cụ thể)
  Future<void> addComment({
    required String postId,
    required String postAuthorId,
    required UserModel author,
    required String text,
    String? imageUrl,
    String? replyToId,
    String? replyToName,
  }) async {
    final comment = CommentModel(
      commentId: '',
      authorId: author.uid,
      authorName: author.displayName,
      authorAvatar: author.avatarUrl,
      text: text,
      imageUrl: imageUrl,
      likes: [],
      replyToId: replyToId,
      replyToName: replyToName,
      createdAt: DateTime.now(),
    );

    final postRef = _firestore.collection('posts').doc(postId);

    await _firestore.runTransaction((transaction) async {
      final postSnap = await transaction.get(postRef);
      if (!postSnap.exists) return;

      int currentCount = postSnap.data()?['commentCount'] ?? 0;
      transaction.update(postRef, {'commentCount': currentCount + 1});

      final newCommentRef = postRef.collection('comments').doc();
      transaction.set(newCommentRef, comment.toMap());
    });

    final notifText = replyToName != null
        ? 'đã trả lời bình luận của $replyToName: "$text"'
        : text.isNotEmpty
            ? text
            : 'đã gửi một hình ảnh trong bình luận';

    await NotificationService().sendNotification(
      recipientId: postAuthorId,
      sender: author,
      type: 'comment',
      postId: postId,
      text: notifText,
    );
  }

  /// Xóa bình luận
  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    final postRef = _firestore.collection('posts').doc(postId);
    final commentRef = postRef.collection('comments').doc(commentId);

    await _firestore.runTransaction((transaction) async {
      final postSnap = await transaction.get(postRef);
      if (postSnap.exists) {
        int currentCount = postSnap.data()?['commentCount'] ?? 1;
        int newCount = (currentCount - 1).clamp(0, 999999);
        transaction.update(postRef, {'commentCount': newCount});
      }
      transaction.delete(commentRef);
    });
  }

  /// Chỉnh sửa nội dung bình luận
  Future<void> editComment({
    required String postId,
    required String commentId,
    required String newText,
  }) async {
    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .update({
      'text': newText,
    });
  }
}
