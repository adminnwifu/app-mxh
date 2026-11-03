import 'package:cloud_firestore/cloud_firestore.dart';

class StoryModel {
  final String storyId;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String type; // 'image' hoặc 'text'
  final String? mediaUrl;
  final String content;
  final String? postContent;
  final String? postAuthorName;
  final DateTime createdAt;

  StoryModel({
    required this.storyId,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    this.type = 'text',
    this.mediaUrl,
    required this.content,
    this.postContent,
    this.postAuthorName,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'type': type,
      'mediaUrl': mediaUrl,
      'content': content,
      'postContent': postContent,
      'postAuthorName': postAuthorName,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory StoryModel.fromMap(Map<String, dynamic> map, String documentId) {
    var timestamp = map['createdAt'];
    DateTime date = DateTime.now();
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    }
    return StoryModel(
      storyId: documentId,
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      authorAvatar: map['authorAvatar'] ?? '',
      type: map['type'] ?? 'text',
      mediaUrl: map['mediaUrl'],
      content: map['content'] ?? '',
      postContent: map['postContent'],
      postAuthorName: map['postAuthorName'],
      createdAt: date,
    );
  }
}
