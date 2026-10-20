import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';

/// Reads and updates the signed-in user's Firestore profile document.
class UserProfileService {
  UserProfileService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Shared profile service used by the application.
  static final UserProfileService instance = UserProfileService();

  final FirebaseFirestore _firestore;

  /// Returns the user's profile, creating a basic document if needed.
  Future<UserProfile> getOrCreateProfile(
    User user, {
    String? fallbackName,
  }) async {
    final profileReference = _firestore.collection('users').doc(user.uid);
    final profileSnapshot = await profileReference.get();

    if (profileSnapshot.exists) {
      return UserProfile.fromMap(profileSnapshot.data()!);
    }

    final defaultName = user.email?.split('@').first ?? '';
    final displayName = [
      user.displayName?.trim() ?? '',
      fallbackName?.trim() ?? '',
      defaultName,
      'Amigo de PetVerse',
    ].firstWhere((name) => name.isNotEmpty);
    await profileReference.set({
      'uid': user.uid,
      'displayName': displayName,
      'email': user.email ?? '',
      'bio': '',
      'photoUrl': user.photoURL,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final createdSnapshot = await profileReference.get();
    return UserProfile.fromMap(createdSnapshot.data()!);
  }

  /// Saves the editable name and biography for a user's profile.
  Future<UserProfile> updateProfile({
    required User user,
    required String displayName,
    required String bio,
  }) async {
    final normalizedName = displayName.trim();
    final profileReference = _firestore.collection('users').doc(user.uid);
    final existingProfile = await profileReference.get();

    if (!existingProfile.exists) {
      await getOrCreateProfile(user, fallbackName: normalizedName);
    }

    await profileReference.set({
      'uid': user.uid,
      'displayName': normalizedName,
      'email': user.email ?? '',
      'bio': bio.trim(),
      'photoUrl': user.photoURL,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await user.updateDisplayName(normalizedName);

    final updatedSnapshot = await profileReference.get();
    return UserProfile.fromMap(updatedSnapshot.data()!);
  }
}
