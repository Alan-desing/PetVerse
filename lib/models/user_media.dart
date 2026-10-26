/// A photo or video uploaded to a user's PetVerse media library.
class UserMedia {
  /// Creates a media library item.
  const UserMedia({
    required this.id,
    required this.fileName,
    required this.contentType,
    required this.downloadUrl,
    required this.storagePath,
  });

  /// Firestore document ID.
  final String id;

  /// Original name of the uploaded file.
  final String fileName;

  /// File MIME type.
  final String contentType;

  /// Download URL from Firebase Storage.
  final String downloadUrl;

  /// Storage object path, used to remove the file.
  final String storagePath;

  /// Whether this item is a video.
  bool get isVideo => contentType.startsWith('video/');

  /// Creates a media item from Firestore data.
  factory UserMedia.fromMap(String id, Map<String, dynamic> data) {
    return UserMedia(
      id: id,
      fileName: data['fileName'] as String? ?? 'archivo',
      contentType: data['contentType'] as String? ?? 'application/octet-stream',
      downloadUrl: data['downloadUrl'] as String? ?? '',
      storagePath: data['storagePath'] as String? ?? '',
    );
  }
}
