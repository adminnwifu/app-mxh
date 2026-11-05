import 'package:flutter/material.dart';
import '../../models/friend_request_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/user_friend_service.dart';
import '../chat/chat_screen.dart';
import '../profile/user_profile_detail_screen.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUid = AuthService().currentUser?.uid;
    if (currentUid == null) return const SizedBox.shrink();

    final userService = UserFriendService();

    return StreamBuilder<UserModel?>(
      stream: userService.getUserProfileStream(currentUid),
      builder: (context, userSnap) {
        final currentUser = userSnap.data;
        if (currentUser == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text(
                'Danh bạ & Bạn bè',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              bottom: TabBar(
                indicatorColor: Theme.of(context).colorScheme.primary,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Colors.grey.shade600,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: [
                  Tab(text: 'Bạn bè (${currentUser.friendIds.length})'),
                  const Tab(text: 'Lời mời'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                // TAB 1: DANH SÁCH BẠN BÈ (Sử dụng AutomaticKeepAliveClientMixin giữ trạng thái)
                _FriendsListTabWidget(currentUser: currentUser),

                // TAB 2: LỜI MỜI KẾT BẠN (Sử dụng AutomaticKeepAliveClientMixin giữ trạng thái)
                _IncomingRequestsTabWidget(currentUser: currentUser),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Tab Danh Sách Bạn Bè Giữ Trạng Thái Sinh Động Khi Chuyển Tab (Avoid Unmount / Reset)
class _FriendsListTabWidget extends StatefulWidget {
  final UserModel currentUser;

  const _FriendsListTabWidget({required this.currentUser});

  @override
  State<_FriendsListTabWidget> createState() => _FriendsListTabWidgetState();
}

class _FriendsListTabWidgetState extends State<_FriendsListTabWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final userService = UserFriendService();

    return StreamBuilder<List<UserModel>>(
      stream: userService.getFriendsListStream(widget.currentUser.friendIds),
      builder: (context, friendSnap) {
        if (friendSnap.connectionState == ConnectionState.waiting &&
            !friendSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final friends = friendSnap.data ?? [];
        if (friends.isEmpty) {
          return Builder(
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline_rounded,
                        size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'Bạn chưa có người bạn nào trong danh bạ.\nHãy tìm kiếm người dùng mới ở thanh tìm kiếm!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserProfileDetailScreen(
                        targetUser: friend,
                        currentUser: widget.currentUser,
                      ),
                    ),
                  );
                },
                leading: CircleAvatar(
                  radius: 22,
                  backgroundImage: friend.avatarUrl.isNotEmpty
                      ? NetworkImage(friend.avatarUrl)
                      : null,
                  child: friend.avatarUrl.isEmpty
                      ? const Icon(Icons.person)
                      : null,
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
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          currentUser: widget.currentUser,
                          friendUser: friend,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_rounded, size: 16),
                  label: const Text('Nhắn tin'),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Tab Lời Mời Kết Bạn Giữ Trạng Thái Sinh Động Khi Chuyển Tab
class _IncomingRequestsTabWidget extends StatefulWidget {
  final UserModel currentUser;

  const _IncomingRequestsTabWidget({required this.currentUser});

  @override
  State<_IncomingRequestsTabWidget> createState() =>
      _IncomingRequestsTabWidgetState();
}

class _IncomingRequestsTabWidgetState extends State<_IncomingRequestsTabWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final userService = UserFriendService();

    return StreamBuilder<List<FriendRequestModel>>(
      stream: userService.getIncomingRequestsStream(widget.currentUser.uid),
      builder: (context, reqSnap) {
        if (reqSnap.connectionState == ConnectionState.waiting &&
            !reqSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = reqSnap.data ?? [];
        if (requests.isEmpty) {
          return Builder(
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mark_email_read_outlined,
                        size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'Không có lời mời kết bạn mới.',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: req.senderAvatar.isNotEmpty
                          ? NetworkImage(req.senderAvatar)
                          : null,
                      child: req.senderAvatar.isEmpty
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            req.senderName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Đã gửi lời mời kết bạn',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        FilledButton(
                          onPressed: () => userService.acceptFriendRequest(req),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                          ),
                          child: const Text('Chấp nhận'),
                        ),
                        const SizedBox(width: 6),
                        OutlinedButton(
                          onPressed: () =>
                              userService.rejectFriendRequest(req.requestId),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          child: const Text('Từ chối'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
