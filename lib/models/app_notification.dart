import 'package:cloud_firestore/cloud_firestore.dart';

/// A private activity notice shown to its recipient.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.actorName,
    required this.body,
    required this.isRead,
    this.postId,
    this.commentId,
    this.chatId,
    this.messageId,
    this.sourceId,
    this.createdAt,
  });

  final String id;
  final String type;
  final String actorName;
  final String body;
  final bool isRead;
  final String? postId;
  final String? commentId;
  final String? chatId;
  final String? messageId;
  final String? sourceId;
  final DateTime? createdAt;

  /// Builds a notice from a Firestore document.
  factory AppNotification.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final timestamp = data['createdAt'];
    return AppNotification(
      id: document.id,
      type: data['type'] as String? ?? 'activity',
      actorName: data['actorName'] as String? ?? 'Alguien',
      body: data['body'] as String? ?? '',
      isRead: data['isRead'] as bool? ?? false,
      postId: data['postId'] as String?,
      commentId: data['commentId'] as String?,
      chatId: data['chatId'] as String?,
      messageId: data['messageId'] as String?,
      sourceId: data['sourceId'] as String?,
      createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }
}
