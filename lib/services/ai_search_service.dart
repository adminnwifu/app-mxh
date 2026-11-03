import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';

class AiSearchResult {
  final List<UserModel> matchedUsers;
  final List<PostModel> matchedPosts;
  final String aiSummary;
  final List<String> searchTags;

  AiSearchResult({
    required this.matchedUsers,
    required this.matchedPosts,
    required this.aiSummary,
    required this.searchTags,
  });
}

class AiSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Tìm kiếm thông minh bằng AI cho Bài viết và Người dùng
  Future<AiSearchResult> searchWithAi({
    required String query,
    required String currentUserId,
    required List<String> currentUserFriendIds,
  }) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      return AiSearchResult(
        matchedUsers: [],
        matchedPosts: [],
        aiSummary: 'Nhập từ khóa hoặc câu hỏi để AI tìm kiếm cho bạn.',
        searchTags: ['#Flutter', '#LậpTrình', '#CôngNghệ', '#BạnBè', '#NổiBật'],
      );
    }

    // 1. TẢI DỮ LIỆU TỪ FIRESTORE
    final usersSnapshot = await _firestore.collection('users').get();
    final postsSnapshot = await _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .get();

    final allUsers = usersSnapshot.docs.map((doc) {
      return UserModel.fromMap(doc.data(), doc.id);
    }).toList();

    final allPosts = postsSnapshot.docs.map((doc) {
      return PostModel.fromMap(doc.data(), doc.id);
    }).toList();

    // 2. AI SEMANTIC MATCHING & INTENT PARSING (Phân tích ngữ nghĩa từ khóa)
    final queryTokens = cleanQuery.split(' ').where((t) => t.isNotEmpty).toList();

    // Intent Flags
    final isLookingForPopular = cleanQuery.contains('nổi bật') ||
        cleanQuery.contains('hot') ||
        cleanQuery.contains('nhiều like') ||
        cleanQuery.contains('thích');

    final isLookingForRecent = cleanQuery.contains('mới') ||
        cleanQuery.contains('vừa') ||
        cleanQuery.contains('hôm nay');

    final isLookingForFriends = cleanQuery.contains('bạn') ||
        cleanQuery.contains('kết bạn') ||
        cleanQuery.contains('người');

    // 3. TÌM KIẾM & XẾP HẠNG NGƯỜI DÙNG (User Scoring)
    final List<MapEntry<UserModel, double>> scoredUsers = [];
    for (var user in allUsers) {
      if (user.uid == currentUserId) continue; // Bỏ qua chính mình

      double score = 0.0;
      final name = user.displayName.toLowerCase();
      final email = user.email.toLowerCase();
      final bio = user.bio.toLowerCase();

      if (name == cleanQuery) score += 10.0;
      if (name.contains(cleanQuery)) score += 5.0;
      if (email.contains(cleanQuery)) score += 4.0;
      if (bio.contains(cleanQuery)) score += 3.0;

      for (var token in queryTokens) {
        if (name.contains(token)) score += 2.0;
        if (bio.contains(token)) score += 1.0;
      }

      // Điểm thưởng nếu đã là bạn bè
      if (currentUserFriendIds.contains(user.uid)) {
        score += 1.5;
      }

      if (score > 0) {
        scoredUsers.add(MapEntry(user, score));
      }
    }

    scoredUsers.sort((a, b) => b.value.compareTo(a.value));
    final matchedUsers = scoredUsers.map((e) => e.key).toList();

    // 4. TÌM KIẾM & XẾP HẠNG BÀI VIẾT (Post Scoring & Privacy Filtering)
    final List<MapEntry<PostModel, double>> scoredPosts = [];
    for (var post in allPosts) {
      // Lọc quy tắc quyền riêng tư (Privacy Filtering)
      if (post.authorId != currentUserId) {
        if (post.visibility == 'private') continue;
        if (post.visibility == 'friends' &&
            !currentUserFriendIds.contains(post.authorId)) {
          continue;
        }
      }

      double score = 0.0;
      final content = post.content.toLowerCase();
      final authorName = post.authorName.toLowerCase();

      if (content.contains(cleanQuery)) score += 6.0;
      if (authorName.contains(cleanQuery)) score += 4.0;

      for (var token in queryTokens) {
        if (content.contains(token)) score += 2.0;
        if (authorName.contains(token)) score += 1.5;
      }

      // Xếp hạng bài viết nổi bật nếu có ý định tìm bài hot
      if (isLookingForPopular) {
        score += (post.likes.length * 2.0) + (post.commentCount * 1.5);
      }

      // Xếp hạng theo thời gian nếu có ý định tìm bài mới
      if (isLookingForRecent) {
        final hoursAgo = DateTime.now().difference(post.createdAt).inHours;
        if (hoursAgo < 24) score += 3.0;
      }

      if (score > 0) {
        scoredPosts.add(MapEntry(post, score));
      }
    }

    scoredPosts.sort((a, b) => b.value.compareTo(a.value));
    final matchedPosts = scoredPosts.map((e) => e.key).toList();

    // 5. TẠO AI SUMMARY INSIGHT
    String summary = '';
    if (matchedUsers.isEmpty && matchedPosts.isEmpty) {
      summary =
          '🤖 AI không tìm thấy kết quả trực tiếp cho "$query". Bạn hãy thử các từ khóa ngắn hơn hoặc kiểm tra lại lỗi chính tả nhé!';
    } else {
      final userText = matchedUsers.isNotEmpty
          ? '${matchedUsers.length} người dùng'
          : '';
      final postText = matchedPosts.isNotEmpty
          ? '${matchedPosts.length} bài viết phù hợp'
          : '';
      final combined = [userText, postText].where((s) => s.isNotEmpty).join(' và ');

      if (isLookingForPopular) {
        summary =
            '🤖 AI đã phân tích và sắp xếp các bài viết có lượt tương tác (Thích & Bình luận) cao nhất liên quan đến "$query".';
      } else if (isLookingForRecent) {
        summary =
            '🤖 AI đã ưu tiên hiển thị những nội dung và bài viết mới nhất cho "$query".';
      } else if (isLookingForFriends) {
        summary =
            '🤖 AI gợi ý $combined dựa trên mức độ liên quan và danh bạ kết nối của bạn.';
      } else {
        summary =
            '🤖 AI đã phân tích ngữ nghĩa và tìm thấy $combined cho từ khóa "$query".';
      }
    }

    return AiSearchResult(
      matchedUsers: matchedUsers,
      matchedPosts: matchedPosts,
      aiSummary: summary,
      searchTags: [
        '#$cleanQuery',
        '#MớiNhất',
        '#NổiBật',
        '#BạnBè',
      ],
    );
  }
}
