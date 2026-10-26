import 'package:cloud_firestore/cloud_firestore.dart';

/// Information about a pet registered by a PetVerse user.
class PetProfile {
  /// Creates a pet profile.
  const PetProfile({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.type,
    required this.breed,
    required this.ageYears,
    required this.weightKg,
    required this.bio,
    required this.photoUrls,
    required this.storagePaths,
  });

  /// Firestore document ID.
  final String id;

  /// ID of the user who owns the pet profile.
  final String ownerId;

  /// Pet's name.
  final String name;

  /// Pet type, stored as dog or cat.
  final String type;

  /// Breed, or an empty value when it is unknown or mixed.
  final String breed;

  /// Age in years.
  final int ageYears;

  /// Weight in kilograms.
  final double weightKg;

  /// Short description of the pet.
  final String bio;

  /// Download URLs for the pet's photos.
  final List<String> photoUrls;

  /// Storage paths used to remove the pet's photos later.
  final List<String> storagePaths;

  /// Creates a pet profile from a Firestore document.
  factory PetProfile.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return PetProfile(
      id: document.id,
      ownerId: data['ownerId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      type: data['type'] as String? ?? 'dog',
      breed: data['breed'] as String? ?? '',
      ageYears: (data['ageYears'] as num?)?.toInt() ?? 0,
      weightKg: (data['weightKg'] as num?)?.toDouble() ?? 0,
      bio: data['bio'] as String? ?? '',
      photoUrls: List<String>.from(data['photoUrls'] as List? ?? const []),
      storagePaths: List<String>.from(
        data['storagePaths'] as List? ?? const [],
      ),
    );
  }

  /// Fields shared by pet creation and editing.
  Map<String, Object?> toFirestore() => {
    'ownerId': ownerId,
    'name': name.trim(),
    'type': type,
    'breed': breed.trim(),
    'ageYears': ageYears,
    'weightKg': weightKg,
    'bio': bio.trim(),
    'photoUrls': photoUrls,
    'storagePaths': storagePaths,
  };
}
