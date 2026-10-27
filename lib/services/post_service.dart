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

  /// Publishes a post and records its one-time points award atomically.
  Future<void> createPost({
    required String authorId,
    required String authorName,
    required String? authorPhotoUrl,
    required String caption,
    required String? mediaUrl,
    required String mediaType,
  }) async {
    final post = _posts.doc();
    final activity = _firestore
        .collection('users')
        .doc(authorId)
        .collection('activityEvents')
        .doc('post_${post.id}');
    final batch = _firestore.batch();
    batch.set(post, {
      'authorId': authorId,
      'authorName': authorName.trim(),
      'authorPhotoUrl': authorPhotoUrl,
      'caption': caption.trim(),
      'mediaUrl': mediaUrl,
      'mediaType': mediaUrl == null ? 'none' : mediaType,
      'likeCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(activity, {
      'kind': 'post',
      'targetId': post.id,
      'points': 10,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
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

  /// Adds or removes one like and records its one-time award atomically.
  Future<void> toggleLike({
    required String postId,
    required String userId,
    required String actorName,
  }) async {
    final postReference = _posts.doc(postId);
    final likeReference = postReference.collection('likes').doc(userId);
    final likeEventId = _posts.doc().id;
    final activityReference = _firestore
        .collection('users')
        .doc(userId)
        .collection('activityEvents')
        .doc('like_$postId');

    await _firestore.runTransaction((transaction) async {
      final postSnapshot = await transaction.get(postReference);
      final likeSnapshot = await transaction.get(likeReference);
      if (!postSnapshot.exists) {
        throw StateError('La publicación ya no existe.');
      }

      final postData = postSnapshot.data()!;
      final authorId = postData['authorId'] as String;
      final activitySnapshot = authorId == userId || likeSnapshot.exists
          ? null
          : await transaction.get(activityReference);
      final currentCount = (postData['likeCount'] as num?)?.toInt() ?? 0;

      if (likeSnapshot.exists) {
        transaction.delete(likeReference);
        transaction.update(postReference, {
          'likeCount': currentCount > 0 ? currentCount - 1 : 0,
        });
        return;
      }

      transaction.set(likeReference, {
        'userId': userId,
        'eventId': likeEventId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(postReference, {'likeCount': currentCount + 1});

      if (authorId != userId) {
        if (activitySnapshot?.exists == false) {
          transaction.set(activityReference, {
            'kind': 'like',
            'targetId': postId,
            'points': 2,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        final notification = _firestore
            .collection('users')
            .doc(authorId)
            .collection('notifications')
            .doc('like_$likeEventId');
        transaction.set(notification, {
          'type': 'like',
          'actorId': userId,
          'actorName': actorName.trim(),
          'postId': postId,
          'commentId': null,
          'chatId': null,
          'messageId': null,
          'sourceId': likeEventId,
          'body': 'Le gustó tu publicación.',
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
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

  /// Adds a comment, points, and a private notice as one Firestore batch.
  Future<void> addComment({
    required String postId,
    required String authorId,
    required String authorName,
    required String text,
  }) async {
    final postReference = _posts.doc(postId);
    final postSnapshot = await postReference.get();
    if (!postSnapshot.exists) {
      throw StateError('La publicación ya no existe.');
    }

    final postAuthorId = postSnapshot.data()!['authorId'] as String;
    final comment = postReference.collection('comments').doc();
    final activity = _firestore
        .collection('users')
        .doc(authorId)
        .collection('activityEvents')
        .doc('comment_${comment.id}');
    final batch = _firestore.batch();
    batch.set(comment, {
      'authorId': authorId,
      'authorName': authorName.trim(),
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(activity, {
      'kind': 'comment',
      'targetId': comment.id,
      'postId': postId,
      'points': 3,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (postAuthorId != authorId) {
      final normalizedText = text.trim();
      final preview = normalizedText.length <= 150
          ? normalizedText
          : '${normalizedText.substring(0, 147)}...';
      final notification = _firestore
          .collection('users')
          .doc(postAuthorId)
          .collection('notifications')
          .doc('comment_${comment.id}');
      batch.set(notification, {
        'type': 'comment',
        'actorId': authorId,
        'actorName': authorName.trim(),
        'postId': postId,
        'commentId': comment.id,
        'chatId': null,
        'messageId': null,
        'sourceId': comment.id,
        'body': preview,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    }
    await batch.commit();
  }

  /// Deletes one comment.
  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) {
    return _posts.doc(postId).collection('comments').doc(commentId).delete();
  }
}
