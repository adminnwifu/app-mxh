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
    final coverCtrl = TextEditingController(text: user.coverUrl);

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
          child: SingleChildScrollView(
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
                const SizedBox(height: 14),
                TextField(
                  controller: coverCtrl,
                  decoration: const InputDecoration(
                    labelText: 'URL Ảnh bìa (Cover)',
                    prefixIcon: Icon(Icons.wallpaper_rounded),
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
                      coverUrl: coverCtrl.text.trim(),
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
          ),
        );
      },
    );
  }

  void _showAvatarOptionsSheet(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tùy chọn Ảnh đại diện',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.photo_camera_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: const Text(
                  'Chỉnh sửa ảnh đại diện',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Cập nhật URL ảnh hoặc chọn ảnh đại diện mới'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditAvatarDialog(context, user);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.visibility_rounded,
                    color: Colors.blue,
                  ),
                ),
                title: const Text(
                  'Xem ảnh đại diện',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Xem ảnh đại diện ở chế độ phóng to'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showViewAvatarDialog(context, user);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.manage_accounts_rounded,
                    color: Colors.orange,
                  ),
                ),
                title: const Text(
                  'Chỉnh sửa hồ sơ cá nhân',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Đổi tên hiển thị, tiểu sử bio'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditProfileDialog(context, user);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showEditAvatarDialog(BuildContext context, UserModel user) {
    final avatarCtrl = TextEditingController(text: user.avatarUrl);
    final presetAvatars = [
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400',
      'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentUrl = avatarCtrl.text.trim();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Chỉnh sửa ảnh đại diện',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),

                    // LIVE AVATAR PREVIEW
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 54,
                          backgroundImage: currentUrl.isNotEmpty
                              ? NetworkImage(currentUrl)
                              : null,
                          child: currentUrl.isEmpty
                              ? const Icon(Icons.person, size: 54)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // URL INPUT FIELD
                    TextField(
                      controller: avatarCtrl,
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Đường dẫn (URL) ảnh đại diện mới',
                        hintText: 'https://example.com/avatar.jpg',
                        prefixIcon: const Icon(Icons.link_rounded),
                        suffixIcon: avatarCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  avatarCtrl.clear();
                                  setModalState(() {});
                                },
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // PRESET AVATARS SELECTION
                    const Text(
                      'Hoặc chọn ảnh đại diện gợi ý:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 60,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: presetAvatars.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final url = presetAvatars[index];
                          final isSelected = avatarCtrl.text == url;

                          return GestureDetector(
                            onTap: () {
                              avatarCtrl.text = url;
                              setModalState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 24,
                                backgroundImage: NetworkImage(url),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SAVE BUTTON
                    FilledButton.icon(
                      onPressed: () async {
                        await UserFriendService().updateProfile(
                          uid: user.uid,
                          displayName: user.displayName,
                          bio: user.bio,
                          avatarUrl: avatarCtrl.text.trim(),
                        );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('🎉 Cập nhật ảnh đại diện thành công!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('Lưu ảnh đại diện'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditCoverDialog(BuildContext context, UserModel user) {
    final coverCtrl = TextEditingController(text: user.coverUrl);
    final presetCovers = [
      'https://images.unsplash.com/photo-1579546929518-9e396f3cc809?w=800',
      'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800',
      'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=800',
      'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800',
      'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800',
      '',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentCover = coverCtrl.text.trim();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Chỉnh sửa ảnh bìa',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),

                    // LIVE COVER PREVIEW
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              const Color(0xFF818CF8),
                            ],
                          ),
                        ),
                        child: currentCover.isNotEmpty
                            ? Image.network(
                                currentCover,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Center(
                                  child: Icon(Icons.broken_image,
                                      color: Colors.white),
                                ),
                              )
                            : const Center(
                                child: Text(
                                  'Chưa có ảnh bìa',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // URL INPUT FIELD
                    TextField(
                      controller: coverCtrl,
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Đường dẫn (URL) ảnh bìa mới',
                        hintText: 'https://example.com/cover.jpg',
                        prefixIcon: const Icon(Icons.wallpaper_rounded),
                        suffixIcon: coverCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  coverCtrl.clear();
                                  setModalState(() {});
                                },
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // PRESET COVERS
                    const Text(
                      'Hoặc chọn ảnh bìa gợi ý:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 70,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: presetCovers.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final url = presetCovers[index];
                          final isSelected = coverCtrl.text == url;

                          return GestureDetector(
                            onTap: () {
                              coverCtrl.text = url;
                              setModalState(() {});
                            },
                            child: Container(
                              width: 110,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SAVE BUTTON
                    FilledButton.icon(
                      onPressed: () async {
                        await UserFriendService().updateProfile(
                          uid: user.uid,
                          displayName: user.displayName,
                          bio: user.bio,
                          avatarUrl: user.avatarUrl,
                          coverUrl: coverCtrl.text.trim(),
                        );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('🎉 Cập nhật ảnh bìa thành công!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('Lưu ảnh bìa'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showViewAvatarDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                user.displayName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: user.avatarUrl.isNotEmpty
                    ? Image.network(
                        user.avatarUrl,
                        width: 260,
                        height: 260,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.person, size: 100),
                      )
                    : Container(
                        width: 200,
                        height: 200,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.person,
                            size: 100, color: Colors.grey),
                      ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đóng'),
              ),
            ],
          ),
        ),
      ),
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
                        Stack(
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
                              top: 12,
                              right: 12,
                              child: GestureDetector(
                                onTap: () => _showEditCoverDialog(context, user),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.55),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.6),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.camera_alt_outlined,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Sửa ảnh bìa',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          bottom: -42,
                          child: Stack(
                            children: [
                              GestureDetector(
                                onTap: () => _showAvatarOptionsSheet(context, user),
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
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: GestureDetector(
                                  onTap: () => _showAvatarOptionsSheet(context, user),
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
