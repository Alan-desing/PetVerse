/// Basic profile information stored for each PetVerse account.
class UserProfile {
  /// Creates a profile value.
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.bio,
    this.photoUrl,
  });

  /// Firebase Authentication user ID and Firestore document ID.
  final String uid;

  /// Name shown to other PetVerse users.
  final String displayName;

  /// Account email address.
  final String email;

  /// Short profile description.
  final String bio;

  /// Optional profile photo URL, to be used in a later image upload block.
  final String? photoUrl;

  /// Builds a profile from a Firestore document map.
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
