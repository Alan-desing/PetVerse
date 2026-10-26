import 'package:cloud_firestore/cloud_firestore.dart';

/// A private one-to-one conversation associated with an adoption listing.
class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.petId,
    required this.petName,
    required this.ownerId,
    required this.requesterName,
    required this.participantIds,
    required this.lastMessage,
    required this.lastSenderId,
    required this.lastMessageAt,
  });

  final String id;
  final String petId;
  final String petName;
  final String ownerId;
  final String requesterName;
  final List<String> participantIds;
  final String lastMessage;
  final String lastSenderId;
  final DateTime? lastMessageAt;

  factory ChatConversation.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final timestamp = data['lastMessageAt'];
    return ChatConversation(
      id: document.id,
      petId: data['petId'] as String? ?? '',
      petName: data['petName'] as String? ?? 'Mascota',
      ownerId: data['ownerId'] as String? ?? '',
      requesterName: data['requesterName'] as String? ?? 'Interesado',
      participantIds: List<String>.from(
        data['participantIds'] as List? ?? const [],
      ),
      lastMessage: data['lastMessage'] as String? ?? '',
      lastSenderId: data['lastSenderId'] as String? ?? '',
      lastMessageAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }
}

/// One immutable message in a chat history.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime? createdAt;

  factory ChatMessage.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final timestamp = data['createdAt'];
    return ChatMessage(
      id: document.id,
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? 'Usuario',
      text: data['text'] as String? ?? '',
      createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }
}
