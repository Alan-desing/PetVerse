import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/pet_profile.dart';

/// Reads and writes the pet records owned by each PetVerse user.
class PetService {
  PetService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  /// Shared pet service.
  static final PetService instance = PetService();

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  /// Creates a unique document ID for a new pet.
  String createPetId(String userId) => _firestore
      .collection('users')
      .doc(userId)
      .collection('pets')
      .doc()
      .id;

  /// Streams all pets owned by [userId].
  Stream<List<PetProfile>> watchPets(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('pets')
        .snapshots()
        .map((snapshot) {
          final pets = snapshot.docs.map(PetProfile.fromDocument).toList();
          pets.sort(
            (left, right) =>
                left.name.toLowerCase().compareTo(right.name.toLowerCase()),
          );
          return pets;
        });
  }

  /// Creates or updates a pet profile.
  Future<void> savePet(PetProfile pet) async {
    final reference = _firestore
        .collection('users')
        .doc(pet.ownerId)
        .collection('pets')
        .doc(pet.id);
    final existingPet = await reference.get();
    final petFields = pet.toFirestore()
      ..remove('ownerId');

    if (existingPet.exists) {
      await reference.update({
        ...petFields,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await reference.set({
        ...pet.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Deletes a pet and its uploaded photos.
  Future<void> deletePet(PetProfile pet) async {
    for (final storagePath in pet.storagePaths) {
      try {
        await _storage.ref().child(storagePath).delete();
      } on FirebaseException catch (error) {
        if (error.code != 'object-not-found' &&
            error.code != 'bucket-not-found') {
          rethrow;
        }
      }
    }

    await _firestore
        .collection('users')
        .doc(pet.ownerId)
        .collection('pets')
        .doc(pet.id)
        .delete();
  }
}
