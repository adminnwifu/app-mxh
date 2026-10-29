import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/friend_request_model.dart';
import '../models/user_model.dart';

class UserFriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<UserModel?> getUserProfileStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!, doc.id);
    });
  }

  Stream<List<UserModel>> getFriendsListStream(List<String> friendIds) {
    if (friendIds.isEmpty) return Stream.value([]);

    // Firestore whereIn supports up to 10 items. Chunk if needed or query all users
    return _firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: friendIds.take(10).toList())
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
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
    });
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
    // Kiểm tra xem đã tồn tại request chưa
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
