import 'package:cloud_firestore/cloud_firestore.dart';

class FriendRequestModel {
  final String requestId;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String receiverId;
  final DateTime createdAt;

  FriendRequestModel({
    required this.requestId,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.receiverId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'receiverId': receiverId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory FriendRequestModel.fromMap(Map<String, dynamic> map, String documentId) {
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

      return FriendRequestModel(
        requestId: documentId,
        senderId: map['senderId']?.toString() ?? '',
        senderName: map['senderName']?.toString() ?? '',
        senderAvatar: map['senderAvatar']?.toString() ?? '',
        receiverId: map['receiverId']?.toString() ?? '',
        createdAt: date,
      );
    } catch (e) {
      return FriendRequestModel(
        requestId: documentId,
        senderId: map['senderId']?.toString() ?? '',
        senderName: map['senderName']?.toString() ?? '',
        senderAvatar: map['senderAvatar']?.toString() ?? '',
        receiverId: map['receiverId']?.toString() ?? '',
        createdAt: DateTime.now(),
      );
    }
  }
}
