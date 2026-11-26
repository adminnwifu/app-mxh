import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String notificationId;
  final String recipientId;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String type; // 'like' or 'comment'
  final String postId;
  final String text;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.notificationId,
    required this.recipientId,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.type,
    required this.postId,
    required this.text,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'recipientId': recipientId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'type': type,
      'postId': postId,
      'text': text,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, String documentId) {
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

      return NotificationModel(
        notificationId: documentId,
        recipientId: map['recipientId']?.toString() ?? '',
        senderId: map['senderId']?.toString() ?? '',
        senderName: map['senderName']?.toString() ?? '',
        senderAvatar: map['senderAvatar']?.toString() ?? '',
        type: map['type']?.toString() ?? 'like',
        postId: map['postId']?.toString() ?? '',
        text: map['text']?.toString() ?? '',
        isRead: map['isRead'] == true,
        createdAt: date,
      );
    } catch (e) {
      return NotificationModel(
        notificationId: documentId,
        recipientId: map['recipientId']?.toString() ?? '',
        senderId: map['senderId']?.toString() ?? '',
        senderName: map['senderName']?.toString() ?? '',
        senderAvatar: map['senderAvatar']?.toString() ?? '',
        type: 'like',
        postId: '',
        text: '',
        isRead: false,
        createdAt: DateTime.now(),
      );
    }
  }
}
