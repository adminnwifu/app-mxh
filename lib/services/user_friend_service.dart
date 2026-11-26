import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/friend_request_model.dart';
import '../models/user_model.dart';

class UserFriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<UserModel?> getUserProfileStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) {
        return UserModel(
          uid: uid,
          email: '',
          displayName: 'Người dùng',
          avatarUrl: '',
        );
      }
      return UserModel.fromMap(doc.data()!, doc.id);
    }).asBroadcastStream();
  }

  Stream<List<UserModel>> getFriendsListStream(List<String> friendIds) {
    if (friendIds.isEmpty) {
      return Stream.value(<UserModel>[]).asBroadcastStream();
    }

    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) {
      final allUsers = snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data(), doc.id);
      }).toList();
      return allUsers.where((u) => friendIds.contains(u.uid)).toList();
    }).asBroadcastStream();
  }

  Stream<List<FriendRequestModel>> getIncomingRequestsStream(String uid) {
    return _firestore
        .collection('friend_requests')
        .where('receiverId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return FriendRequestModel.fromMap(doc.data(), doc.id);
      }).toList();
    }).asBroadcastStream();
  }

  Future<List<UserModel>> searchUsers(String currentUid, String query) async {
    if (query.trim().isEmpty) return [];

    final querySnapshot = await _firestore.collection('users').get();
    final allUsers = querySnapshot.docs.map((doc) {
      return UserModel.fromMap(doc.data(), doc.id);
    }).toList();

    final lowerQuery = query.toLowerCase();
    return allUsers.where((user) {
      if (user.uid == currentUid) return false;
      bool matchName = user.displayName.toLowerCase().contains(lowerQuery);
      bool matchEmail = user.email.toLowerCase().contains(lowerQuery);
      return matchName || matchEmail;
    }).toList();
  }

  Future<void> sendFriendRequest({
    required UserModel sender,
    required String receiverId,
  }) async {
    final existing = await _firestore
        .collection('friend_requests')
        .where('senderId', isEqualTo: sender.uid)
        .where('receiverId', isEqualTo: receiverId)
        .get();

    if (existing.docs.isNotEmpty) return;

    final request = FriendRequestModel(
      requestId: '',
      senderId: sender.uid,
      senderName: sender.displayName,
      senderAvatar: sender.avatarUrl,
      receiverId: receiverId,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('friend_requests').add(request.toMap());
  }

  Stream<bool> hasSentFriendRequestStream({
    required String senderId,
    required String receiverId,
  }) {
    return _firestore
        .collection('friend_requests')
        .where('senderId', isEqualTo: senderId)
        .where('receiverId', isEqualTo: receiverId)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty)
        .asBroadcastStream();
  }

  Future<void> cancelFriendRequest({
    required String senderId,
    required String receiverId,
  }) async {
    final query = await _firestore
        .collection('friend_requests')
        .where('senderId', isEqualTo: senderId)
        .where('receiverId', isEqualTo: receiverId)
        .get();

    for (var doc in query.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> acceptFriendRequest(FriendRequestModel request) async {
    final userRef = _firestore.collection('users').doc(request.receiverId);
    final senderRef = _firestore.collection('users').doc(request.senderId);

    await _firestore.runTransaction((transaction) async {
      transaction.update(userRef, {
        'friendIds': FieldValue.arrayUnion([request.senderId]),
      });
      transaction.update(senderRef, {
        'friendIds': FieldValue.arrayUnion([request.receiverId]),
      });
    });

    await _firestore.collection('friend_requests').doc(request.requestId).delete();
  }

  Future<void> rejectFriendRequest(String requestId) async {
    await _firestore.collection('friend_requests').doc(requestId).delete();
  }

  /// Hủy kết bạn giữa 2 người dùng
  Future<void> unfriend({
    required String currentUserId,
    required String targetUserId,
  }) async {
    final currentUserRef = _firestore.collection('users').doc(currentUserId);
    final targetUserRef = _firestore.collection('users').doc(targetUserId);

    await _firestore.runTransaction((transaction) async {
      transaction.update(currentUserRef, {
        'friendIds': FieldValue.arrayRemove([targetUserId]),
      });
      transaction.update(targetUserRef, {
        'friendIds': FieldValue.arrayRemove([currentUserId]),
      });
    });
  }

  Future<void> updateProfile({
    required String uid,
    required String displayName,
    required String bio,
    required String avatarUrl,
    String? coverUrl,
  }) async {
    final Map<String, dynamic> data = {
      'displayName': displayName,
      'bio': bio,
      'avatarUrl': avatarUrl,
    };
    if (coverUrl != null) {
      data['coverUrl'] = coverUrl;
    }
    await _firestore.collection('users').doc(uid).update(data);
  }
}
