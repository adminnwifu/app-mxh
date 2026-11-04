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

    return CommentModel(
      commentId: documentId,
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      authorAvatar: map['authorAvatar'] ?? '',
      text: map['text'] ?? '',
      imageUrl: map['imageUrl'],
      likes: List<String>.from(map['likes'] ?? []),
      reactions: reactionsMap,
      replyToId: map['replyToId'],
      replyToName: map['replyToName'],
      createdAt: date,
    );
  }
}
