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
    try {
      var timestamp = map['createdAt'];
      DateTime date = DateTime.now();
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is int) {
        date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else if (timestamp is String) {
        date = DateTime.tryParse(timestamp) ?? DateTime.now();
      }

      Map<String, String> reactionsMap = {};
      if (map['reactions'] is Map) {
        (map['reactions'] as Map).forEach((key, value) {
          reactionsMap[key.toString()] = value.toString();
        });
      }

      List<String> likesList = [];
      if (map['likes'] is List) {
        likesList = (map['likes'] as List).map((e) => e.toString()).toList();
      }

      return PostModel(
        postId: documentId,
        authorId: map['authorId']?.toString() ?? '',
        authorName: map['authorName']?.toString() ?? 'Người dùng',
        authorAvatar: map['authorAvatar']?.toString() ?? '',
        content: map['content']?.toString() ?? '',
        visibility: map['visibility']?.toString() ?? 'public',
        likes: likesList,
        reactions: reactionsMap,
        commentCount: (map['commentCount'] is int)
            ? map['commentCount']
            : (int.tryParse(map['commentCount']?.toString() ?? '0') ?? 0),
        createdAt: date,
      );
    } catch (e) {
      return PostModel(
        postId: documentId,
        authorId: map['authorId']?.toString() ?? '',
        authorName: map['authorName']?.toString() ?? 'Người dùng',
        authorAvatar: map['authorAvatar']?.toString() ?? '',
        content: map['content']?.toString() ?? '',
        visibility: 'public',
        likes: [],
        reactions: {},
        commentCount: 0,
        createdAt: DateTime.now(),
      );
    }
  }
}
