import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/user_friend_service.dart';
import '../chat/call_screen.dart';
import '../friends/friends_screen.dart';
import '../profile/user_profile_detail_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ChatService _chatService = ChatService();
  final UserFriendService _userService = UserFriendService();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToCallScreen(BuildContext context, {
    required UserModel currentUser,
    required UserModel friendUser,
    required bool isVideoCall,
  }) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => CallScreen(
          caller: currentUser,
          receiver: friendUser,
          isVideoCall: isVideoCall,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = AuthService().currentUser?.uid;
    if (currentUid == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<UserModel?>(
      stream: _userService.getUserProfileStream(currentUid),
      builder: (context, userSnap) {
        final fbUser = AuthService().currentUser;
        final currentUser = userSnap.data ?? UserModel(
          uid: currentUid,
          email: fbUser?.email ?? '',
          displayName: fbUser?.displayName ?? (fbUser?.email?.split('@').first ?? 'Người dùng'),
          avatarUrl: fbUser?.photoURL ?? '',
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Danh bạ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: Column(
            children: [
              // THANH TÌM KIẾM TRONG DANH BẠ
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm bạn bè trong danh bạ...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                  ),
                ),
              ),

              Expanded(
                child: StreamBuilder<List<UserModel>>(
                  stream: _userService.getFriendsListStream(currentUser.friendIds),
                  builder: (context, friendSnap) {
                    if (friendSnap.connectionState == ConnectionState.waiting &&
                        !friendSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final friends = friendSnap.data ?? [];
                    if (friends.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.contacts_outlined,
                                size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'Danh bạ chưa có người liên hệ nào.\nHãy kết nối thêm bạn bè mới!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // LẮNG NGHE BẢN ĐỒ THỜI GIAN TIN NHẮN ĐỂ ĐẨY NGƯỜI NHẮN TIN MỚI NẤT LÊN ĐẦU
                    return StreamBuilder<Map<String, DateTime>>(
                      stream: _chatService.getLastMessageTimestampsStream(currentUid),
                      builder: (context, timeSnap) {
                        final lastMessageMap = timeSnap.data ?? {};

                        // LỌC THEO TỪ KHÓA TÌM KIẾM
                        final query = _searchController.text.trim().toLowerCase();
                        final filteredFriends = friends.where((f) {
                          if (query.isEmpty) return true;
                          return f.displayName.toLowerCase().contains(query) ||
                              f.email.toLowerCase().contains(query);
                        }).toList();

                        // SẮP XẾP ƯU TIÊN: NGƯỜI CÓ TIN NHẮN MỚI NẤT ĐƯỢC ĐẨY LÊN ĐẦU
                        filteredFriends.sort((a, b) {
                          final timeA = lastMessageMap[a.uid];
                          final timeB = lastMessageMap[b.uid];

                          if (timeA != null && timeB != null) {
                            return timeB.compareTo(timeA); // Mới nhất xếp trước
                          } else if (timeA != null) {
                            return -1;
                          } else if (timeB != null) {
                            return 1;
                          } else {
                            return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
                          }
                        });

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: filteredFriends.length,
                          itemBuilder: (context, index) {
                            final friend = filteredFriends[index];
                            final hasRecentChat = lastMessageMap.containsKey(friend.uid);

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              child: ListTile(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => UserProfileDetailScreen(
                                        targetUser: friend,
                                        currentUser: currentUser,
                                      ),
                                    ),
                                  );
                                },
                                leading: Stack(
                                  children: [
                                    buildUserAvatar(
                                      avatarUrl: friend.avatarUrl,
                                      radius: 22,
                                      isDark: isDark,
                                    ),
                                    if (hasRecentChat)
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primary,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Theme.of(context).cardColor,
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                title: Text(
                                  friend.displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Text(
                                  friend.email,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // 📞 NÚT GỌI THOẠI STICKER
                                    InkWell(
                                      onTap: () {
                                        _navigateToCallScreen(
                                          context,
                                          currentUser: currentUser,
                                          friendUser: friend,
                                          isVideoCall: false,
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade900
                                              .withValues(alpha: isDark ? 0.4 : 0.15),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.greenAccent
                                                .withValues(alpha: 0.6),
                                            width: 1.2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.call_rounded,
                                          size: 18,
                                          color: Colors.greenAccent,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // 📹 NÚT GỌI VIDEO STICKER
                                    InkWell(
                                      onTap: () {
                                        _navigateToCallScreen(
                                          context,
                                          currentUser: currentUser,
                                          friendUser: friend,
                                          isVideoCall: true,
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade900
                                              .withValues(alpha: isDark ? 0.4 : 0.15),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.blueAccent
                                                .withValues(alpha: 0.6),
                                            width: 1.2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.videocam_rounded,
                                          size: 18,
                                          color: Colors.blueAccent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
