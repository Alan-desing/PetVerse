import 'package:flutter/material.dart';

import '../models/pet_profile.dart';
import '../services/pet_service.dart';
import '../theme/app_theme.dart';
import 'pet_form_dialog.dart';

/// Lists a user's pets and provides create, edit, and delete actions.
class PetsSection extends StatelessWidget {
  /// Creates the pet list for [ownerId].
  const PetsSection({required this.ownerId, super.key});

  /// Firebase user ID that owns the pets.
  final String ownerId;

  Future<void> _openPetForm(BuildContext context, [PetProfile? pet]) async {
    await showDialog<bool>(
      context: context,
      builder: (_) => PetFormDialog(ownerId: ownerId, pet: pet),
    );
  }

  Future<void> _deletePet(BuildContext context, PetProfile pet) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar mascota'),
        content: Text('¿Quieres eliminar el perfil de ' + pet.name + '?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB3261E),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !context.mounted) return;
    try {
      await PetService.instance.deletePet(pet);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(pet.name + ' fue eliminada.')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pudimos eliminar la mascota.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Mis mascotas',
      subtitle: 'Agrega y administra los perfiles de tus compañeros.',
      action: FilledButton.icon(
        onPressed: () => _openPetForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Agregar'),
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.orange,
          foregroundColor: Colors.white,
        ),
      ),
      child: StreamBuilder<List<PetProfile>>(
        stream: PetService.instance.watchPets(ownerId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('No pudimos cargar tus mascotas.');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final pets = snapshot.data ?? const <PetProfile>[];
          if (pets.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Todavía no agregaste mascotas.',
                style: TextStyle(color: Color(0xFF657279)),
              ),
            );
          }

          return Column(
            children: [
              for (final pet in pets)
                _PetTile(
                  pet: pet,
                  onEdit: () => _openPetForm(context, pet),
                  onDelete: () => _deletePet(context, pet),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PetTile extends StatelessWidget {
  const _PetTile({
    required this.pet,
    required this.onEdit,
    required this.onDelete,
  });

  final PetProfile pet;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final typeName = pet.type == 'cat' ? 'Gato' : 'Perro';
    final ageLabel = pet.ageYears == 1
        ? '1 año'
        : pet.ageYears.toString() + ' años';
    final details = [
      typeName,
      if (pet.breed.isNotEmpty) pet.breed,
      ageLabel,
      pet.weightKg.toString() + ' kg',
      if (pet.isForAdoption) 'En adopción · ' + pet.location,
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: const Color(0xFFFFFBF8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFF0EEEB)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 12, right: 4),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: const Color(0xFFFFE0D2),
          foregroundColor: AppTheme.orange,
          backgroundImage: pet.photoUrls.isNotEmpty
              ? NetworkImage(pet.photoUrls.first)
              : null,
          child: pet.photoUrls.isEmpty ? const Icon(Icons.pets_rounded) : null,
        ),
        title: Text(
          pet.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          details + (pet.bio.isNotEmpty ? '\n' + pet.bio : ''),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: pet.bio.isNotEmpty,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Editar')),
            PopupMenuItem(value: 'delete', child: Text('Eliminar')),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.action,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget action;
  final Widget child;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              action,
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}
