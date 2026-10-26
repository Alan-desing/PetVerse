import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/post_comment.dart';
import '../models/pet_post.dart';

/// Creates feed posts and provides real-time posts, likes, and comments.
class PostService {
  PostService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static final PostService instance = PostService();

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection('posts');

  /// Streams all posts, newest first.
  Stream<List<PetPost>> watchFeed() {
    return _posts
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(PetPost.fromDocument).toList());
  }

  /// Publishes a post with an optional direct image or video URL.
  Future<void> createPost({
    required String authorId,
    required String authorName,
    required String? authorPhotoUrl,
    required String caption,
    required String? mediaUrl,
    required String mediaType,
  }) async {
    await _posts.add({
      'authorId': authorId,
      'authorName': authorName.trim(),
      'authorPhotoUrl': authorPhotoUrl,
      'caption': caption.trim(),
      'mediaUrl': mediaUrl,
      'mediaType': mediaUrl == null ? 'none' : mediaType,
      'likeCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Streams whether [userId] has liked [postId].
  Stream<bool> watchLikedBy(String postId, String userId) {
    return _posts
        .doc(postId)
        .collection('likes')
        .doc(userId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  /// Adds or removes one like and updates its count atomically.
  Future<void> toggleLike({
    required String postId,
    required String userId,
  }) async {
    final postReference = _posts.doc(postId);
    final likeReference = postReference.collection('likes').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final postSnapshot = await transaction.get(postReference);
      final likeSnapshot = await transaction.get(likeReference);
      if (!postSnapshot.exists) {
        throw StateError('La publicación ya no existe.');
      }

      final currentCount =
          (postSnapshot.data()?['likeCount'] as num?)?.toInt() ?? 0;
      if (likeSnapshot.exists) {
        transaction.delete(likeReference);
        transaction.update(postReference, {'likeCount': currentCount - 1});
      } else {
        transaction.set(likeReference, {
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.update(postReference, {'likeCount': currentCount + 1});
      }
    });
  }

  /// Streams a post's comments in chronological order.
  Stream<List<PostComment>> watchComments(String postId) {
    return _posts
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(PostComment.fromDocument).toList(),
        );
  }

  /// Adds a comment to a post.
  Future<void> addComment({
    required String postId,
    required String authorId,
    required String authorName,
    required String text,
  }) async {
    await _posts.doc(postId).collection('comments').add({
      'authorId': authorId,
      'authorName': authorName.trim(),
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Deletes one comment.
  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) {
    return _posts.doc(postId).collection('comments').doc(commentId).delete();
  }
}
