import 'package:flutter/material.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/post_service.dart';
import '../../services/user_friend_service.dart';
import '../feed/feed_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _showEditProfileDialog(BuildContext context, UserModel user) {
    final nameCtrl = TextEditingController(text: user.displayName);
    final bioCtrl = TextEditingController(text: user.bio);
    final avatarCtrl = TextEditingController(text: user.avatarUrl);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Chỉnh sửa hồ sơ cá nhân',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tên hiển thị',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: bioCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Tự giới thiệu (Bio)',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: avatarCtrl,
                decoration: const InputDecoration(
                  labelText: 'URL Ảnh đại diện (Avatar)',
                  prefixIcon: Icon(Icons.link_rounded),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  await UserFriendService().updateProfile(
                    uid: user.uid,
                    displayName: nameCtrl.text.trim(),
                    bio: bioCtrl.text.trim(),
                    avatarUrl: avatarCtrl.text.trim(),
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã cập nhật thông tin trang cá nhân!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: const Text('Lưu thay đổi'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Cài đặt & Quyền riêng tư',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.notifications_active_outlined),
                title: const Text('Thông báo ứng dụng'),
                subtitle: const Text('Đang bật nhận thông báo like/comment'),
                trailing: const Icon(Icons.check_circle, color: Colors.green),
              ),
              ListTile(
                leading: const Icon(Icons.security_outlined),
                title: const Text('Bảo mật tài khoản'),
                subtitle: const Text('Xác thực qua Firebase Auth'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: const Text('Phiên bản ứng dụng'),
                subtitle: const Text('MiniSocial v1.0.0'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng MiniSocial?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              AuthService().signOut();
            },
            child: const Text('Đăng xuất ngay'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = AuthService().currentUser?.uid;
    if (currentUid == null) return const SizedBox.shrink();

    final userService = UserFriendService();
    final postService = PostService();

    return StreamBuilder<UserModel?>(
      stream: userService.getUserProfileStream(currentUid),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Trang cá nhân',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                tooltip: 'Cài đặt',
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => _showSettingsSheet(context),
              ),
              IconButton(
                tooltip: 'Đăng xuất',
                onPressed: () => _confirmSignOut(context),
                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              ),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // COVER PHOTO BANNER & AVATAR HEADER
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.bottomCenter,
                      children: [
                        Container(
                          height: 140,
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
                        ),
                        Positioned(
                          bottom: -42,
                          child: Stack(
                            children: [
                              Container(
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
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: GestureDetector(
                                  onTap: () => _showEditProfileDialog(context, user),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 50),

                    // USER NAME, EMAIL & JOINED TAG
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

                    // BIO CARD
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                              : 'Chưa có tiểu sử. Nhấn chỉnh sửa để cập nhật!',
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

                    // STATS ROW (Friends count, Posts count, Total Likes received)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: StreamBuilder<List<PostModel>>(
                            stream: postService.getUserPostsStream(user.uid),
                            builder: (context, postSnap) {
                              final posts = postSnap.data ?? [];
                              final totalLikes = posts.fold<int>(
                                  0, (sum, p) => sum + p.likes.length);

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatItem('Bài viết', '${posts.length}'),
                                  Container(
                                      height: 24,
                                      width: 1,
                                      color: Colors.grey.shade300),
                                  _buildStatItem(
                                      'Bạn bè', '${user.friendIds.length}'),
                                  Container(
                                      height: 24,
                                      width: 1,
                                      color: Colors.grey.shade300),
                                  _buildStatItem('Lượt thích', '$totalLikes'),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ACTION BUTTONS ROW
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showEditProfileDialog(context, user),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Chỉnh sửa hồ sơ'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            onPressed: () => _showSettingsSheet(context),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.settings_outlined, size: 18),
                            label: const Text('Cài đặt'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 32),

                    // SECTION HEADER
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Bài viết của tôi',
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

              // USER POSTS STREAM
              StreamBuilder<List<PostModel>>(
                stream: postService.getUserPostsStream(user.uid),
                builder: (context, postSnap) {
                  final myPosts = postSnap.data ?? [];
                  if (myPosts.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(
                          child: Text(
                            'Bạn chưa đăng bài viết nào.\nHãy chia sẻ suy nghĩ của bạn trên Trang chủ!',
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
                        post: myPosts[index],
                        currentUser: user,
                      ),
                      childCount: myPosts.length,
                    ),
                  );
                },
              ),
            ],
          ),
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
