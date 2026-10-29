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
    return UserModel(
      uid: documentId,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      bio: map['bio'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      coverUrl: map['coverUrl'] ?? '',
      friendIds: List<String>.from(map['friendIds'] ?? []),
    );
  }
}
