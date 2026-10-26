import 'package:flutter/material.dart';

/// Values returned by the post composer dialog.
class PostDraft {
  const PostDraft({
    required this.caption,
    required this.mediaUrl,
    required this.mediaType,
  });

  final String caption;
  final String? mediaUrl;
  final String mediaType;
}

/// Collects a caption and an optional public image or video URL.
class PostComposerDialog extends StatefulWidget {
  const PostComposerDialog({super.key});

  @override
  State<PostComposerDialog> createState() => _PostComposerDialogState();
}

class _PostComposerDialogState extends State<PostComposerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _captionController = TextEditingController();
  final _mediaUrlController = TextEditingController();
  String _mediaType = 'image';

  @override
  void dispose() {
    _captionController.dispose();
    _mediaUrlController.dispose();
    super.dispose();
  }

  String? _validateMediaUrl(String? value) {
    final url = value?.trim() ?? '';
    if (url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasAuthority || uri.scheme != 'https') {
      return 'Pega un enlace web válido.';
    }
    return null;
  }

  void _publish() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final mediaUrl = _mediaUrlController.text.trim();
    Navigator.of(context).pop(
      PostDraft(
        caption: _captionController.text.trim(),
        mediaUrl: mediaUrl.isEmpty ? null : mediaUrl,
        mediaType: mediaUrl.isEmpty ? 'none' : _mediaType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear publicación'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _captionController,
                  autofocus: true,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: '¿Qué quieres compartir?',
                    hintText: 'Cuéntale algo a la comunidad...',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Escribe un texto para tu publicación.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _mediaType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de enlace',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'image', child: Text('Imagen')),
                    DropdownMenuItem(value: 'video', child: Text('Video')),
                  ],
                  onChanged: (value) =>
                      setState(() => _mediaType = value ?? 'image'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _mediaUrlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Enlace público de imagen o video (opcional)',
                    hintText: 'https://sitio.com/archivo.jpg',
                    helperText: 'Usa el enlace directo al archivo. No se suben archivos desde el dispositivo.',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                  validator: _validateMediaUrl,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _publish,
          icon: const Icon(Icons.send_rounded),
          label: const Text('Publicar'),
        ),
      ],
    );
  }
}
