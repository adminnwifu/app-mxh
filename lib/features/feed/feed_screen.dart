import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../models/comment_model.dart';
import '../../models/post_model.dart';
import '../../models/story_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/post_service.dart';
import '../../services/story_service.dart';
import '../../services/user_friend_service.dart';
import '../notifications/notification_screen.dart';
import '../profile/user_profile_detail_screen.dart';
import '../search/ai_search_screen.dart';

/// Helper hiển thị ảnh thông minh từ URL hoặc Tệp điện thoại
Widget buildSmartImage(String path, {BoxFit fit = BoxFit.cover, double? width, double? height}) {
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return Image.network(
      path,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFF334155),
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.white54, size: 40),
        ),
      ),
    );
  } else {
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => Container(
          color: const Color(0xFF334155),
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.white54, size: 40),
          ),
        ),
      );
    } else {
      return Image.network(
        path,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => Container(
          color: const Color(0xFF334155),
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.white54, size: 40),
          ),
        ),
      );
    }
  }
}

/// Widget thu gọn văn bản dài cho Bài viết và Bình luận với nút Xem thêm / Thu gọn
class ExpandableTextWidget extends StatefulWidget {
  final String text;
  final int maxChars;
  final TextStyle style;

  const ExpandableTextWidget({
    super.key,
    required this.text,
    this.maxChars = 120,
    this.style = const TextStyle(fontSize: 15, height: 1.4, color: Colors.black87),
  });

  @override
  State<ExpandableTextWidget> createState() => _ExpandableTextWidgetState();
}

