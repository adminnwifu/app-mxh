import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String commentId;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String text;
  final List<String> likes;
  final String? replyToId;
  final String? replyToName;
  final DateTime createdAt;

  CommentModel({
    required this.commentId,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.text,
    required this.likes,
    this.replyToId,
    this.replyToName,
    required this.createdAt,
  });

  bool isLikedBy(String uid) => likes.contains(uid);

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'text': text,
      'likes': likes,
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
    return CommentModel(
      commentId: documentId,
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      authorAvatar: map['authorAvatar'] ?? '',
      text: map['text'] ?? '',
      likes: List<String>.from(map['likes'] ?? []),
      replyToId: map['replyToId'],
      replyToName: map['replyToName'],
      createdAt: date,
    );
  }
}
