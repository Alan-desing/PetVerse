import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/adoption_request.dart';
import '../models/pet_profile.dart';

/// Loads public adoption listings and stores private contact requests.
class AdoptionService {
  AdoptionService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static final AdoptionService instance = AdoptionService();

  final FirebaseFirestore _firestore;

  Stream<List<PetProfile>> watchAdoptablePets() {
    return _firestore
        .collectionGroup('pets')
        .where('isForAdoption', isEqualTo: true)
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

  Future<void> sendRequest({
    required PetProfile pet,
    required String requesterId,
    required String requesterName,
    required String requesterEmail,
    required String message,
  }) async {
    final request = _firestore.collection('adoptionRequests').doc();
    final chat = _firestore.collection('chats').doc(request.id);
    final firstMessage = chat.collection('messages').doc();
    final normalizedName = requesterName.trim();
    final normalizedMessage = message.trim();
    final batch = _firestore.batch();

    batch.set(request, {
      'petId': pet.id,
      'petName': pet.name,
      'ownerId': pet.ownerId,
      'requesterId': requesterId,
      'requesterName': normalizedName,
      'requesterEmail': requesterEmail.trim(),
      'message': normalizedMessage,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(chat, {
      'petId': pet.id,
      'petName': pet.name,
      'ownerId': pet.ownerId,
      'requesterName': normalizedName,
      'participantIds': [requesterId, pet.ownerId],
      'lastMessage': normalizedMessage,
      'lastMessageId': firstMessage.id,
      'lastSenderId': requesterId,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(firstMessage, {
      'senderId': requesterId,
      'senderName': normalizedName,
      'text': normalizedMessage,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Stream<List<AdoptionRequest>> watchIncomingRequests(String ownerId) {
    return _firestore
        .collection('adoptionRequests')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map(AdoptionRequest.fromDocument)
              .toList();
          requests.sort((left, right) {
            final leftDate = left.createdAt ?? DateTime(1970);
            final rightDate = right.createdAt ?? DateTime(1970);
            return rightDate.compareTo(leftDate);
          });
          return requests;
        });
  }
}
