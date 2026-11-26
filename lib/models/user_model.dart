class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String bio;
  final String avatarUrl;
  final String coverUrl;
  final List<String> friendIds;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.bio = '',
    this.avatarUrl = '',
    this.coverUrl = '',
    this.friendIds = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'coverUrl': coverUrl,
      'friendIds': friendIds,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    try {
      List<String> friends = [];
      if (map['friendIds'] is List) {
        friends = (map['friendIds'] as List).map((e) => e.toString()).toList();
      }

      return UserModel(
        uid: documentId,
        email: map['email']?.toString() ?? '',
        displayName: map['displayName']?.toString() ?? 'Người dùng',
        bio: map['bio']?.toString() ?? '',
        avatarUrl: map['avatarUrl']?.toString() ?? '',
        coverUrl: map['coverUrl']?.toString() ?? '',
        friendIds: friends,
      );
    } catch (e) {
      return UserModel(
        uid: documentId,
        email: map['email']?.toString() ?? '',
        displayName: map['displayName']?.toString() ?? 'Người dùng',
        bio: map['bio']?.toString() ?? '',
        avatarUrl: map['avatarUrl']?.toString() ?? '',
        coverUrl: map['coverUrl']?.toString() ?? '',
        friendIds: [],
      );
    }
  }
}
