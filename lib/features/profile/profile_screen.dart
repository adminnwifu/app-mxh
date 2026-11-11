import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../main.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/post_service.dart';
import '../../services/user_friend_service.dart';
import '../feed/feed_screen.dart';

/// Helper lấy ImageProvider thông minh từ URL mạng hoặc Tệp bộ nhớ điện thoại
ImageProvider? getSmartImageProvider(String? pathOrUrl) {
  if (pathOrUrl == null || pathOrUrl.isEmpty) return null;
  if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
    return NetworkImage(pathOrUrl);
  }
  final file = File(pathOrUrl);
  if (file.existsSync()) {
    return FileImage(file);
  }
  return NetworkImage(pathOrUrl);
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _showEditProfileDialog(BuildContext context, UserModel user) {
    final nameCtrl = TextEditingController(text: user.displayName);
    final bioCtrl = TextEditingController(text: user.bio);

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
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    await UserFriendService().updateProfile(
                      uid: user.uid,
                      displayName: nameCtrl.text.trim(),
                      bio: bioCtrl.text.trim(),
                      avatarUrl: user.avatarUrl,
                      coverUrl: user.coverUrl,
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
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
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
                subtitle: const Text('Chọn ảnh từ thư viện máy hoặc chụp ảnh mới'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditAvatarDialog(context, user);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
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
                    color: Colors.orange.withValues(alpha: 0.1),
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
    XFile? pickedAvatarFile;

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
            Future<void> pickImage(ImageSource source) async {
              try {
                final picker = ImagePicker();
                final XFile? image = await picker.pickImage(
                  source: source,
                  imageQuality: 85,
                );
                if (image != null) {
                  setModalState(() {
                    pickedAvatarFile = image;
                  });
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Không thể mở thư viện: $e')),
                  );
                }
              }
            }

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
                          backgroundImage: pickedAvatarFile != null
                              ? FileImage(File(pickedAvatarFile!.path)) as ImageProvider
                              : getSmartImageProvider(user.avatarUrl),
                          child: (pickedAvatarFile == null && user.avatarUrl.isEmpty)
                              ? const Icon(Icons.person, size: 54)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // CHỌN ẢNH TỪ ĐIỆN THOẠI HOẶC CHỤP ẢNH
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => pickImage(ImageSource.gallery),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            icon: const Icon(Icons.photo_library_rounded, size: 18),
                            label: const Text('Chọn ảnh', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => pickImage(ImageSource.camera),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            icon: const Icon(Icons.photo_camera_rounded, size: 18),
                            label: const Text('Camera', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    if (pickedAvatarFile != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade900.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.greenAccent),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.greenAccent, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Đã chọn ảnh: ${pickedAvatarFile!.name}',
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // SAVE BUTTON
                    FilledButton.icon(
                      onPressed: () async {
                        final finalUrl = pickedAvatarFile != null
                            ? pickedAvatarFile!.path
                            : user.avatarUrl;

                        await UserFriendService().updateProfile(
                          uid: user.uid,
                          displayName: user.displayName,
                          bio: user.bio,
                          avatarUrl: finalUrl,
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
    XFile? pickedCoverFile;

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
            Future<void> pickImage(ImageSource source) async {
              try {
                final picker = ImagePicker();
                final XFile? image = await picker.pickImage(
                  source: source,
                  imageQuality: 85,
                );
                if (image != null) {
                  setModalState(() {
                    pickedCoverFile = image;
                  });
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Không thể mở thư viện: $e')),
                  );
                }
              }
            }

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
                        height: 130,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              const Color(0xFF818CF8),
                            ],
                          ),
                        ),
                        child: pickedCoverFile != null
                            ? Image.file(
                                File(pickedCoverFile!.path),
                                fit: BoxFit.cover,
                              )
                            : (user.coverUrl.isNotEmpty
                                ? buildSmartImage(user.coverUrl, fit: BoxFit.cover)
                                : const Center(
                                    child: Text(
                                      'Chưa có ảnh bìa',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  )),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // CHỌN ẢNH BÌA TỪ ĐIỆN THOẠI HOẶC CHỤP ẢNH
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => pickImage(ImageSource.gallery),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            icon: const Icon(Icons.photo_library_rounded, size: 18),
                            label: const Text('Chọn ảnh', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => pickImage(ImageSource.camera),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            icon: const Icon(Icons.photo_camera_rounded, size: 18),
                            label: const Text('Camera', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    if (pickedCoverFile != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade900.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.greenAccent),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.greenAccent, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Đã chọn ảnh bìa: ${pickedCoverFile!.name}',
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // SAVE BUTTON
                    FilledButton.icon(
                      onPressed: () async {
                        final finalUrl = pickedCoverFile != null
                            ? pickedCoverFile!.path
                            : user.coverUrl;

                        await UserFriendService().updateProfile(
                          uid: user.uid,
                          displayName: user.displayName,
                          bio: user.bio,
                          avatarUrl: user.avatarUrl,
                          coverUrl: finalUrl,
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
                    ? buildSmartImage(
                        user.avatarUrl,
                        width: 260,
                        height: 260,
                        fit: BoxFit.cover,
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
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (context, currentMode, _) {
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
                    leading: Icon(
                      currentMode == ThemeMode.dark
                          ? Icons.dark_mode_rounded
                          : currentMode == ThemeMode.light
                              ? Icons.light_mode_rounded
                              : Icons.brightness_auto_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text(
                      'Giao diện ứng dụng',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      currentMode == ThemeMode.dark
                          ? 'Đang bật Giao diện Tối (Dark Mode)'
                          : currentMode == ThemeMode.light
                              ? 'Đang bật Giao diện Sáng (Light Mode)'
                              : 'Tự động theo hệ thống thiết bị',
                    ),
                    trailing: DropdownButton<ThemeMode>(
                      value: currentMode,
                      underline: const SizedBox.shrink(),
                      borderRadius: BorderRadius.circular(12),
                      items: const [
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Row(
                            children: [
                              Icon(Icons.light_mode_rounded, size: 18, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('Chế độ Sáng'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Row(
                            children: [
                              Icon(Icons.dark_mode_rounded, size: 18, color: Colors.indigoAccent),
                              SizedBox(width: 8),
                              Text('Chế độ Tối'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Row(
                            children: [
                              Icon(Icons.brightness_auto_rounded, size: 18, color: Colors.teal),
                              SizedBox(width: 8),
                              Text('Theo hệ thống'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (newMode) {
                        if (newMode != null) {
                          themeNotifier.value = newMode;
                        }
                      },
                    ),
                  ),

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
          body: RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // COVER PHOTO & AVATAR SECTION
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      GestureDetector(
                        onTap: () => _showEditCoverDialog(context, user),
                        child: Container(
                          height: 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                const Color(0xFF818CF8),
                              ],
                            ),
                          ),
                          child: user.coverUrl.isNotEmpty
                              ? buildSmartImage(user.coverUrl, fit: BoxFit.cover)
                              : const Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add_a_photo_outlined,
                                          color: Colors.white70, size: 18),
                                      SizedBox(width: 6),
                                      Text(
                                        'Thêm ảnh bìa',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: -46,
                        child: GestureDetector(
                          onTap: () => _showAvatarOptionsSheet(context, user),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              radius: 46,
                              backgroundImage: getSmartImageProvider(user.avatarUrl),
                              child: user.avatarUrl.isEmpty
                                  ? const Icon(Icons.person, size: 46)
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 54),

                  // USER INFO
                  Text(
                    user.displayName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.grey.shade600,
                      fontSize: 13,
                    ),
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
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF1E293B)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF334155)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        user.bio.isNotEmpty
                            ? user.bio
                            : 'Thêm tiểu sử giới thiệu bản thân...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.grey.shade800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // EDIT PROFILE BUTTON
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: OutlinedButton.icon(
                      onPressed: () => _showEditProfileDialog(context, user),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Chỉnh sửa thông tin'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // STATS ROW
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('Bạn bè', '${user.friendIds.length}'),
                            Container(
                                height: 24,
                                width: 1,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF334155)
                                    : Colors.grey.shade300),
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
                  const SizedBox(height: 16),

                  const Divider(height: 24),

                  // SECTION TITLE
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Bài viết của bạn',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // USER'S POSTS STREAM
                  StreamBuilder<List<PostModel>>(
                    stream: postService.getUserPostsStream(user.uid),
                    builder: (context, postSnap) {
                      final posts = postSnap.data ?? [];
                      if (posts.isEmpty) {
                        return Builder(
                          builder: (context) {
                            final isDark = Theme.of(context).brightness == Brightness.dark;
                            return Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Center(
                                child: Text(
                                  'Bạn chưa đăng bài viết nào.\nHãy chia sẻ khoảnh khắc đầu tiên!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          return PostCardWidget(
                            post: posts[index],
                            currentUser: user,
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        );
      },
    );
  }
}
