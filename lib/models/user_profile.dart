/// Basic profile information stored for each PetVerse account.
class UserProfile {
  /// Creates a profile value.
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.bio,
    this.photoUrl,
    this.photoStoragePath,
  });

  /// Firebase Authentication user ID and Firestore document ID.
  final String uid;

  /// Name shown to other PetVerse users.
  final String displayName;

  /// Account email address.
  final String email;

  /// Short profile description.
  final String bio;

  /// Optional URL for the profile photo.
  final String? photoUrl;

  /// Storage path of the profile photo, used to replace or remove it.
  final String? photoStoragePath;

  /// Builds a profile from a Firestore document map.
  factory UserProfile.fromMap(Map<String, dynamic> data) {
    return UserProfile(
      uid: data['uid'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      photoStoragePath: data['photoStoragePath'] as String?,
    );
  }
}
