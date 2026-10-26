import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Result returned after a file finishes uploading to Cloud Storage.
class UploadedMedia {
  /// Creates an upload result.
  const UploadedMedia({
    required this.fileName,
    required this.contentType,
    required this.downloadUrl,
    required this.storagePath,
  });

  /// Original name of the uploaded file.
  final String fileName;

  /// File MIME type.
  final String contentType;

  /// Download URL from Firebase Storage.
  final String downloadUrl;

  /// Storage object path.
  final String storagePath;
}

/// Uploads user selected image and video files to Firebase Storage.
class MediaStorageService {
  MediaStorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  /// Shared media storage service.
  static final MediaStorageService instance = MediaStorageService();

  static const int maxImageBytes = 10 * 1024 * 1024;
  static const int maxVideoBytes = 100 * 1024 * 1024;

  final FirebaseStorage _storage;

  /// Uploads one image or video and reports progress from zero to one.
  Future<UploadedMedia> uploadFile({
    required XFile file,
    required String userId,
    required String folder,
    void Function(double progress)? onProgress,
  }) async {
    final bytes = await file.readAsBytes();
    final contentType = _contentTypeFor(file);
    final isImage = contentType.startsWith('image/');
    final isVideo = contentType.startsWith('video/');

    if (!isImage && !isVideo) {
      throw const FormatException('Solo se permiten imágenes y videos.');
    }
    if (isImage && bytes.length > maxImageBytes) {
      throw const FormatException('Cada imagen debe pesar menos de 10 MB.');
    }
    if (isVideo && bytes.length > maxVideoBytes) {
      throw const FormatException('Cada video debe pesar menos de 100 MB.');
    }

    final safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final fileKey = DateTime.now().microsecondsSinceEpoch.toString();
    final storagePath = 'users/' + userId + '/' + folder + '/' + fileKey + '_' + safeName;
    final reference = _storage.ref().child(storagePath);
    final uploadTask = reference.putData(
      bytes,
      SettableMetadata(contentType: contentType),
    );
    final subscription = uploadTask.snapshotEvents.listen((snapshot) {
      if (snapshot.totalBytes > 0) {
        onProgress?.call(snapshot.bytesTransferred / snapshot.totalBytes);
      }
    });

    try {
      await uploadTask;
      final downloadUrl = await reference.getDownloadURL();
      onProgress?.call(1);
      return UploadedMedia(
        fileName: file.name,
        contentType: contentType,
        downloadUrl: downloadUrl,
        storagePath: storagePath,
      );
    } finally {
      await subscription.cancel();
    }
  }

  /// Removes a previously uploaded file by its Storage path.
  Future<void> deleteFile(String storagePath) {
    return _storage.ref().child(storagePath).delete();
  }

  String _contentTypeFor(XFile file) {
    final providedType = file.mimeType;
    if (providedType != null &&
        (providedType.startsWith('image/') || providedType.startsWith('video/'))) {
      return providedType;
    }

    final extension = file.name.split('.').last.toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'heic' => 'image/heic',
      'mp4' => 'video/mp4',
      'mov' => 'video/quicktime',
      'webm' => 'video/webm',
      'm4v' => 'video/x-m4v',
      _ => 'application/octet-stream',
    };
  }
}
