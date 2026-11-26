import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _getChatRoomId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    final chatRoomId = _getChatRoomId(senderId, receiverId);
    final message = MessageModel(
      messageId: '',
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      createdAt: DateTime.now(),
    );

    final chatRoomRef = _firestore.collection('chat_rooms').doc(chatRoomId);

    // Lưu tin nhắn mới vào subcollection messages
    await chatRoomRef.collection('messages').add(message.toMap());

    // Cập nhật thông tin cuộc trò chuyện gần đây lên parent doc (Giúp xếp hạng đẩy người nhắn tin mới lên đầu)
    await chatRoomRef.set({
      'chatRoomId': chatRoomId,
      'participants': [senderId, receiverId],
      'lastMessageText': text,
      'lastMessageSenderId': senderId,
      'lastMessageAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  Stream<List<MessageModel>> getMessagesStream(String userId1, String userId2) {
    final chatRoomId = _getChatRoomId(userId1, userId2);
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MessageModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Lắng nghe bản đồ thời gian tin nhắn mới nhất giữa người dùng hiện tại và các bạn bè
  Stream<Map<String, DateTime>> getLastMessageTimestampsStream(String currentUserId) {
    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
      Map<String, DateTime> map = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final List<dynamic> participants = data['participants'] ?? [];
        final otherId = participants.firstWhere(
          (id) => id.toString() != currentUserId,
          orElse: () => '',
        ).toString();

        if (otherId.isNotEmpty) {
          final lastAt = data['lastMessageAt'];
          if (lastAt is Timestamp) {
            map[otherId] = lastAt.toDate();
          }
        }
      }
      return map;
    }).asBroadcastStream();
  }
}
