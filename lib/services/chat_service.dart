import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import 'notification_service.dart';

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
      'lastMessageIsRead': false,
      'lastMessageAt': Timestamp.now(),
    }, SetOptions(merge: true));

    // Bắn thông báo đẩy tin nhắn đến cho người nhận
    try {
      final senderSnap = await _firestore.collection('users').doc(senderId).get();
      final senderName = senderSnap.data()?['displayName'] ?? 'Một người bạn';
      final senderAvatar = senderSnap.data()?['avatarUrl'] ?? '';

      await NotificationService().sendNotification(
        recipientId: receiverId,
        sender: UserModel(
          uid: senderId,
          email: '',
          displayName: senderName,
          avatarUrl: senderAvatar,
        ),
        type: 'message',
        postId: '',
        text: text,
      );
    } catch (_) {}
  }

  /// Đánh dấu tất cả tin nhắn trong đoạn chat đã đọc khi người dùng mở ChatScreen
  Future<void> markMessagesAsRead(String currentUserId, String friendId) async {
    final chatRoomId = _getChatRoomId(currentUserId, friendId);
    final chatRoomRef = _firestore.collection('chat_rooms').doc(chatRoomId);

    await chatRoomRef.set({'lastMessageIsRead': true}, SetOptions(merge: true));

    final unreadQuery = await chatRoomRef
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in unreadQuery.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Lắng nghe dữ liệu tin nhắn mới nhất giữa người dùng hiện tại và bạn bè
  Stream<Map<String, dynamic>?> getLastMessageStream(String currentUserId, String friendId) {
    final chatRoomId = _getChatRoomId(currentUserId, friendId);
    return _firestore.collection('chat_rooms').doc(chatRoomId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return doc.data();
    }).asBroadcastStream();
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