class _ExpandableTextWidgetState extends State<ExpandableTextWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final defaultTextColor = Theme.of(context).colorScheme.onSurface;
    final effectiveStyle = widget.style.copyWith(
      color: (widget.style.color == Colors.black87 || widget.style.color == Colors.black)
          ? defaultTextColor
          : (widget.style.color ?? defaultTextColor),
    );

    final lines = widget.text.split('\n');
    final isTooLong = widget.text.length > widget.maxChars || lines.length > 3;

    if (!isTooLong) {
      return Text(widget.text, style: effectiveStyle);
    }

    String displayText;
    if (_isExpanded) {
      displayText = widget.text;
    } else {
      if (widget.text.length > widget.maxChars) {
        displayText = '${widget.text.substring(0, widget.maxChars)}...';
      } else {
        displayText = '${lines.take(3).join('\n')}...';
      }
    }

    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(displayText, style: effectiveStyle),
        const SizedBox(height: 3),
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Text(
              _isExpanded ? 'Thu gọn ▲' : 'Xem thêm ▼',
              style: TextStyle(
                fontSize: effectiveStyle.fontSize != null
                    ? effectiveStyle.fontSize! - 2
                    : 12,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  /// Giao diện Studio Tạo Tin Mới
  void _showCreateStoryModal(BuildContext context, UserModel currentUser) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreateStoryStudioModal(currentUser: currentUser),
    );
  }

  /// Modal Xem Story Tương Tác: Tap 1 lần để chuyển tin tiếp theo, Nhấn giữ để Tạm dừng
  void _showStoryViewerModal(
      BuildContext context, List<StoryModel> stories, int initialIndex, UserModel currentUser) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (ctx) => _StoryViewerInteractiveSheet(
        stories: stories,
        initialIndex: initialIndex,
        currentUser: currentUser,
      ),
    );
  }

  void _showCreatePostDialog(BuildContext context, UserModel currentUser) {
    final contentController = TextEditingController();
    String selectedVisibility = 'public';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
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
                        'Tạo bài viết mới',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 22,
                      backgroundImage: currentUser.avatarUrl.isNotEmpty
                          ? NetworkImage(currentUser.avatarUrl)
                          : null,
                      child: currentUser.avatarUrl.isEmpty
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(
                      currentUser.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: PopupMenuButton<String>(
                      initialValue: selectedVisibility,
                      onSelected: (val) {
                        setDialogState(() => selectedVisibility = val);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              selectedVisibility == 'public'
                                  ? Icons.public
                                  : selectedVisibility == 'friends'
                                      ? Icons.group
                                      : Icons.lock,
                              size: 14,
                              color: Colors.grey.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              selectedVisibility == 'public'
                                  ? 'Công khai'
                                  : selectedVisibility == 'friends'
                                      ? 'Bạn bè'
                                      : 'Chỉ mình tôi',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, size: 18),
                          ],
                        ),
                      ),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'public',
                          child: Row(
                            children: [
                              Icon(Icons.public, size: 18, color: Colors.blueAccent),
                              SizedBox(width: 8),
                              Text('Công khai'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'friends',
                          child: Row(
                            children: [
                              Icon(Icons.group, size: 18, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Bạn bè'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'private',
                          child: Row(
                            children: [
                              Icon(Icons.lock, size: 18, color: Colors.redAccent),
                              SizedBox(width: 8),
                              Text('Chỉ mình tôi'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: contentController,
                    maxLines: 6,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Bạn đang nghĩ gì thế?',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      fillColor: Colors.transparent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      if (contentController.text.trim().isEmpty) return;
                      await PostService().createPost(
                        author: currentUser,
                        content: contentController.text.trim(),
                        visibility: selectedVisibility,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Đăng bài ngay'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = AuthService().currentUser?.uid;
    if (currentUid == null) return const SizedBox.shrink();

    final userService = UserFriendService();
    final postService = PostService();
    final storyService = StoryService();
    final notificationService = NotificationService();

    return StreamBuilder<UserModel?>(
      stream: userService.getUserProfileStream(currentUid),
      builder: (context, userSnapshot) {
        final currentUser = userSnapshot.data;
        if (currentUser == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bubble_chart_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'MiniSocial',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AiSearchScreen(currentUser: currentUser),
                    ),
                  );
                },
              ),
              StreamBuilder<int>(
                stream: notificationService.getUnreadCountStream(currentUser.uid),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data ?? 0;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none_rounded),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NotificationScreen(
                                currentUserId: currentUser.uid,
                              ),
                            ),
                          );
                        },
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              unreadCount > 9 ? '9+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showCreatePostDialog(context, currentUser),
            elevation: 4,
            child: const Icon(Icons.edit_note_rounded, size: 28),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: CustomScrollView(
              slivers: [
                // FACEBOOK-STYLE STORY CARD CAROUSEL
                SliverToBoxAdapter(
                  child: Container(
                    height: 195,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: StreamBuilder<List<StoryModel>>(
                      stream: storyService.getActiveStoriesStream(
                        currentUserId: currentUser.uid,
                        currentUserFriendIds: currentUser.friendIds,
                      ),
                      builder: (context, storySnap) {
                        final activeStories = storySnap.data ?? [];

                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: 1 + activeStories.length,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: _buildCreateStoryCard(context, currentUser),
                              );
                            }
                            final story = activeStories[index - 1];
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: _buildStoryCard(context, story, activeStories, index - 1, currentUser),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),

                // CREATE POST QUICK TRIGGER BAR
                SliverToBoxAdapter(
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: currentUser.avatarUrl.isNotEmpty
                                ? NetworkImage(currentUser.avatarUrl)
                                : null,
                            child: currentUser.avatarUrl.isEmpty
                                ? const Icon(Icons.person, size: 18)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showCreatePostDialog(context, currentUser),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Text(
                                  'Bạn đang nghĩ gì thế, ${currentUser.displayName.split(' ').last}?',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // REALTIME FEED POSTS STREAM WITH STRICT PRIVACY FILTERING
                StreamBuilder<List<PostModel>>(
                  stream: postService.getHomeFeedStream(
                    currentUserId: currentUser.uid,
                    currentUserFriendIds: currentUser.friendIds,
                  ),
                  builder: (context, postSnapshot) {
                    if (postSnapshot.connectionState == ConnectionState.waiting) {
                      return const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final posts = postSnapshot.data ?? [];
                    if (posts.isEmpty) {
                      return const SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.feed_outlined, size: 64, color: Colors.grey),
                              SizedBox(height: 12),
                              Text(
                                'Chưa có bài viết nào.\nHãy đăng bài đầu tiên hoặc kết bạn thêm!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return PostCardWidget(
                            post: posts[index],
                            currentUser: currentUser,
                          );
                        },
                        childCount: posts.length,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Thẻ Tạo Tin / Ghi Chú đầu tiên
  Widget _buildCreateStoryCard(BuildContext context, UserModel user) {
    return GestureDetector(
      onTap: () => _showCreateStoryModal(context, user),
      child: Container(
        width: 115,
        height: 190,
        decoration: BoxDecoration(
          color: const Color(0xFF242526),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 125,
                child: user.avatarUrl.isNotEmpty
                    ? Image.network(
                        user.avatarUrl,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: Colors.grey.shade800,
                        child: const Icon(Icons.person, size: 50, color: Colors.white70),
                      ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 65,
                child: Container(
                  color: const Color(0xFF242526),
                  padding: const EdgeInsets.only(bottom: 10),
                  child: const Align(
                    alignment: Alignment.bottomCenter,
                    child: Text(
                      'Tạo tin',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 106,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Color(0xFF242526),
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1877F2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Thẻ Tin Dọc Dành Cho Mỗi Story
  Widget _buildStoryCard(
      BuildContext context, StoryModel story, List<StoryModel> allStories, int storyIndex, UserModel currentUser) {
    return GestureDetector(
      onTap: () => _showStoryViewerModal(context, allStories, storyIndex, currentUser),
      child: Container(
        width: 115,
        height: 190,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                child: story.mediaUrl != null && story.mediaUrl!.isNotEmpty
                    ? buildSmartImage(
                        story.mediaUrl!,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: story.postContent != null
                                ? [const Color(0xFF312E81), const Color(0xFF4338CA)]
                                : [const Color(0xFF1E293B), const Color(0xFF334155)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(top: 48, left: 8, right: 8, bottom: 38),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        story.postContent != null
                            ? '📌 ${story.postContent!}'
                            : story.content,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 50,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black87],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1877F2), Color(0xFF00C6FF)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundImage: story.authorAvatar.isNotEmpty
                        ? NetworkImage(story.authorAvatar)
                        : null,
                    child: story.authorAvatar.isEmpty
                        ? const Icon(Icons.person, size: 16)
                        : null,
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Text(
                  story.authorName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Giao diện Xem Story Tương Tác: Chạm 1 lần để chuyển tin tiếp theo, Nhấn giữ để Tạm dừng
class _StoryViewerInteractiveSheet extends StatefulWidget {
  final List<StoryModel> stories;
  final int initialIndex;
  final UserModel currentUser;

  const _StoryViewerInteractiveSheet({
    required this.stories,
    required this.initialIndex,
    required this.currentUser,
  });

  @override
  State<_StoryViewerInteractiveSheet> createState() =>
      _StoryViewerInteractiveSheetState();
}

class _StoryViewerInteractiveSheetState
    extends State<_StoryViewerInteractiveSheet> {
  late int _currentIndex;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _showStoryMoreMenu(BuildContext modalCtx, StoryModel story) {
    final isAuthor = story.authorId == widget.currentUser.uid;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              if (isAuthor) ...[
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded,
                      color: Colors.redAccent),
                  title: const Text(
                    'Xóa tin này',
                    style: TextStyle(
                        color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Tin sẽ bị gỡ bỏ khỏi trang chủ ngay lập tức',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    Navigator.pop(modalCtx);
                    await StoryService().deleteStory(story.storyId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🗑️ Đã xóa tin thành công!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
                const Divider(color: Colors.white12),
              ],
              ListTile(
                leading: const Icon(Icons.copy_rounded, color: Colors.white70),
                title: const Text('Sao chép nội dung tin',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã sao chép nội dung tin!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.white70),
                title: const Text('Báo cáo tin xấu',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã gửi báo cáo tin tới quản trị viên.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPaused) {
      setState(() => _isPaused = false);
      return;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final dx = details.globalPosition.dx;

    if (dx > screenWidth * 0.35) {
      // Chuyển sang Tin tiếp theo
      if (_currentIndex < widget.stories.length - 1) {
        setState(() => _currentIndex++);
      } else {
        Navigator.pop(context); // Hết tin -> đóng xem Story
      }
    } else {
      // Quay lại Tin trước đó
      if (_currentIndex > 0) {
        setState(() => _currentIndex--);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];
    final ageInMinutes = DateTime.now().difference(story.createdAt).inMinutes;
    final hoursAgo = ageInMinutes ~/ 60;
    final timeDisplay = hoursAgo > 0 ? '$hoursAgo giờ' : '$ageInMinutes phút';
    final replyController = TextEditingController();

    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      color: story.type == 'image' || story.mediaUrl != null
          ? const Color(0xFF534834)
          : const Color(0xFF332F28),
      child: SafeArea(
        child: GestureDetector(
          onTapUp: _handleTapUp,
          onLongPressStart: (_) => setState(() => _isPaused = true),
          onLongPressEnd: (_) => setState(() => _isPaused = false),
          child: Stack(
            children: [
              // 1. STORY MAIN BODY
              Positioned.fill(
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    Expanded(
                      child: Center(
                        child: story.mediaUrl != null && story.mediaUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: buildSmartImage(
                                  story.mediaUrl!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  story.content,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    if (story.content.isNotEmpty && story.mediaUrl != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        child: Text(
                          story.content,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(color: Colors.black, blurRadius: 6),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 70),
                  ],
                ),
              ),

              // 2. HEADER TOP ROW WITH SEGMENTED PROGRESS BARS
              Positioned(
                top: 8,
                left: 12,
                right: 12,
                child: Column(
                  children: [
                    // MULTI-STORY PROGRESS SEGMENTS
                    Row(
                      children: List.generate(widget.stories.length, (index) {
                        final isFinished = index < _currentIndex;
                        final isCurrent = index == _currentIndex;

                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            height: 3,
                            decoration: BoxDecoration(
                              color: isFinished
                                  ? Colors.white
                                  : isCurrent
                                      ? (_isPaused ? Colors.amber : Colors.white)
                                      : Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 10),

                    // HEADER INFO
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: story.authorAvatar.isNotEmpty
                              ? NetworkImage(story.authorAvatar)
                              : null,
                          child: story.authorAvatar.isEmpty
                              ? const Icon(Icons.person, size: 18)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    story.authorName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$timeDisplay 🌐',
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 11),
                                  ),
                                ],
                              ),
                              if (_isPaused) ...[
                                const Text(
                                  '⏸ Đã tạm dừng tin',
                                  style: TextStyle(
                                    color: Colors.amberAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() => _isPaused = !_isPaused);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_horiz_rounded,
                              color: Colors.white, size: 20),
                          onPressed: () =>
                              _showStoryMoreMenu(context, story),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 3. BOTTOM REPLY BAR & REACTION EMOJIS
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white38),
                        ),
                        child: TextField(
                          controller: replyController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'Nhắn...',
                            hintStyle:
                                TextStyle(color: Colors.white70, fontSize: 13),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          onSubmitted: (text) {
                            if (text.trim().isNotEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Đã gửi tin nhắn tới ${story.authorName}!'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildEmojiButton(context, '👍', story.authorName),
                        _buildEmojiButton(context, '❤️', story.authorName),
                        _buildEmojiButton(context, '🥰', story.authorName),
                        _buildEmojiButton(context, '😆', story.authorName),
                        _buildEmojiButton(context, '😲', story.authorName),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmojiButton(
      BuildContext context, String emoji, String authorName) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã thả $emoji cho tin của $authorName!'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}

/// Giao diện Studio Tạo Tin Chọn Ảnh Trực Tiếp Từ Điện Thoại
class _CreateStoryStudioModal extends StatefulWidget {
  final UserModel currentUser;

  const _CreateStoryStudioModal({required this.currentUser});

  @override
  State<_CreateStoryStudioModal> createState() => _CreateStoryStudioModalState();
}

class _CreateStoryStudioModalState extends State<_CreateStoryStudioModal> {
  final _storyService = StoryService();
  final _captionController = TextEditingController();

  int _selectedMode = 0; // 0: Tin Ảnh / Phương tiện, 1: Tin Văn bản
  XFile? _pickedImageFile;
  String _selectedPresetUrl = 'https://picsum.photos/800/1200?random=101';
  bool _isPublishing = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _pickedImageFile = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể mở thư viện: $e')),
        );
      }
    }
  }

  Future<void> _publishStory() async {
    if (_isPublishing) return;
    setState(() => _isPublishing = true);

    if (_selectedMode == 0) {
      final finalPath = _pickedImageFile != null
          ? _pickedImageFile!.path
          : _selectedPresetUrl;

      await _storyService.createStory(
        author: widget.currentUser,
        type: 'image',
        mediaUrl: finalPath,
        content: _captionController.text.trim().isEmpty
            ? '1 tháng xem 4film 🥺'
            : _captionController.text.trim(),
      );
    } else {
      if (_captionController.text.trim().isEmpty) {
        setState(() => _isPublishing = false);
        return;
      }
      await _storyService.createStory(
        author: widget.currentUser,
        type: 'text',
        content: _captionController.text.trim(),
      );
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Đã chia sẻ Story mới thành công!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // HEADER STUDIO
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Tạo Story',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _isPublishing ? null : _publishStory,
                    icon: _isPublishing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 16),
                    label: const Text('Đăng ngay'),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),

            // THẺ CHỌN CHẾ ĐỘ TRỰC QUAN
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedMode = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedMode == 0
                              ? primaryColor
                              : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _selectedMode == 0
                                ? Colors.white
                                : Colors.white24,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo_library_rounded,
                                color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Tin Ảnh / Video',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedMode = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedMode == 1
                              ? primaryColor
                              : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _selectedMode == 1
                                ? Colors.white
                                : Colors.white24,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit_note_rounded,
                                color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Tin Văn bản',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // STUDIO CANVAS PREVIEW & INPUT FORM
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // LIVE STUDIO CANVAS PREVIEW
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            if (_selectedMode == 0) ...[
                              Positioned.fill(
                                child: buildSmartImage(
                                  _pickedImageFile != null
                                      ? _pickedImageFile!.path
                                      : _selectedPresetUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                bottom: 12,
                                left: 16,
                                right: 16,
                                child: Text(
                                  _captionController.text.isNotEmpty
                                      ? _captionController.text
                                      : '1 tháng xem 4film 🥺',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(color: Colors.black, blurRadius: 6)
                                    ],
                                  ),
                                ),
                              ),
                            ] else ...[
                              Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Text(
                                      _captionController.text.isNotEmpty
                                          ? _captionController.text
                                          : 'Nhập nội dung ghi chú của bạn...',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // CHỌN ẢNH TRỰC TIẾP TỪ ĐIỆN THOẠI HOẶC CHỤP ẢNH
                    if (_selectedMode == 0) ...[
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.tonalIcon(
                              onPressed: () => _pickImage(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_rounded, size: 18),
                              label: const Text('Chọn ảnh từ máy'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickImage(ImageSource.camera),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white38),
                              ),
                              icon: const Icon(Icons.photo_camera_rounded,
                                  size: 18, color: Colors.white),
                              label: const Text('Chụp ảnh mới',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                      if (_pickedImageFile != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.shade900.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.greenAccent),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  color: Colors.greenAccent, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Đã chọn: ${_pickedImageFile!.name}',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _pickedImageFile = null),
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 16),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Mẫu ảnh chọn nhanh:',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: ActionChip(
                                avatar: const Icon(Icons.movie, size: 14),
                                label: const Text('Vé CGV', style: TextStyle(fontSize: 11)),
                                onPressed: () {
                                  setState(() {
                                    _selectedPresetUrl =
                                        'https://picsum.photos/800/1200?random=101';
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ActionChip(
                                avatar: const Icon(Icons.landscape, size: 14),
                                label: const Text('Du lịch', style: TextStyle(fontSize: 11)),
                                onPressed: () {
                                  setState(() {
                                    _selectedPresetUrl =
                                        'https://picsum.photos/800/1200?random=102';
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ActionChip(
                                avatar: const Icon(Icons.star, size: 14),
                                label: const Text('Nghệ thuật', style: TextStyle(fontSize: 11)),
                                onPressed: () {
                                  setState(() {
                                    _selectedPresetUrl =
                                        'https://picsum.photos/800/1200?random=103';
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                    ],

                    // CAPTION INPUT FIELD
                    TextField(
                      controller: _captionController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      onChanged: (_) => setState(() {}),
                      maxLines: _selectedMode == 1 ? 3 : 1,
                      decoration: InputDecoration(
                        labelText: _selectedMode == 0
                            ? 'Chú thích ảnh (Ví dụ: 1 tháng xem 4film 🥺)'
                            : 'Nội dung ghi chú / văn bản...',
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.title, color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReactionTypeInfo {
  final String type;
  final String label;
  final String emoji;
  final Color color;

  const ReactionTypeInfo({
    required this.type,
    required this.label,
    required this.emoji,
    required this.color,
  });
}

const List<ReactionTypeInfo> kPostReactions = [
  ReactionTypeInfo(type: 'like', label: 'Thích', emoji: '👍', color: Colors.blue),
  ReactionTypeInfo(type: 'love', label: 'Yêu thích', emoji: '❤️', color: Colors.redAccent),
  ReactionTypeInfo(type: 'care', label: 'Thương thương', emoji: '🥰', color: Colors.amber),
  ReactionTypeInfo(type: 'haha', label: 'Haha', emoji: '😆', color: Colors.amber),
  ReactionTypeInfo(type: 'wow', label: 'Wow', emoji: '😲', color: Colors.amber),
  ReactionTypeInfo(type: 'sad', label: 'Buồn', emoji: '😢', color: Colors.amber),
  ReactionTypeInfo(type: 'angry', label: 'Phẫn nộ', emoji: '😡', color: Colors.deepOrange),
];

/// Modal xem danh sách những người đã thả cảm xúc (Bài viết hoặc Bình luận)
class _ReactionsListViewSheet extends StatefulWidget {
  final Map<String, String> mergedReactions; // userId -> reactionType
  final UserModel currentUser;

  const _ReactionsListViewSheet({
    required this.mergedReactions,
    required this.currentUser,
  });

  @override
  State<_ReactionsListViewSheet> createState() =>
      _ReactionsListViewSheetState();
}

class _ReactionsListViewSheetState extends State<_ReactionsListViewSheet> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final entries = widget.mergedReactions.entries.where((e) {
      if (_selectedFilter == 'all') return true;
      return e.value == _selectedFilter;
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              'Cảm xúc (${widget.mergedReactions.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const Divider(height: 1),

          // FILTER CHIPS ROW
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: Text('Tất cả ${widget.mergedReactions.length}'),
                  selected: _selectedFilter == 'all',
                  onSelected: (_) => setState(() => _selectedFilter = 'all'),
                ),
                ...kPostReactions.map((r) {
                  final count = widget.mergedReactions.values
                      .where((val) => val == r.type)
                      .length;
                  if (count == 0) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(left: 6.0),
                    child: FilterChip(
                      label: Text('${r.emoji} $count'),
                      selected: _selectedFilter == r.type,
                      onSelected: (_) =>
                          setState(() => _selectedFilter = r.type),
                    ),
                  );
                }),
              ],
            ),
          ),
          const Divider(height: 1),

          // LIST OF USERS
          Expanded(
            child: entries.isEmpty
                ? const Center(child: Text('Không có người dùng nào.'))
                : ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final uid = entries[index].key;
                      final reactionType = entries[index].value;
                      final rInfo = kPostReactions.firstWhere(
                        (r) => r.type == reactionType,
                        orElse: () => kPostReactions.first,
                      );

                      return StreamBuilder<UserModel?>(
                        stream: UserFriendService().getUserProfileStream(uid),
                        builder: (context, snapshot) {
                          final user = snapshot.data;
                          if (user == null) {
                            return const SizedBox.shrink();
                          }

                          return ListTile(
                            leading: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage: user.avatarUrl.isNotEmpty
                                      ? NetworkImage(user.avatarUrl)
                                      : null,
                                  child: user.avatarUrl.isEmpty
                                      ? const Icon(Icons.person, size: 20)
                                      : null,
                                ),
                                Positioned(
                                  right: -4,
                                  bottom: -2,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      rInfo.emoji,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            title: Text(
                              user.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              'Đã thả ${rInfo.emoji} (${rInfo.label})',
                              style: TextStyle(
                                fontSize: 12,
                                color: rInfo.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: Colors.black38,
                            ),
                            onTap: () {
                              Navigator.pop(context);
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
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Widget thẻ bài viết với phản hồi Thích (Like) / Cảm xúc Facebook & Bình luận thời gian thực
class PostCardWidget extends StatefulWidget {
  final PostModel post;
  final UserModel currentUser;

  const PostCardWidget({
    super.key,
    required this.post,
    required this.currentUser,
  });

  @override
  State<PostCardWidget> createState() => _PostCardWidgetState();
}

class _PostCardWidgetState extends State<PostCardWidget> {
  bool _isLiking = false;

  void _showReactionPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 16,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Bày tỏ cảm xúc',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: kPostReactions.map((reaction) {
                  final isSelected =
                      widget.post.getReactionOf(widget.currentUser.uid) ==
                          reaction.type;

                  return GestureDetector(
                    onTap: () async {
                      Navigator.pop(ctx);
                      await PostService().setReaction(
                        postId: widget.post.postId,
                        postAuthorId: widget.post.authorId,
                        currentUser: widget.currentUser,
                        reactionType: isSelected ? null : reaction.type,
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? reaction.color.withOpacity(0.2)
                                : Colors.transparent,
                          ),
                          child: Text(
                            reaction.emoji,
                            style: TextStyle(
                              fontSize: isSelected ? 30 : 26,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          reaction.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? reaction.color : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openCommentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CommentBottomSheet(
        postId: widget.post.postId,
        postAuthorId: widget.post.authorId,
        currentUser: widget.currentUser,
      ),
    );
  }

  void _showShareOptionsSheet(BuildContext context) {
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
                'Tùy chọn chia sẻ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.auto_awesome, color: Color(0xFF6366F1)),
                title: const Text('Chia sẻ bài viết này lên Tin của tôi'),
                subtitle: const Text('Đưa bài viết này lên thẻ Tin thời gian thực'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await StoryService().createStory(
                    author: widget.currentUser,
                    type: 'text',
                    content: 'Đã chia sẻ một bài viết',
                    postContent: widget.post.content,
                    postAuthorName: widget.post.authorName,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🎉 Đã chia sẻ bài viết lên Tin của bạn!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: const Text('Sao chép văn bản bài viết'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã sao chép nội dung bài viết!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showPostReactionsUsersSheet() {
    Map<String, String> merged = Map.from(widget.post.reactions);
    for (var id in widget.post.likes) {
      if (!merged.containsKey(id)) merged[id] = 'like';
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReactionsListViewSheet(
        mergedReactions: merged,
        currentUser: widget.currentUser,
      ),
    );
  }

  void _confirmDeletePost(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa bài viết'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa bài viết này khỏi Trang chủ? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await PostService().deletePost(widget.post.postId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🗑️ Đã xóa bài viết thành công!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Xóa bài viết'),
          ),
        ],
      ),
    );
  }

  void _handleLikeToggle() async {
    if (_isLiking) return;
    setState(() => _isLiking = true);

    final currentReaction = widget.post.getReactionOf(widget.currentUser.uid);

    await PostService().setReaction(
      postId: widget.post.postId,
      postAuthorId: widget.post.authorId,
      currentUser: widget.currentUser,
      reactionType: currentReaction != null ? null : 'like',
    );

    if (mounted) {
      setState(() => _isLiking = false);
    }
  }

  List<String> _getUniqueActiveEmojis() {
    final Set<String> emojis = {};
    widget.post.reactions.forEach((uid, type) {
      final match = kPostReactions.firstWhere(
        (r) => r.type == type,
        orElse: () => kPostReactions.first,
      );
      emojis.add(match.emoji);
    });
    if (emojis.isEmpty && widget.post.likes.isNotEmpty) {
      emojis.add('👍');
    }
    return emojis.toList();
  }

  @override
  Widget build(BuildContext context) {
    final userReaction = widget.post.getReactionOf(widget.currentUser.uid);
    final reactionInfo = userReaction != null
        ? kPostReactions.firstWhere(
            (r) => r.type == userReaction,
            orElse: () => kPostReactions.first,
          )
        : null;

    final totalReactions = widget.post.totalReactions;
    final timeStr = DateFormat('dd/MM/yyyy HH:mm').format(widget.post.createdAt);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER POST
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: widget.post.authorAvatar.isNotEmpty
                      ? NetworkImage(widget.post.authorAvatar)
                      : null,
                  child: widget.post.authorAvatar.isEmpty
                      ? const Icon(Icons.person, size: 20)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            widget.post.visibility == 'public'
                                ? Icons.public
                                : widget.post.visibility == 'friends'
                                    ? Icons.group
                                    : Icons.lock,
                            size: 13,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            widget.post.visibility == 'public'
                                ? 'Công khai'
                                : widget.post.visibility == 'friends'
                                    ? 'Bạn bè'
                                    : 'Chỉ mình tôi',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz_rounded),
                  onSelected: (val) async {
                    if (val == 'delete') {
                      _confirmDeletePost(context);
                    } else if (val == 'copy') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã sao chép nội dung bài viết!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else if (val == 'hide') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã ẩn bài viết khỏi trang chủ!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  itemBuilder: (_) => [
                    if (widget.post.authorId == widget.currentUser.uid)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded,
                                color: Colors.redAccent, size: 18),
                            SizedBox(width: 8),
                            Text('Xóa bài viết',
                                style: TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'copy',
                      child: Row(
                        children: [
                          Icon(Icons.copy_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Sao chép văn bản'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'hide',
                      child: Row(
                        children: [
                          Icon(Icons.visibility_off_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Ẩn bài viết'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // CONTENT WITH EXPANDABLE "Xem thêm" / "Thu gọn"
            ExpandableTextWidget(
              text: widget.post.content,
              maxChars: 120,
              style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            // STATS ROW
            Row(
              children: [
                if (totalReactions > 0) ...[
                  GestureDetector(
                    onTap: _showPostReactionsUsersSheet,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getUniqueActiveEmojis().join(' '),
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$totalReactions lượt bày tỏ cảm xúc',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                if (widget.post.commentCount > 0)
                  GestureDetector(
                    onTap: () => _openCommentSheet(context),
                    child: Text(
                      '${widget.post.commentCount} bình luận',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ),
              ],
            ),
            const Divider(height: 16),

            // ACTION BUTTONS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // NÚT BÀY TỎ CẢM XÚC / THÍCH
                Expanded(
                  child: InkWell(
                    onTap: _handleLikeToggle,
                    onLongPress: () => _showReactionPicker(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (reactionInfo != null) ...[
                            Text(
                              reactionInfo.emoji,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  reactionInfo.label,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: reactionInfo.color,
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            Icon(
                              Icons.thumb_up_alt_outlined,
                              color: Colors.grey.shade700,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Thích',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                // NÚT BÌNH LUẬN
                Expanded(
                  child: InkWell(
                    onTap: () => _openCommentSheet(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.mode_comment_outlined,
                            color: Colors.grey.shade700,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                widget.post.commentCount > 0
                                    ? '${widget.post.commentCount} Bình luận'
                                    : 'Bình luận',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // NÚT CHIA SẺ
                Expanded(
                  child: InkWell(
                    onTap: () => _showShareOptionsSheet(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.share_outlined,
                            color: Colors.grey.shade700,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Chia sẻ',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// BottomSheet Xem, Thả Tim, Trả Lời, Sửa/Xóa & Đính Kèm Ảnh Bình Luận theo thời gian thực
class CommentBottomSheet extends StatefulWidget {
  final String postId;
  final String postAuthorId;
  final UserModel currentUser;

  const CommentBottomSheet({
    super.key,
    required this.postId,
    required this.postAuthorId,
    required this.currentUser,
  });

  @override
  State<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  final _commentController = TextEditingController();
  final _focusNode = FocusNode();
  final _postService = PostService();

  CommentModel? _replyingToComment;
  CommentModel? _editingComment;
  XFile? _attachedImageFile;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: source, imageQuality: 80);
      if (image != null) {
        setState(() {
          _attachedImageFile = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể chọn ảnh: $e')),
        );
      }
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if ((text.isEmpty && _attachedImageFile == null) || _isSending) return;

    setState(() => _isSending = true);

    if (_editingComment != null) {
      // Đang chỉnh sửa bình luận cũ
      await _postService.editComment(
        postId: widget.postId,
        commentId: _editingComment!.commentId,
        newText: text,
      );
      setState(() {
        _editingComment = null;
        _commentController.clear();
      });
    } else {
      // Tạo bình luận mới
      final replyId = _replyingToComment?.commentId;
      final replyName = _replyingToComment?.authorName;
      final imagePath = _attachedImageFile?.path;

      _commentController.clear();
      setState(() {
        _replyingToComment = null;
        _attachedImageFile = null;
      });

      await _postService.addComment(
        postId: widget.postId,
        postAuthorId: widget.postAuthorId,
        author: widget.currentUser,
        text: text,
        imageUrl: imagePath,
        replyToId: replyId,
        replyToName: replyName,
      );
    }

    if (mounted) {
      setState(() => _isSending = false);
    }
  }

  void _showCommentOptions(CommentModel comment) {
    final isCommentAuthor = comment.authorId == widget.currentUser.uid;
    final isPostAuthor = widget.postAuthorId == widget.currentUser.uid;

    if (!isCommentAuthor && !isPostAuthor) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              if (isCommentAuthor) ...[
                ListTile(
                  leading: const Icon(Icons.edit_rounded, color: Colors.blueAccent),
                  title: const Text('Chỉnh sửa bình luận'),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _editingComment = comment;
                      _replyingToComment = null;
                      _commentController.text = comment.text;
                    });
                    _focusNode.requestFocus();
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                title: const Text('Xóa bình luận', style: TextStyle(color: Colors.redAccent)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _postService.deleteComment(
                    postId: widget.postId,
                    commentId: comment.commentId,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🗑️ Đã xóa bình luận!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showCommentReactionPicker(CommentModel comment) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 16,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Bày tỏ cảm xúc cho bình luận',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: kPostReactions.map((reaction) {
                  final isSelected =
                      comment.getReactionOf(widget.currentUser.uid) ==
                          reaction.type;

                  return GestureDetector(
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _postService.setCommentReaction(
                        postId: widget.postId,
                        commentId: comment.commentId,
                        currentUser: widget.currentUser,
                        reactionType: isSelected ? null : reaction.type,
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? reaction.color.withOpacity(0.2)
                                : Colors.transparent,
                          ),
                          child: Text(
                            reaction.emoji,
                            style: TextStyle(
                              fontSize: isSelected ? 30 : 26,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          reaction.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? reaction.color : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  List<String> _getCommentUniqueActiveEmojis(CommentModel comment) {
    final Set<String> emojis = {};
    comment.reactions.forEach((uid, type) {
      final match = kPostReactions.firstWhere(
        (r) => r.type == type,
        orElse: () => kPostReactions.first,
      );
      emojis.add(match.emoji);
    });
    if (emojis.isEmpty && comment.likes.isNotEmpty) {
      emojis.add('👍');
    }
    return emojis.toList();
  }

  void _showCommentReactionsUsersSheet(CommentModel comment) {
    Map<String, String> merged = Map.from(comment.reactions);
    for (var id in comment.likes) {
      if (!merged.containsKey(id)) merged[id] = 'like';
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReactionsListViewSheet(
        mergedReactions: merged,
        currentUser: widget.currentUser,
      ),
    );
  }

  void _navigateToUserProfile(String authorId, String authorName, String authorAvatar) {
    final targetUser = UserModel(
      uid: authorId,
      email: '',
      displayName: authorName,
      avatarUrl: authorAvatar,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileDetailScreen(
          targetUser: targetUser,
          currentUser: widget.currentUser,
        ),
      ),
    );
  }

  void _showPickImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
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
                'Đính kèm hình ảnh',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Colors.blue),
                title: const Text('Chọn ảnh từ thư viện'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded, color: Colors.green),
                title: const Text('Chụp ảnh mới'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.grey.shade100;
    final onSurfaceColor = theme.colorScheme.onSurface;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;
    final actionBtnColor = isDark ? Colors.white70 : Colors.grey.shade700;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.78,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Text(
                'Bình luận',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: onSurfaceColor,
                ),
              ),
            ),
            const Divider(height: 1),

            // STREAM DANH SÁCH BÌNH LUẬN
            Expanded(
              child: StreamBuilder<List<CommentModel>>(
                stream: _postService.getCommentsStream(widget.postId),
                builder: (context, snapshot) {
                  final comments = snapshot.data ?? [];
                  if (comments.isEmpty) {
                    return Center(
                      child: Text(
                        'Chưa có bình luận nào.\nHãy là người đầu tiên viết bình luận!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: secondaryTextColor),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final c = comments[index];
                      final cReaction = c.getReactionOf(widget.currentUser.uid);
                      final cReactionInfo = cReaction != null
                          ? kPostReactions.firstWhere(
                              (r) => r.type == cReaction,
                              orElse: () => kPostReactions.first,
                            )
                          : null;
                      final timeAgo = DateFormat('HH:mm dd/MM').format(c.createdAt);
                      final isReply = c.replyToId != null;
                      final canManage = c.authorId == widget.currentUser.uid ||
                          widget.postAuthorId == widget.currentUser.uid;

                      return Padding(
                        padding: EdgeInsets.only(
                          left: isReply ? 36.0 : 0.0,
                          top: 6,
                          bottom: 6,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => _navigateToUserProfile(
                                c.authorId,
                                c.authorName,
                                c.authorAvatar,
                              ),
                              child: CircleAvatar(
                                radius: isReply ? 14 : 17,
                                backgroundImage: c.authorAvatar.isNotEmpty
                                    ? NetworkImage(c.authorAvatar)
                                    : null,
                                child: c.authorAvatar.isEmpty
                                    ? Icon(Icons.person, size: isReply ? 14 : 17)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onLongPress: () => _showCommentOptions(c),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: cardBgColor,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isDark
                                              ? const Color(0xFF334155)
                                              : Colors.transparent,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Wrap(
                                                  crossAxisAlignment: WrapCrossAlignment.center,
                                                  children: [
                                                    GestureDetector(
                                                      onTap: () => _navigateToUserProfile(
                                                        c.authorId,
                                                        c.authorName,
                                                        c.authorAvatar,
                                                      ),
                                                      child: Text(
                                                        c.authorName,
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 13,
                                                          color: onSurfaceColor,
                                                        ),
                                                      ),
                                                    ),
                                                    if (c.replyToName != null) ...[
                                                      Text(
                                                        ' ➔ ',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: secondaryTextColor,
                                                        ),
                                                      ),
                                                      Text(
                                                        '@${c.replyToName}',
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 12,
                                                          color: primaryColor,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    timeAgo,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: secondaryTextColor,
                                                    ),
                                                  ),
                                                  if (canManage)
                                                    InkWell(
                                                      onTap: () => _showCommentOptions(c),
                                                      child: Padding(
                                                        padding: const EdgeInsets.only(left: 6),
                                                        child: Icon(
                                                          Icons.more_horiz,
                                                          size: 16,
                                                          color: secondaryTextColor,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          if (c.text.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            ExpandableTextWidget(
                                              text: c.text,
                                              maxChars: 85,
                                              style: TextStyle(
                                                fontSize: 14,
                                                height: 1.35,
                                                color: onSurfaceColor,
                                              ),
                                            ),
                                          ],
                                          if (c.imageUrl != null && c.imageUrl!.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(10),
                                              child: buildSmartImage(
                                                c.imageUrl!,
                                                fit: BoxFit.cover,
                                                height: 140,
                                                width: double.infinity,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const SizedBox(width: 4),
                                      InkWell(
                                        onTap: () {
                                          _postService.setCommentReaction(
                                            postId: widget.postId,
                                            commentId: c.commentId,
                                            currentUser: widget.currentUser,
                                            reactionType: cReaction != null ? null : 'like',
                                          );
                                        },
                                        onLongPress: () => _showCommentReactionPicker(c),
                                        borderRadius: BorderRadius.circular(6),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          child: Row(
                                            children: [
                                              if (cReactionInfo != null) ...[
                                                Text(
                                                  cReactionInfo.emoji,
                                                  style: const TextStyle(fontSize: 13),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  cReactionInfo.label,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: cReactionInfo.color,
                                                  ),
                                                ),
                                              ] else ...[
                                                Icon(
                                                  Icons.thumb_up_alt_outlined,
                                                  size: 14,
                                                  color: actionBtnColor,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Thích',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: actionBtnColor,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (c.totalReactions > 0) ...[
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () => _showCommentReactionsUsersSheet(c),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF334155) : Colors.white,
                                              borderRadius: BorderRadius.circular(10),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.08),
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  _getCommentUniqueActiveEmojis(c).join(''),
                                                  style: const TextStyle(fontSize: 11),
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  '${c.totalReactions}',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: onSurfaceColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(width: 16),
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            _replyingToComment = c;
                                            _editingComment = null;
                                          });
                                          _focusNode.requestFocus();
                                        },
                                        borderRadius: BorderRadius.circular(6),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.reply_rounded,
                                                size: 14,
                                                color: actionBtnColor,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Trả lời',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: actionBtnColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),

            // BANNER ĐANG TRẢ LỜI / SỬA BÌNH LUẬN
            if (_replyingToComment != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                color: isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF),
                child: Row(
                  children: [
                    Icon(Icons.reply_rounded, size: 16, color: primaryColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Đang trả lời bình luận của @${_replyingToComment!.authorName}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _replyingToComment = null),
                      child: const Icon(Icons.close_rounded, size: 18),
                    ),
                  ],
                ),
              ),
            ],

            if (_editingComment != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                color: isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7),
                child: Row(
                  children: [
                    const Icon(Icons.edit_rounded, size: 16, color: Colors.amber),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Đang chỉnh sửa bình luận...',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _editingComment = null;
                          _commentController.clear();
                        });
                      },
                      child: const Icon(Icons.close_rounded, size: 18),
                    ),
                  ],
                ),
              ),
            ],

            // HIỂN THỊ ẢNH ĐÍNH KÈM CHUẨN BỊ GỬI
            if (_attachedImageFile != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                color: cardBgColor,
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: buildSmartImage(
                        _attachedImageFile!.path,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ảnh đính kèm: ${_attachedImageFile!.name}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: onSurfaceColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _attachedImageFile = null),
                      child: const Icon(Icons.close_rounded, size: 20, color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
            ],

            // THANH BIỂU CẢM EMOJI CHỌN NHANH
            Container(
              height: 36,
              color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['👍', '❤️', '🥰', '😆', '😲', '🔥'].map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      _commentController.text += emoji;
                      _commentController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _commentController.text.length),
                      );
                    },
                    child: Text(emoji, style: const TextStyle(fontSize: 18)),
                  );
                }).toList(),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.photo_camera_rounded, color: secondaryTextColor),
                      onPressed: _showPickImageSourceSheet,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        focusNode: _focusNode,
                        autofocus: true,
                        style: TextStyle(color: onSurfaceColor),
                        onSubmitted: (_) => _sendComment(),
                        decoration: InputDecoration(
                          hintText: _editingComment != null
                              ? 'Chỉnh sửa nội dung...'
                              : _replyingToComment != null
                                  ? 'Trả lời @${_replyingToComment!.authorName}...'
                                  : 'Viết bình luận công khai...',
                          hintStyle: TextStyle(color: secondaryTextColor),
                          isDense: true,
                          fillColor: cardBgColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _isSending ? null : _sendComment,
                      icon: _isSending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _editingComment != null
                                  ? Icons.check_rounded
                                  : Icons.send_rounded,
                              size: 18,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
