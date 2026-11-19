import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/ai_search_service.dart';
import '../../services/user_friend_service.dart';
import '../chat/chat_screen.dart';
import '../feed/feed_screen.dart';
import '../profile/user_profile_detail_screen.dart';

class AiSearchScreen extends StatefulWidget {
  final UserModel currentUser;

  const AiSearchScreen({super.key, required this.currentUser});

  @override
  State<AiSearchScreen> createState() => _AiSearchScreenState();
}

class _AiSearchScreenState extends State<AiSearchScreen> {
  final _searchController = TextEditingController();
  final _aiSearchService = AiSearchService();
  final _userService = UserFriendService();

  AiSearchResult? _searchResult;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performAiSearch(String query) async {
    final text = query.trim();
    if (text.isEmpty) {
      setState(() => _searchResult = null);
      return;
    }

    setState(() => _isSearching = true);
    final result = await _aiSearchService.searchWithAi(
      query: text,
      currentUserId: widget.currentUser.uid,
      currentUserFriendIds: widget.currentUser.friendIds,
    );

    if (mounted) {
      setState(() {
        _searchResult = result;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Container(
          margin: const EdgeInsets.only(right: 16),
          height: 44,
          child: TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: (text) => _performAiSearch(text),
            onSubmitted: (text) => _performAiSearch(text),
            decoration: InputDecoration(
              hintText: 'Hỏi AI hoặc tìm bài viết, bạn bè...',
              hintStyle: const TextStyle(fontSize: 14),
              prefixIcon: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF6366F1)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchResult = null);
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          ),
        ),
      ),
      body: _isSearching
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('AI đang phân tích ngữ nghĩa & tìm kiếm...',
                      style: TextStyle(color: Colors.black54, fontSize: 13)),
                ],
              ),
            )
          : _searchResult == null
              ? _buildSuggestedPrompts(context)
              : _buildSearchResults(context, primaryColor),
    );
  }

  /// Khung hiển thị gợi ý từ khóa thông minh
  Widget _buildSuggestedPrompts(BuildContext context) {
    final prompts = [
      '🚀 Bài viết về Flutter & Công nghệ',
      '🔥 Bài viết nổi bật nhiều like',
      '⏰ Bài viết mới đăng hôm nay',
      '👥 Gợi ý bạn bè mới',
      '💬 Thảo luận sôi nổi',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome_rounded, color: Color(0xFF6366F1), size: 20),
              SizedBox(width: 8),
              Text(
                'AI Search - Tìm kiếm thông minh',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Nhập nội dung tìm kiếm tự nhiên, AI sẽ tự động phân tích và đưa ra kết quả chính xác nhất.',
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 20),
          const Text(
            'Gợi ý tìm kiếm nhanh:',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: prompts.map((prompt) {
              return ActionChip(
                avatar: const Icon(Icons.search_rounded, size: 16),
                label: Text(prompt, style: const TextStyle(fontSize: 13)),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                onPressed: () {
                  final cleanPrompt = prompt.replaceAll(RegExp(r'^[^\s]+\s*'), '');
                  _searchController.text = cleanPrompt;
                  _performAiSearch(cleanPrompt);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Khung hiển thị kết quả tìm kiếm phân loại
  Widget _buildSearchResults(BuildContext context, Color primaryColor) {
    final result = _searchResult!;

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          // AI SUMMARY INSIGHT BANNER
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFEEF2FF),
                  primaryColor.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome_rounded, color: Color(0xFF6366F1), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    result.aiSummary,
                    style: const TextStyle(fontSize: 13, height: 1.35, color: Color(0xFF1E293B)),
                  ),
                ),
              ],
            ),
          ),

          // TAB CATEGORIES
          TabBar(
            indicatorColor: primaryColor,
            labelColor: primaryColor,
            unselectedLabelColor: Colors.grey.shade600,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'Tất cả (${result.matchedPosts.length + result.matchedUsers.length})'),
              Tab(text: 'Bài viết (${result.matchedPosts.length})'),
              Tab(text: 'Người dùng (${result.matchedUsers.length})'),
            ],
          ),

          // TAB VIEWS
          Expanded(
            child: TabBarView(
              children: [
                // TAB 1: ALL
                ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    if (result.matchedUsers.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'NGƯỜI DÙNG PHÙ HỢP',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                        ),
                      ),
                      ...result.matchedUsers.take(3).map((u) => _buildUserCard(context, u)),
                      const Divider(height: 24),
                    ],
                    if (result.matchedPosts.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'BÀI VIẾT NỔI BẬT',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                        ),
                      ),
                      ...result.matchedPosts.map((p) => PostCardWidget(
                            post: p,
                            currentUser: widget.currentUser,
                          )),
                    ] else if (result.matchedUsers.isEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(
                          child: Text(
                            'Không tìm thấy nội dung phù hợp với từ khóa.',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // TAB 2: POSTS ONLY
                result.matchedPosts.isEmpty
                    ? const Center(child: Text('Không có bài viết phù hợp.'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: result.matchedPosts.length,
                        itemBuilder: (context, index) {
                          return PostCardWidget(
                            post: result.matchedPosts[index],
                            currentUser: widget.currentUser,
                          );
                        },
                      ),

                // TAB 3: USERS ONLY
                result.matchedUsers.isEmpty
                    ? const Center(child: Text('Không có người dùng phù hợp.'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: result.matchedUsers.length,
                        itemBuilder: (context, index) {
                          return _buildUserCard(context, result.matchedUsers[index]);
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, UserModel user) {
    final isAlreadyFriend = widget.currentUser.friendIds.contains(user.uid);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserProfileDetailScreen(
                targetUser: user,
                currentUser: widget.currentUser,
              ),
            ),
          );
        },
        leading: CircleAvatar(
          backgroundImage:
              user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
          child: user.avatarUrl.isEmpty ? const Icon(Icons.person) : null,
        ),
        title: Text(
          user.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(user.email, style: const TextStyle(fontSize: 12)),
        trailing: isAlreadyFriend
            ? FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        currentUser: widget.currentUser,
                        friendUser: user,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble_rounded, size: 16),
                label: const Text('Nhắn tin'),
              )
            : StreamBuilder<bool>(
                stream: _userService.hasSentFriendRequestStream(
                  senderId: widget.currentUser.uid,
                  receiverId: user.uid,
                ),
                builder: (context, reqSnap) {
                  final hasSent = reqSnap.data ?? false;

                  if (hasSent) {
                    return OutlinedButton.icon(
                      onPressed: () async {
                        await _userService.cancelFriendRequest(
                          senderId: widget.currentUser.uid,
                          receiverId: user.uid,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã hủy lời mời kết bạn'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.2),
                      ),
                      icon: const Icon(Icons.mark_email_read_rounded, size: 16),
                      label: const Text('Đã gửi lời mời'),
                    );
                  }

                  return OutlinedButton.icon(
                    onPressed: () async {
                      await _userService.sendFriendRequest(
                        sender: widget.currentUser,
                        receiverId: user.uid,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đã gửi lời mời kết bạn tới ${user.displayName}'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                    label: const Text('Kết bạn'),
                  );
                },
              ),
      ),
    );
  }
}
