import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/pet_profile.dart';
import '../services/pet_service.dart';
import '../theme/app_theme.dart';

/// Dialog used to create or edit a pet profile without cloud file storage.
class PetFormDialog extends StatefulWidget {
  const PetFormDialog({required this.ownerId, this.pet, super.key});

  final String ownerId;
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
  final _photoUrlsController = TextEditingController();
  final _locationController = TextEditingController();

  late String _type;
  bool _isForAdoption = false;
  bool _isSaving = false;
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
    _photoUrlsController.text = pet?.photoUrls.join('\n') ?? '';
    _locationController.text = pet?.location ?? '';
    _isForAdoption = pet?.isForAdoption ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _bioController.dispose();
    _photoUrlsController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  List<String> _photoUrls() => _photoUrlsController.text
      .split(RegExp(r'\r?\n'))
      .map((url) => url.trim())
      .where((url) => url.isNotEmpty)
      .toList();

  String? _validatePhotoUrls(String? value) {
    final urls = (value ?? '')
        .split(RegExp(r'\r?\n'))
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList();

    if (urls.length > 6) return 'Puedes agregar hasta 6 enlaces de foto.';
    for (final url in urls) {
      final uri = Uri.tryParse(url);
      if (uri == null ||
          !uri.hasAuthority ||
          (uri.scheme != 'https' && uri.scheme != 'http')) {
        return 'Cada foto necesita un enlace web válido.';
      }
    }
    return null;
  }

  Future<void> _savePet() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final pet = PetProfile(
        id: widget.pet?.id ?? PetService.instance.createPetId(widget.ownerId),
        ownerId: widget.ownerId,
        name: _nameController.text.trim(),
        type: _type,
        breed: _breedController.text.trim(),
        ageYears: int.parse(_ageController.text),
        weightKg: double.parse(_weightController.text.replaceAll(',', '.')),
        bio: _bioController.text.trim(),
        photoUrls: _photoUrls(),
        location: _locationController.text.trim(),
        isForAdoption: _isForAdoption,
      );
      await PetService.instance.savePet(pet);
      if (mounted) Navigator.of(context).pop(true);
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.code == 'permission-denied'
              ? 'Firebase rechazó el cambio. Publica las reglas actualizadas.'
              : 'No pudimos guardar la mascota. Inténtalo otra vez.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'No pudimos guardar la mascota. Inténtalo otra vez.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.pet != null;
    final photoUrls = _photoUrls();

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
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
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
                const SizedBox(height: 14),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Publicar en adopciones'),
                  subtitle: const Text(
                    'Otros usuarios podrán ver el perfil y enviarte una solicitud.',
                  ),
                  value: _isForAdoption,
                  activeThumbColor: AppTheme.orange,
                  onChanged: _isSaving
                      ? null
                      : (value) => setState(() => _isForAdoption = value),
                ),
                if (_isForAdoption) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _locationController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Localidad',
                      hintText: 'Por ejemplo, Córdoba Capital',
                    ),
                    validator: (value) {
                      if (_isForAdoption && (value ?? '').trim().isEmpty) {
                        return 'Indica en qué localidad está';
                      }
                      if ((value ?? '').trim().length > 100) {
                        return 'Máximo 100 caracteres';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 10),
                TextFormField(
                  controller: _photoUrlsController,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 1800,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Enlaces de fotos (opcional)',
                    hintText: 'Pega un enlace directo por línea',
                    helperText: 'Sin Storage, usa enlaces públicos de imágenes. Máximo 6.',
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 50),
                      child: Icon(Icons.link_rounded),
                    ),
                  ),
                  validator: _validatePhotoUrls,
                  onChanged: (_) => setState(() {}),
                ),
                if (photoUrls.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final url in photoUrls)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            url,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 72,
                              height: 72,
                              color: const Color(0xFFFFE0D2),
                              child: const Icon(
                                Icons.broken_image_outlined,
                                color: AppTheme.orange,
                              ),
                            ),
                          ),
                        ),
                    ],
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
