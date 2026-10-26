/// Basic profile information stored for each PetVerse account.
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.bio,
    this.photoUrl,
  });

  final String uid;
  final String displayName;
  final String email;
  final String bio;
  final String? photoUrl;

  factory UserProfile.fromMap(Map<String, dynamic> data) {
    return UserProfile(
      uid: data['uid'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
    );
  }
}
