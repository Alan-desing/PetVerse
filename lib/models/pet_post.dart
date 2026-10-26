import 'package:cloud_firestore/cloud_firestore.dart';

/// A public post in the PetVerse feed.
class PetPost {
  const PetPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.caption,
    required this.mediaType,
    required this.likeCount,
    required this.createdAt,
    this.authorPhotoUrl,
    this.mediaUrl,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String caption;
  final String? mediaUrl;
  final String mediaType;
  final int likeCount;
  final DateTime createdAt;

  factory PetPost.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final createdAt = data['createdAt'];
    return PetPost(
      id: document.id,
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'Usuario de PetVerse',
      authorPhotoUrl: data['authorPhotoUrl'] as String?,
      caption: data['caption'] as String? ?? '',
      mediaUrl: data['mediaUrl'] as String?,
      mediaType: data['mediaType'] as String? ?? 'none',
      likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
    );
  }
}
