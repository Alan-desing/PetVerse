import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/pet_profile.dart';
import '../services/media_storage_service.dart';
import '../services/pet_service.dart';
import '../theme/app_theme.dart';

/// Dialog used to create or edit a pet profile.
class PetFormDialog extends StatefulWidget {
  /// Creates the pet form for [ownerId].
  const PetFormDialog({
    required this.ownerId,
    this.pet,
    super.key,
  });

  /// Firebase user ID that owns the pet.
  final String ownerId;

  /// Existing pet when editing.
  final PetProfile? pet;

  @override
  State<PetFormDialog> createState() => _PetFormDialogState();
}

class _PetFormDialogState extends State<PetFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _bioController = TextEditingController();
  final _picker = ImagePicker();

  late String _type;
  late List<String> _photoUrls;
  late List<String> _storagePaths;
  final List<XFile> _newPhotos = [];
  bool _isSaving = false;
  double _uploadProgress = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final pet = widget.pet;
    _type = pet?.type ?? 'dog';
    _nameController.text = pet?.name ?? '';
    _breedController.text = pet?.breed ?? '';
    _ageController.text = pet?.ageYears.toString() ?? '';
    _weightController.text = pet?.weightKg.toString() ?? '';
    _bioController.text = pet?.bio ?? '';
    _photoUrls = List<String>.from(pet?.photoUrls ?? const []);
    _storagePaths = List<String>.from(pet?.storagePaths ?? const []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    try {
      final selected = await _picker.pickMultiImage(imageQuality: 85);
      if (selected.isEmpty || !mounted) return;

      final remaining = 6 - _photoUrls.length - _newPhotos.length;
      if (selected.length > remaining) {
        _showMessage('Puedes guardar hasta 6 fotos por mascota.');
        return;
      }

      setState(() {
        _newPhotos.addAll(selected);
        _errorMessage = null;
      });
    } catch (_) {
      if (mounted) _showMessage('No pudimos abrir tus fotos.');
    }
  }

  void _removeExistingPhoto(int index) {
    setState(() {
      _photoUrls.removeAt(index);
      if (index < _storagePaths.length) _storagePaths.removeAt(index);
    });
  }

  void _removeNewPhoto(int index) {
    setState(() => _newPhotos.removeAt(index));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _savePet() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_photoUrls.isEmpty && _newPhotos.isEmpty) {
      setState(() => _errorMessage = 'Agrega al menos una foto de tu mascota.');
      return;
    }

    setState(() {
      _isSaving = true;
      _uploadProgress = 0;
      _errorMessage = null;
    });

    final petId =
        widget.pet?.id ?? PetService.instance.createPetId(widget.ownerId);
    final uploadedPhotos = <UploadedMedia>[];
    var petSaved = false;

    try {
      for (var index = 0; index < _newPhotos.length; index++) {
        final uploaded = await MediaStorageService.instance.uploadFile(
          file: _newPhotos[index],
          userId: widget.ownerId,
          folder: 'pets/' + petId,
          onProgress: (progress) {
            if (mounted) {
              setState(() {
                _uploadProgress = (index + progress) / _newPhotos.length;
              });
            }
          },
        );
        uploadedPhotos.add(uploaded);
      }

      final pet = PetProfile(
        id: petId,
        ownerId: widget.ownerId,
        name: _nameController.text.trim(),
        type: _type,
        breed: _breedController.text.trim(),
        ageYears: int.parse(_ageController.text),
        weightKg: double.parse(_weightController.text.replaceAll(',', '.')),
        bio: _bioController.text.trim(),
        photoUrls: [
          ..._photoUrls,
          ...uploadedPhotos.map((photo) => photo.downloadUrl),
        ],
        storagePaths: [
          ..._storagePaths,
          ...uploadedPhotos.map((photo) => photo.storagePath),
        ],
      );
      await PetService.instance.savePet(pet);
      petSaved = true;

      final previousPaths = widget.pet?.storagePaths ?? const <String>[];
      for (final oldPath in previousPaths) {
        if (!_storagePaths.contains(oldPath)) {
          try {
            await MediaStorageService.instance.deleteFile(oldPath);
          } on FirebaseException {
            // The saved profile no longer points to this file.
          }
        }
      }

      if (mounted) Navigator.of(context).pop(true);
    } on FormatException catch (error) {
      if (!petSaved) await _cleanupUploadedPhotos(uploadedPhotos);
      if (mounted) setState(() => _errorMessage = error.message.toString());
    } on FirebaseException catch (error) {
      if (!petSaved) await _cleanupUploadedPhotos(uploadedPhotos);
      if (mounted) {
        setState(() {
          _errorMessage = error.code == 'permission-denied'
              ? 'Firebase rechazó la operación. Publica las reglas actualizadas.'
              : 'Storage no está disponible. Comprueba que esté habilitado en Firebase.';
        });
      }
    } catch (_) {
      if (!petSaved) await _cleanupUploadedPhotos(uploadedPhotos);
      if (mounted) {
        setState(
          () => _errorMessage = 'No pudimos guardar la mascota. Inténtalo otra vez.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _cleanupUploadedPhotos(List<UploadedMedia> photos) async {
    for (final photo in photos) {
      try {
        await MediaStorageService.instance.deleteFile(photo.storagePath);
      } on FirebaseException {
        // Preserve the original save error.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.pet != null;

    return AlertDialog(
      title: Text(isEditing ? 'Editar mascota' : 'Agregar mascota'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Por ejemplo, Luna',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Escribe el nombre';
                    }
                    if (value.trim().length > 60) return 'Máximo 60 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const [
                    DropdownMenuItem(value: 'dog', child: Text('Perro')),
                    DropdownMenuItem(value: 'cat', child: Text('Gato')),
                  ],
                  onChanged: _isSaving
                      ? null
                      : (value) => setState(() => _type = value ?? 'dog'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _breedController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Raza',
                    hintText: 'Puedes dejarlo vacío si no la sabes',
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().length > 80) {
                      return 'La raza no puede superar 80 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Edad (años)',
                        ),
                        validator: (value) {
                          final age = int.tryParse(value ?? '');
                          if (age == null || age < 0 || age > 60) {
                            return 'Ingresa una edad válida';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Peso (kg)',
                        ),
                        validator: (value) {
                          final weight = double.tryParse(
                            (value ?? '').replaceAll(',', '.'),
                          );
                          if (weight == null || weight <= 0 || weight > 300) {
                            return 'Ingresa un peso válido';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _bioController,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 240,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    hintText: 'Cuéntanos cómo es tu mascota',
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _isSaving ? null : _pickPhotos,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Elegir fotos'),
                ),
                if (_photoUrls.isNotEmpty || _newPhotos.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var index = 0; index < _photoUrls.length; index++)
                        _ExistingPhoto(
                          url: _photoUrls[index],
                          onRemove: _isSaving
                              ? null
                              : () => _removeExistingPhoto(index),
                        ),
                      for (var index = 0; index < _newPhotos.length; index++)
                        _PendingPhoto(
                          fileName: _newPhotos[index].name,
                          onRemove: _isSaving
                              ? null
                              : () => _removeNewPhoto(index),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    (_photoUrls.length + _newPhotos.length).toString() +
                        ' fotos seleccionadas',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (_isSaving && _newPhotos.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  LinearProgressIndicator(value: _uploadProgress),
                  const SizedBox(height: 6),
                  Text(
                    'Subiendo fotos: ' +
                        (_uploadProgress * 100).round().toString() +
                        '%',
                    textAlign: TextAlign.center,
                  ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Color(0xFFB3261E)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _savePet,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.orange,
            foregroundColor: Colors.white,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(isEditing ? 'Guardar cambios' : 'Guardar mascota'),
        ),
      ],
    );
  }
}

class _ExistingPhoto extends StatelessWidget {
  const _ExistingPhoto({required this.url, required this.onRemove});

  final String url;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            url,
            width: 76,
            height: 76,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 76,
              height: 76,
              color: const Color(0xFFF3F0ED),
              child: const Icon(Icons.pets_rounded, color: AppTheme.orange),
            ),
          ),
        ),
        Positioned(
          right: 2,
          top: 2,
          child: _RemovePhotoButton(onPressed: onRemove),
        ),
      ],
    );
  }
}

class _PendingPhoto extends StatelessWidget {
  const _PendingPhoto({required this.fileName, required this.onRemove});

  final String fileName;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 76,
          height: 76,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0E9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.image_outlined, color: AppTheme.orange),
              const SizedBox(height: 2),
              Text(
                fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9),
              ),
            ],
          ),
        ),
        Positioned(
          right: 2,
          top: 2,
          child: _RemovePhotoButton(onPressed: onRemove),
        ),
      ],
    );
  }
}

class _RemovePhotoButton extends StatelessWidget {
  const _RemovePhotoButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: const Padding(
          padding: EdgeInsets.all(3),
          child: Icon(Icons.close_rounded, size: 14, color: Colors.white),
        ),
      ),
    );
  }
}
