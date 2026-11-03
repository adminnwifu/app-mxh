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
    final postRef = _firestore.collection('posts').doc(postId);
    if (isCurrentlyLiked) {
      await postRef.update({
        'likes': FieldValue.arrayRemove([currentUser.uid]),
      });
    } else {
      await postRef.update({
        'likes': FieldValue.arrayUnion([currentUser.uid]),
      });

      await NotificationService().sendNotification(
        recipientId: postAuthorId,
        sender: currentUser,
        type: 'like',
        postId: postId,
        text: 'đã thích bài viết của bạn',
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
    required String currentUid,
    required bool isCurrentlyLiked,
  }) async {
    final commentRef = _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId);

    if (isCurrentlyLiked) {
      await commentRef.update({
        'likes': FieldValue.arrayRemove([currentUid]),
      });
    } else {
      await commentRef.update({
        'likes': FieldValue.arrayUnion([currentUid]),
      });
    }
  }

  /// Thêm bình luận mới (hỗ trợ trả lời từng bình luận cụ thể)
  Future<void> addComment({
    required String postId,
    required String postAuthorId,
    required UserModel author,
    required String text,
    String? replyToId,
    String? replyToName,
  }) async {
    final comment = CommentModel(
      commentId: '',
      authorId: author.uid,
      authorName: author.displayName,
      authorAvatar: author.avatarUrl,
      text: text,
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
        : text;

    await NotificationService().sendNotification(
      recipientId: postAuthorId,
      sender: author,
      type: 'comment',
      postId: postId,
      text: notifText,
    );
  }
}
