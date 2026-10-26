import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_media.dart';
import '../services/media_storage_service.dart';
import '../services/user_media_service.dart';
import '../theme/app_theme.dart';

/// Uploads and displays images or videos from the user's device.
class MediaSection extends StatefulWidget {
  /// Creates the media library for [userId].
  const MediaSection({required this.userId, super.key});

  /// Firebase user ID that owns the uploaded files.
  final String userId;

  @override
  State<MediaSection> createState() => _MediaSectionState();
}

class _MediaSectionState extends State<MediaSection> {
  final _picker = ImagePicker();
  bool _isUploading = false;
  double _progress = 0;
  String? _uploadError;

  Future<void> _pickAndUpload() async {
    UploadedMedia? uploaded;
    var metadataSaved = false;
    try {
      final file = await _picker.pickMedia();
      if (file == null || !mounted) return;

      setState(() {
        _isUploading = true;
        _progress = 0;
        _uploadError = null;
      });

      uploaded = await MediaStorageService.instance.uploadFile(
        file: file,
        userId: widget.userId,
        folder: 'media',
        onProgress: (progress) {
          if (mounted) setState(() => _progress = progress);
        },
      );
      await UserMediaService.instance.addMedia(
        userId: widget.userId,
        uploadedMedia: uploaded,
      );
      metadataSaved = true;
    } on FormatException catch (error) {
      if (mounted) setState(() => _uploadError = error.message.toString());
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() {
        _uploadError = error.code == 'permission-denied'
            ? 'Firebase rechazó el archivo. Revisa las reglas publicadas.'
            : 'Firebase Storage no está disponible o todavía no tiene un bucket.';
      });
    } catch (_) {
      if (mounted) {
        setState(() => _uploadError = 'No pudimos subir el archivo. Inténtalo otra vez.');
      }
    } finally {
      if (!metadataSaved && uploaded != null) {
        try {
          await MediaStorageService.instance.deleteFile(uploaded.storagePath);
        } on FirebaseException {
          // Preserve the original upload or metadata error.
        }
      }
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteMedia(UserMedia media) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar archivo'),
        content: Text('¿Quieres eliminar ' + media.fileName + '?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB3261E)),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;
    try {
      await UserMediaService.instance.deleteMedia(
        userId: widget.userId,
        media: media,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pudimos eliminar el archivo.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF0EEEB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fotos y videos',
                      style: TextStyle(
                        color: AppTheme.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text('Archivos subidos desde tu dispositivo.'),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _isUploading ? null : _pickAndUpload,
                icon: const Icon(Icons.upload_rounded),
                label: const Text('Subir'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          if (_isUploading) ...[
            const SizedBox(height: 18),
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 6),
            Text(
              'Subiendo: ' + (_progress * 100).round().toString() + '%',
              textAlign: TextAlign.center,
            ),
          ],
          if (_uploadError != null) ...[
            const SizedBox(height: 12),
            Text(
              _uploadError!,
              style: const TextStyle(color: Color(0xFFB3261E)),
            ),
          ],
          const SizedBox(height: 18),
          StreamBuilder<List<UserMedia>>(
            stream: UserMediaService.instance.watchMedia(widget.userId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('No pudimos cargar tus archivos.');
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final media = snapshot.data ?? const <UserMedia>[];
              if (media.isEmpty) {
                return const Text(
                  'Todavía no subiste fotos ni videos.',
                  style: TextStyle(color: Color(0xFF657279)),
                );
              }

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final item in media)
                    _MediaTile(
                      media: item,
                      onDelete: () => _deleteMedia(item),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({required this.media, required this.onDelete});

  final UserMedia media;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF0EEEB)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 96,
              child: media.isVideo
                  ? const ColoredBox(
                      color: Color(0xFFFFE0D2),
                      child: Icon(
                        Icons.play_circle_outline_rounded,
                        size: 40,
                        color: AppTheme.orange,
                      ),
                    )
                  : Image.network(
                      media.downloadUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: Color(0xFFFFE0D2),
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 2, top: 6, bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      media.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Eliminar archivo',
                    onPressed: onDelete,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
