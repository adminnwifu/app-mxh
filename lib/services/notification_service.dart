import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot>? _realtimeSubscription;
  bool _isInitialized = false;

  /// Khởi tạo hệ thống Thông báo Local và xin quyền tức thì trên Android 13+ (API 33+)
  Future<void> initializeLocalNotifications() async {
    if (_isInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(initSettings);

    final androidImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // Xin quyền hiển thị thông báo tức thì
    await androidImplementation?.requestNotificationsPermission();

    const androidChannel = AndroidNotificationChannel(
      'minisocial_channel_v3',
      'MiniSocial Realtime Notifications',
      description: 'Kênh nhận thông báo lượt thích, bình luận và bạn bè thời gian thực',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await androidImplementation?.createNotificationChannel(androidChannel);

    _isInitialized = true;
  }

  /// Hiển thị thông báo ngay lập tức trên thanh trạng thái điện thoại (0ms Latency)
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await initializeLocalNotifications();

    const androidDetails = AndroidNotificationDetails(
      'minisocial_channel_v3',
      'MiniSocial Realtime Notifications',
      channelDescription: 'Kênh nhận thông báo lượt thích, bình luận và bạn bè thời gian thực',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      id,
      title,
      body,
      notificationDetails,
    );
  }

  /// Bắn thông báo thử nghiệm trực tiếp xuống thiết bị điện thoại
  Future<void> sendTestNotification() async {
    await showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '🔔 Thông báo thử nghiệm MiniSocial',
      body: 'Hệ thống thông báo đẩy thời gian thực đang hoạt động hoàn hảo!',
    );
  }

  /// Tạo bản ghi thông báo trên Firestore và BẮN THÔNG BÁO ĐẨY TỨC THỜI VỀ ĐIỆN THOẠI
  Future<void> sendNotification({
    required String recipientId,
    required UserModel sender,
    required String type, // 'like', 'comment', 'friend_request', 'friend_accept'
    required String postId,
    required String text,
  }) async {
    final notification = NotificationModel(
      notificationId: '',
      recipientId: recipientId,
      senderId: sender.uid,
      senderName: sender.displayName,
      senderAvatar: sender.avatarUrl,
      type: type,
      postId: postId,
      text: text,
      isRead: false,
      createdAt: DateTime.now(),
    );

    // 1. Lưu bản ghi vào Firestore
    await _firestore.collection('notifications').add(notification.toMap());

    // 2. Phát thông báo đẩy tức thời lên thanh trạng thái điện thoại
    String title = type == 'like'
        ? '❤️ Lượt thích mới'
        : type == 'comment'
            ? '💬 Bình luận mới'
            : type == 'friend_request'
                ? '👥 Lời mời kết bạn'
                : '🔔 Thông báo mới';

    String body = type == 'like'
        ? '${sender.displayName} đã thích bài viết của bạn!'
        : type == 'comment'
            ? '${sender.displayName} đã bình luận: "$text"'
            : type == 'friend_request'
                ? '${sender.displayName} đã gửi lời mời kết bạn!'
                : text;

    await showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
    );
  }

  /// Lắng nghe Firestore theo thời gian thực để phát thông báo đẩy bất cứ khi nào có bản ghi mới
  void listenToRealtimeNotifications(String currentUserId) {
    _realtimeSubscription?.cancel();

    _realtimeSubscription = _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null) {
            final senderName = data['senderName'] ?? 'Một người dùng';
            final type = data['type'] ?? 'like';
            final text = data['text'] ?? '';

            String title = 'MiniSocial';
            String body = '';

            if (type == 'like') {
              title = '❤️ Lượt thích mới';
              body = '$senderName đã thích bài viết của bạn!';
            } else if (type == 'comment') {
              title = '💬 Bình luận mới';
              body = '$senderName đã bình luận: "$text"';
            } else if (type == 'friend_request') {
              title = '👥 Lời mời kết bạn';
              body = '$senderName đã gửi lời mời kết bạn!';
            } else {
              title = '🔔 Thông báo mới';
              body = text;
            }

            showLocalNotification(
              id: change.doc.id.hashCode,
              title: title,
              body: body,
            );
          }
        }
      }
    });
  }

  /// Lấy Stream danh sách thông báo của người dùng
  Stream<List<NotificationModel>> getNotificationsStream(String recipientId) {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: recipientId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return NotificationModel.fromMap(doc.data(), doc.id);
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }).asBroadcastStream();
  }

  /// Lấy Stream số lượng thông báo chưa đọc
  Stream<int> getUnreadCountStream(String recipientId) {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: recipientId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .asBroadcastStream();
  }

  /// Đánh dấu tất cả thông báo đã đọc
  Future<void> markAllAsRead(String recipientId) async {
    final query = await _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: recipientId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in query.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  void stopListening() {
    _realtimeSubscription?.cancel();
  }
}
