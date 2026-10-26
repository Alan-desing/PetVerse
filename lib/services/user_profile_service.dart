import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';

/// Reads and updates the signed-in user's Firestore profile document.
class UserProfileService {
  UserProfileService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static final UserProfileService instance = UserProfileService();

  final FirebaseFirestore _firestore;

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

  Future<UserProfile> updateProfile({
    required User user,
    required String displayName,
    required String bio,
    required String? photoUrl,
  }) async {
    final normalizedName = displayName.trim();
    await getOrCreateProfile(user, fallbackName: normalizedName);
    final normalizedPhotoUrl = photoUrl?.trim();
    final profileReference = _firestore.collection('users').doc(user.uid);

    await profileReference.set({
      'uid': user.uid,
      'displayName': normalizedName,
      'email': user.email ?? '',
      'bio': bio.trim(),
      'photoUrl': normalizedPhotoUrl == null || normalizedPhotoUrl.isEmpty
          ? null
          : normalizedPhotoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    try {
      await user.updateDisplayName(normalizedName);
      await user.updatePhotoURL(
        normalizedPhotoUrl == null || normalizedPhotoUrl.isEmpty
            ? null
            : normalizedPhotoUrl,
      );
    } on FirebaseAuthException {
      // Firestore remains the source of truth for the PetVerse profile.
    }

    final updatedSnapshot = await profileReference.get();
    return UserProfile.fromMap(updatedSnapshot.data()!);
  }
}
