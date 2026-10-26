import 'package:cloud_firestore/cloud_firestore.dart';

/// Information about a pet registered by a PetVerse user.
class PetProfile {
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
    this.location = '',
    this.isForAdoption = false,
  });

  final String id;
  final String ownerId;
  final String name;
  final String type;
  final String breed;
  final int ageYears;
  final double weightKg;
  final String bio;
  final List<String> photoUrls;
  final String location;
  final bool isForAdoption;

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
      location: data['location'] as String? ?? '',
      isForAdoption: data['isForAdoption'] as bool? ?? false,
    );
  }

  Map<String, Object?> toFirestore() => {
    'ownerId': ownerId,
    'name': name.trim(),
    'type': type,
    'breed': breed.trim(),
    'ageYears': ageYears,
    'weightKg': weightKg,
    'bio': bio.trim(),
    'photoUrls': photoUrls,
    'location': location.trim(),
    'isForAdoption': isForAdoption,
  };
}
