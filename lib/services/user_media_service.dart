import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_media.dart';
import 'media_storage_service.dart';

/// Stores and lists a user's uploaded image and video library.
class UserMediaService {
  UserMediaService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Shared user media service.
  static final UserMediaService instance = UserMediaService();

  final FirebaseFirestore _firestore;

  /// Streams media files owned by [userId].
  Stream<List<UserMedia>> watchMedia(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('media')
        .snapshots()
        .map((snapshot) {
          final media = snapshot.docs
              .map((document) => UserMedia.fromMap(document.id, document.data()))
              .toList();
          media.sort(
            (left, right) => left.fileName
                .toLowerCase()
                .compareTo(right.fileName.toLowerCase()),
          );
          return media;
        });
  }

  /// Saves metadata for a file uploaded to Firebase Storage.
  Future<void> addMedia({
    required String userId,
    required UploadedMedia uploadedMedia,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('media')
        .add({
          'fileName': uploadedMedia.fileName,
          'contentType': uploadedMedia.contentType,
          'downloadUrl': uploadedMedia.downloadUrl,
          'storagePath': uploadedMedia.storagePath,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  /// Deletes a media file and its Firestore metadata.
  Future<void> deleteMedia({
    required String userId,
    required UserMedia media,
  }) async {
    await MediaStorageService.instance.deleteFile(media.storagePath);
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('media')
        .doc(media.id)
        .delete();
  }
}
