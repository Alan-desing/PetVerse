import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/pet_profile.dart';

/// Reads and writes the pet records owned by each PetVerse user.
class PetService {
  PetService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static final PetService instance = PetService();

  final FirebaseFirestore _firestore;

  String createPetId(String userId) =>
      _firestore.collection('users').doc(userId).collection('pets').doc().id;

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

  Future<void> savePet(PetProfile pet) async {
    final reference = _firestore
        .collection('users')
        .doc(pet.ownerId)
        .collection('pets')
        .doc(pet.id);
    final existingPet = await reference.get();
    final petFields = pet.toFirestore()..remove('ownerId');

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

  Future<void> deletePet(PetProfile pet) {
    return _firestore
        .collection('users')
        .doc(pet.ownerId)
        .collection('pets')
        .doc(pet.id)
        .delete();
  }
}
