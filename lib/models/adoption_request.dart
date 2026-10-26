import 'package:cloud_firestore/cloud_firestore.dart';

/// A private message sent by a prospective adopter to a pet's owner.
class AdoptionRequest {
  const AdoptionRequest({
    required this.id,
    required this.petId,
    required this.petName,
    required this.ownerId,
    required this.requesterId,
    required this.requesterName,
    required this.requesterEmail,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String petId;
  final String petName;
  final String ownerId;
  final String requesterId;
  final String requesterName;
  final String requesterEmail;
  final String message;
  final DateTime? createdAt;

  factory AdoptionRequest.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final timestamp = data['createdAt'];
    return AdoptionRequest(
      id: document.id,
      petId: data['petId'] as String? ?? '',
      petName: data['petName'] as String? ?? '',
      ownerId: data['ownerId'] as String? ?? '',
      requesterId: data['requesterId'] as String? ?? '',
      requesterName: data['requesterName'] as String? ?? '',
      requesterEmail: data['requesterEmail'] as String? ?? '',
      message: data['message'] as String? ?? '',
      createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }
}
