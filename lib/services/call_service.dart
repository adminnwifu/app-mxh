import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

enum CallStatus { ringing, accepted, rejected, ended }

class CallModel {
  final String callId;
  final String callerId;
  final String callerName;
  final String callerAvatar;
  final String receiverId;
  final String receiverName;
  final String receiverAvatar;
  final bool isVideoCall;
  final String status; // 'ringing', 'accepted', 'rejected', 'ended'
  final DateTime createdAt;

  CallModel({
    required this.callId,
    required this.callerId,
    required this.callerName,
    required this.callerAvatar,
    required this.receiverId,
    required this.receiverName,
    required this.receiverAvatar,
    required this.isVideoCall,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'callId': callId,
      'callerId': callerId,
      'callerName': callerName,
      'callerAvatar': callerAvatar,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverAvatar': receiverAvatar,
      'isVideoCall': isVideoCall,
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory CallModel.fromMap(Map<String, dynamic> map, String documentId) {
    return CallModel(
      callId: documentId,
      callerId: map['callerId'] ?? '',
      callerName: map['callerName'] ?? '',
      callerAvatar: map['callerAvatar'] ?? '',
      receiverId: map['receiverId'] ?? '',
      receiverName: map['receiverName'] ?? '',
      receiverAvatar: map['receiverAvatar'] ?? '',
      isVideoCall: map['isVideoCall'] ?? false,
      status: map['status'] ?? 'ringing',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }

  UserModel toCallerUserModel() {
    return UserModel(
      uid: callerId,
      email: '',
      displayName: callerName,
      avatarUrl: callerAvatar,
    );
  }

  UserModel toReceiverUserModel() {
    return UserModel(
      uid: receiverId,
      email: '',
      displayName: receiverName,
      avatarUrl: receiverAvatar,
    );
  }
}

class CallService {
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Tạo cuộc gọi mới trên Firestore
  Future<String> startCall({
    required UserModel caller,
    required UserModel receiver,
    required bool isVideoCall,
  }) async {
    final docRef = _firestore.collection('calls').doc();
    final call = CallModel(
      callId: docRef.id,
      callerId: caller.uid,
      callerName: caller.displayName,
      callerAvatar: caller.avatarUrl,
      receiverId: receiver.uid,
      receiverName: receiver.displayName,
      receiverAvatar: receiver.avatarUrl,
      isVideoCall: isVideoCall,
      status: 'ringing',
      createdAt: DateTime.now(),
    );

    await docRef.set(call.toMap());
    return docRef.id;
  }

  /// Người nhận chấp nhận cuộc gọi
  Future<void> acceptCall(String callId) async {
    await _firestore.collection('calls').doc(callId).update({
      'status': 'accepted',
    });
  }

  /// Người nhận từ chối cuộc gọi
  Future<void> rejectCall(String callId) async {
    await _firestore.collection('calls').doc(callId).update({
      'status': 'rejected',
    });
  }

  /// Kết thúc cuộc gọi
  Future<void> endCall(String callId) async {
    if (callId.isEmpty) return;
    await _firestore.collection('calls').doc(callId).update({
      'status': 'ended',
    });
  }

  /// Lắng nghe trạng thái của 1 cuộc gọi cụ thể
  Stream<CallModel?> getCallStream(String callId) {
    return _firestore.collection('calls').doc(callId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return CallModel.fromMap(snapshot.data()!, snapshot.id);
    });
  }

  /// Lắng nghe cuộc gọi đến cho người dùng hiện tại
  Stream<List<CallModel>> listenToIncomingCalls(String currentUserId) {
    return _firestore
        .collection('calls')
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'ringing')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CallModel.fromMap(doc.data(), doc.id)).toList();
    });
  }
}
