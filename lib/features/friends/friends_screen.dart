import 'package:flutter/material.dart';
import '../../models/friend_request_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/user_friend_service.dart';
import '../chat/chat_screen.dart';
import '../profile/user_profile_detail_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _userService = UserFriendService();
  final _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String currentUid) async {
    if (_searchController.text.trim().isEmpty) return;
    setState(() => _isSearching = true);
    final results = await _userService.searchUsers(
      currentUid,
      _searchController.text.trim(),
    );
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = AuthService().currentUser?.uid;
    if (currentUid == null) return const SizedBox.shrink();

    return StreamBuilder<UserModel?>(
      stream: _userService.getUserProfileStream(currentUid),
      builder: (context, userSnap) {
        final currentUser = userSnap.data;
        if (currentUser == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return DefaultTabController(
          length: 3,
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
                  const Tab(text: 'Tìm bạn'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                // TAB 1: DANH SÁCH BẠN BÈ HIỆN TẠI
                StreamBuilder<List<UserModel>>(
                  stream: _userService.getFriendsListStream(currentUser.friendIds),
                  builder: (context, friendSnap) {
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
                                  'Bạn chưa có người bạn nào trong danh bạ.\nHãy sang tab "Tìm bạn" để kết nối thêm!',
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
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
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
                                      currentUser: currentUser,
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
                ),

                // TAB 2: LỜI MỜI KẾT BẠN
                StreamBuilder<List<FriendRequestModel>>(
                  stream: _userService.getIncomingRequestsStream(currentUser.uid),
                  builder: (context, reqSnap) {
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
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      onPressed: () =>
                                          _userService.acceptFriendRequest(req),
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
                                      onPressed: () => _userService
                                          .rejectFriendRequest(req.requestId),
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
                ),

                // TAB 3: TÌM KIẾM NGƯỜI DÙNG
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onSubmitted: (_) =>
                                  _performSearch(currentUser.uid),
                              decoration: InputDecoration(
                                hintText: 'Nhập tên hoặc email...',
                                prefixIcon: const Icon(Icons.search_rounded),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchResults = []);
                                        },
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () => _performSearch(currentUser.uid),
                            child: const Text('Tìm'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _isSearching
                          ? const Center(child: CircularProgressIndicator())
                          : _searchResults.isEmpty
                              ? Builder(
                                  builder: (context) {
                                    final isDark = Theme.of(context).brightness == Brightness.dark;
                                    return Center(
                                      child: Text(
                                        _searchController.text.isEmpty
                                            ? 'Nhập từ khóa để tìm kiếm người dùng mới.'
                                            : 'Không tìm thấy người dùng phù hợp.',
                                        style: TextStyle(
                                          color: isDark ? Colors.white70 : Colors.black54,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : ListView.builder(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  itemCount: _searchResults.length,
                                  itemBuilder: (context, index) {
                                    final user = _searchResults[index];
                                    final isAlreadyFriend = currentUser
                                        .friendIds
                                        .contains(user.uid);

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
                                                targetUser: user,
                                                currentUser: currentUser,
                                              ),
                                            ),
                                          );
                                        },
                                        leading: CircleAvatar(
                                          backgroundImage:
                                              user.avatarUrl.isNotEmpty
                                                  ? NetworkImage(user.avatarUrl)
                                                  : null,
                                          child: user.avatarUrl.isEmpty
                                              ? const Icon(Icons.person)
                                              : null,
                                        ),
                                        title: Text(
                                          user.displayName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Text(user.email),
                                        trailing: isAlreadyFriend
                                            ? const Chip(
                                                label: Text('Đã là bạn bè'),
                                                backgroundColor: Color(0xFFE2E8F0),
                                              )
                                            : OutlinedButton.icon(
                                                onPressed: () async {
                                                  await _userService
                                                      .sendFriendRequest(
                                                    sender: currentUser,
                                                    receiverId: user.uid,
                                                  );
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Đã gửi lời mời kết bạn tới ${user.displayName}',
                                                        ),
                                                        behavior: SnackBarBehavior.floating,
                                                      ),
                                                    );
                                                  }
                                                },
                                                icon: const Icon(
                                                  Icons.person_add_alt_1_rounded,
                                                  size: 16,
                                                ),
                                                label: const Text('Kết bạn'),
                                              ),
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
