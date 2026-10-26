import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_conversation.dart';

/// Streams private conversations and appends messages to their history.
class ChatService {
  ChatService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static final ChatService instance = ChatService();

  final FirebaseFirestore _firestore;

  Stream<List<ChatConversation>> watchConversations(String userId) {
    return _firestore
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final conversations = snapshot.docs
              .map(ChatConversation.fromDocument)
              .toList();
          conversations.sort((left, right) {
            final leftDate = left.lastMessageAt ?? DateTime(1970);
            final rightDate = right.lastMessageAt ?? DateTime(1970);
            return rightDate.compareTo(leftDate);
          });
          return conversations;
        });
  }

  Stream<List<ChatMessage>> watchMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(ChatMessage.fromDocument).toList(),
        );
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) return;

    final chat = _firestore.collection('chats').doc(chatId);
    final message = chat.collection('messages').doc();
    final batch = _firestore.batch();
    batch.update(chat, {
      'lastMessage': normalizedText,
      'lastMessageId': message.id,
      'lastSenderId': senderId,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(message, {
      'senderId': senderId,
      'senderName': senderName.trim(),
      'text': normalizedText,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }
}
