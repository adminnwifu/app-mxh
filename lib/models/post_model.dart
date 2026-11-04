import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String postId;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String content;
  final String visibility; // 'public' or 'friends'
  final List<String> likes;
  final Map<String, String> reactions; // userId -> reactionType ('like', 'love', 'care', 'haha', 'wow', 'sad', 'angry')
  final int commentCount;
  final DateTime createdAt;

  PostModel({
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.content,
    required this.visibility,
    required this.likes,
    this.reactions = const {},
    required this.commentCount,
    required this.createdAt,
  });

  String? getReactionOf(String userId) {
    if (reactions.containsKey(userId)) {
      return reactions[userId];
    }
    if (likes.contains(userId)) {
      return 'like';
    }
    return null;
  }

  bool isLikedBy(String userId) {
    return reactions.containsKey(userId) || likes.contains(userId);
  }

  int get totalReactions => reactions.isNotEmpty ? reactions.length : likes.length;

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'content': content,
      'visibility': visibility,
      'likes': likes,
      'reactions': reactions,
      'commentCount': commentCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory PostModel.fromMap(Map<String, dynamic> map, String documentId) {
    var timestamp = map['createdAt'];
    DateTime date = DateTime.now();
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    }

    Map<String, String> reactionsMap = {};
    if (map['reactions'] != null && map['reactions'] is Map) {
      (map['reactions'] as Map).forEach((key, value) {
        reactionsMap[key.toString()] = value.toString();
      });
    }

    return PostModel(
      postId: documentId,
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      authorAvatar: map['authorAvatar'] ?? '',
      content: map['content'] ?? '',
      visibility: map['visibility'] ?? 'public',
      likes: List<String>.from(map['likes'] ?? []),
      reactions: reactionsMap,
      commentCount: map['commentCount'] ?? 0,
      createdAt: date,
    );
  }
}
