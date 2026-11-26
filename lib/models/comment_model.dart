import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String commentId;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String text;
  final String? imageUrl;
  final List<String> likes;
  final Map<String, String> reactions; // userId -> reactionType ('like', 'love', 'care', 'haha', 'wow', 'sad', 'angry')
  final String? replyToId;
  final String? replyToName;
  final DateTime createdAt;

  CommentModel({
    required this.commentId,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.text,
    this.imageUrl,
    required this.likes,
    this.reactions = const {},
    this.replyToId,
    this.replyToName,
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

  bool isLikedBy(String uid) => reactions.containsKey(uid) || likes.contains(uid);

  int get totalReactions => reactions.isNotEmpty ? reactions.length : likes.length;

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'text': text,
      'imageUrl': imageUrl,
      'likes': likes,
      'reactions': reactions,
      'replyToId': replyToId,
      'replyToName': replyToName,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory CommentModel.fromMap(Map<String, dynamic> map, String documentId) {
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

      return CommentModel(
        commentId: documentId,
        authorId: map['authorId']?.toString() ?? '',
        authorName: map['authorName']?.toString() ?? 'Người dùng',
        authorAvatar: map['authorAvatar']?.toString() ?? '',
        text: map['text']?.toString() ?? '',
        imageUrl: map['imageUrl']?.toString(),
        likes: likesList,
        reactions: reactionsMap,
        replyToId: map['replyToId']?.toString(),
        replyToName: map['replyToName']?.toString(),
        createdAt: date,
      );
    } catch (e) {
      return CommentModel(
        commentId: documentId,
        authorId: map['authorId']?.toString() ?? '',
        authorName: map['authorName']?.toString() ?? 'Người dùng',
        authorAvatar: map['authorAvatar']?.toString() ?? '',
        text: map['text']?.toString() ?? '',
        likes: [],
        reactions: {},
        createdAt: DateTime.now(),
      );
    }
  }
}
