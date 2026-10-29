import 'package:flutter/material.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../services/post_service.dart';
import '../../services/user_friend_service.dart';
import '../chat/chat_screen.dart';
import '../feed/feed_screen.dart';

class UserProfileDetailScreen extends StatelessWidget {
  final UserModel targetUser;
  final UserModel currentUser;

  const UserProfileDetailScreen({
    super.key,
    required this.targetUser,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    final userService = UserFriendService();
    final postService = PostService();

    return StreamBuilder<UserModel?>(
      stream: userService.getUserProfileStream(targetUser.uid),
      builder: (context, snapshot) {
        final user = snapshot.data ?? targetUser;
        final isSelf = user.uid == currentUser.uid;

        return StreamBuilder<UserModel?>(
          stream: userService.getUserProfileStream(currentUser.uid),
          builder: (context, currentSnapshot) {
            final freshCurrentUser = currentSnapshot.data ?? currentUser;
            final isFriend = freshCurrentUser.friendIds.contains(user.uid);

            return Scaffold(
              appBar: AppBar(
                title: Text(
                  user.displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              body: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        // COVER PHOTO & AVATAR HEADER
                        Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.bottomCenter,
                          children: [
                            Container(
                              height: 150,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    const Color(0xFF818CF8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: user.coverUrl.isNotEmpty
                                  ? Image.network(
                                      user.coverUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: 150,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const SizedBox.shrink(),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: -40,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  radius: 46,
                                  backgroundImage: user.avatarUrl.isNotEmpty
                                      ? NetworkImage(user.avatarUrl)
                                      : null,
                                  child: user.avatarUrl.isEmpty
                                      ? const Icon(Icons.person, size: 46)
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 48),

                        // USER NAME & EMAIL
                        Text(
                          user.displayName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                        const SizedBox(height: 12),

                        // BIO BOX
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              user.bio.isNotEmpty
                                  ? user.bio
                                  : 'Người dùng chưa cập nhật tiểu sử.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey.shade800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // STATS ROW (Friends count & Posts count)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatItem('Bạn bè', '${user.friendIds.length}'),
                                  Container(height: 24, width: 1, color: Colors.grey.shade300),
                                  StreamBuilder<List<PostModel>>(
                                    stream: postService.getUserPostsStream(user.uid),
                                    builder: (context, postSnap) {
                                      final count = postSnap.data?.length ?? 0;
                                      return _buildStatItem('Bài viết', '$count');
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ACTION BUTTONS (Nhắn tin / Kết bạn)
                        if (!isSelf) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ChatScreen(
                                            currentUser: freshCurrentUser,
                                            friendUser: user,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                                    label: const Text('Nhắn tin'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: isFriend
                                      ? OutlinedButton.icon(
                                          onPressed: null,
                                          icon: const Icon(Icons.check_rounded, size: 18),
                                          label: const Text('Đã là bạn bè'),
                                        )
                                      : OutlinedButton.icon(
                                          onPressed: () async {
                                            await userService.sendFriendRequest(
                                              sender: freshCurrentUser,
                                              receiverId: user.uid,
                                            );
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      'Đã gửi lời mời kết bạn tới ${user.displayName}'),
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
                                            }
                                          },
                                          icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                                          label: const Text('Kết bạn'),
                                        ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        const Divider(height: 24),

                        // SECTION TITLE
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Bài viết của ${user.displayName}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),

                  // POSTS LIST OF TARGET USER
                  StreamBuilder<List<PostModel>>(
                    stream: postService.getUserPostsStream(user.uid),
                    builder: (context, postSnap) {
                      final posts = postSnap.data ?? [];

                      // Lọc bài viết công khai hoặc bài viết nếu là bạn bè
                      final visiblePosts = posts.where((p) {
                        if (p.visibility == 'public') return true;
                        if (isSelf || isFriend) return true;
                        return false;
                      }).toList();

                      if (visiblePosts.isEmpty) {
                        return const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(
                              child: Text(
                                'Chưa có bài viết nào được chia sẻ.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.black54),
                              ),
                            ),
                          ),
                        );
                      }

                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => PostCardWidget(
                            post: visiblePosts[index],
                            currentUser: freshCurrentUser,
                          ),
                          childCount: visiblePosts.length,
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ],
    );
  }
}
