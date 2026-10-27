import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/adoption_request.dart';
import '../models/pet_profile.dart';
import '../services/adoption_service.dart';
import '../theme/app_theme.dart';

class AdoptionsScreen extends StatefulWidget {
  const AdoptionsScreen({required this.user, super.key});

  final User user;

  @override
  State<AdoptionsScreen> createState() => _AdoptionsScreenState();
}

class _AdoptionsScreenState extends State<AdoptionsScreen> {
  final _locationController = TextEditingController();
  late final _petsStream = AdoptionService.instance.watchAdoptablePets();
  String _type = 'all';
  String _age = 'all';

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  bool _matches(PetProfile pet) {
    if (_type != 'all' && pet.type != _type) return false;
    if (_age == 'young' && pet.ageYears > 2) return false;
    if (_age == 'adult' && (pet.ageYears < 3 || pet.ageYears > 7)) return false;
    if (_age == 'senior' && pet.ageYears < 8) return false;
    final location = _locationController.text.trim().toLowerCase();
    return location.isEmpty || pet.location.toLowerCase().contains(location);
  }

  Future<void> _openPet(PetProfile pet) async {
    final sent = await showDialog<bool>(
      context: context,
      builder: (_) => AdoptionPetDialog(pet: pet, user: widget.user),
    );
    if (sent == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tu solicitud fue enviada y el chat ya está disponible en Mensajes.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1160),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(context),
              const SizedBox(height: 16),
              _filters(),
              const SizedBox(height: 14),
              Expanded(
                child: StreamBuilder<List<PetProfile>>(
                  stream: _petsStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      final permissionDenied =
                          snapshot.error is FirebaseException &&
                          (snapshot.error as FirebaseException).code ==
                              'permission-denied';
                      return _Message(
                        icon: Icons.cloud_off_rounded,
                        title: 'No pudimos cargar las adopciones',
                        text: permissionDenied
                            ? 'Publica las reglas nuevas de Firestore y vuelve a intentar.'
                            : 'Revisa tu conexión y vuelve a intentar.',
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final pets = (snapshot.data ?? const <PetProfile>[])
                        .where(_matches)
                        .toList();
                    if (pets.isEmpty) {
                      return const _Message(
                        icon: Icons.pets_rounded,
                        title: 'No hay mascotas para mostrar',
                        text:
                            'Cambia los filtros o publica una desde Mi perfil.',
                      );
                    }
                    return LayoutBuilder(
                      builder: (context, box) {
                        final columns = box.maxWidth >= 900
                            ? 4
                            : box.maxWidth >= 640
                            ? 3
                            : box.maxWidth >= 420
                            ? 2
                            : 1;
                        return GridView.builder(
                          itemCount: pets.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio: columns == 1 ? 1.15 : 0.78,
                              ),
                          itemBuilder: (context, index) => _PetCard(
                            pet: pets[index],
                            onTap: () => _openPet(pets[index]),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final title = const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Adopciones',
          style: TextStyle(
            color: AppTheme.ink,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text('Encuentra a tu próximo compañero.'),
      ],
    );
    final requestsButton = OutlinedButton.icon(
      onPressed: () => showDialog<void>(
        context: context,
        builder: (_) => AdoptionRequestsDialog(ownerId: widget.user.uid),
      ),
      icon: const Icon(Icons.mail_outline_rounded),
      label: const Text('Solicitudes recibidas'),
    );

    if (MediaQuery.sizeOf(context).width < 520) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title,
          const SizedBox(height: 10),
          Align(alignment: Alignment.centerLeft, child: requestsButton),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: title),
        requestsButton,
      ],
    );
  }

  Widget _filters() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFF0EEEB)),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ChoiceChip(
          label: const Text('Todos'),
          selected: _type == 'all',
          onSelected: (_) => setState(() => _type = 'all'),
        ),
        ChoiceChip(
          label: const Text('Perros'),
          selected: _type == 'dog',
          onSelected: (_) => setState(() => _type = 'dog'),
        ),
        ChoiceChip(
          label: const Text('Gatos'),
          selected: _type == 'cat',
          onSelected: (_) => setState(() => _type = 'cat'),
        ),
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<String>(
            initialValue: _age,
            decoration: const InputDecoration(
              labelText: 'Edad',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Todas')),
              DropdownMenuItem(value: 'young', child: Text('0 a 2 años')),
              DropdownMenuItem(value: 'adult', child: Text('3 a 7 años')),
              DropdownMenuItem(value: 'senior', child: Text('8 años o más')),
            ],
            onChanged: (value) => setState(() => _age = value ?? 'all'),
          ),
        ),
        SizedBox(
          width: 230,
          child: TextField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: 'Localidad',
              hintText: 'Filtrar por ciudad',
              isDense: true,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.location_on_outlined),
              suffixIcon: _locationController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _locationController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    ),
  );
}

class _PetCard extends StatelessWidget {
  const _PetCard({required this.pet, required this.onTap});

  final PetProfile pet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final photo = pet.photoUrls.isEmpty ? null : pet.photoUrls.first;
    final age = pet.ageYears == 1 ? '1 año' : pet.ageYears.toString() + ' años';
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFF0EEEB)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _Photo(url: photo)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    [
                      pet.type == 'cat' ? 'Gato' : 'Perro',
                      if (pet.breed.isNotEmpty) pet.breed,
                      age,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '📍 ' + pet.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onTap,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Ver perfil'),
                    ),
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

class _Photo extends StatelessWidget {
  const _Photo({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: const Color(0xFFFFE0D2),
      child: const Center(
        child: Icon(Icons.pets_rounded, size: 48, color: AppTheme.orange),
      ),
    );
    if (url == null || url!.isEmpty) return fallback;
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

class AdoptionPetDialog extends StatelessWidget {
  const AdoptionPetDialog({required this.pet, required this.user, super.key});

  final PetProfile pet;
  final User user;

  Future<void> _contact(BuildContext context) async {
    final sent = await showDialog<bool>(
      context: context,
      builder: (_) => AdoptionContactDialog(pet: pet, user: user),
    );
    if (sent == true && context.mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final photo = pet.photoUrls.isEmpty ? null : pet.photoUrls.first;
    final age = pet.ageYears == 1 ? '1 año' : pet.ageYears.toString() + ' años';
    return AlertDialog(
      title: Text(pet.name),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width < 600
            ? MediaQuery.sizeOf(context).width * 0.82
            : 520.0,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 230, child: _Photo(url: photo)),
              const SizedBox(height: 12),
              Text(
                [
                  pet.type == 'cat' ? 'Gato' : 'Perro',
                  if (pet.breed.isNotEmpty) pet.breed,
                  age,
                  pet.weightKg.toString() + ' kg',
                ].join(' · '),
              ),
              const SizedBox(height: 6),
              Text('Localidad: ' + pet.location),
              if (pet.bio.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'Sobre esta mascota',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(pet.bio),
              ],
              if (pet.ownerId != user.uid) ...[
                const SizedBox(height: 14),
                const Text(
                  'El dueño recibirá tu nombre, correo y mensaje dentro de PetVerse.',
                  style: TextStyle(color: Color(0xFF657279)),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cerrar'),
        ),
        if (pet.ownerId != user.uid)
          FilledButton.icon(
            onPressed: () => _contact(context),
            icon: const Icon(Icons.mail_outline_rounded),
            label: const Text('Contactar'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.orange,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }
}

class AdoptionContactDialog extends StatefulWidget {
  const AdoptionContactDialog({
    required this.pet,
    required this.user,
    super.key,
  });

  final PetProfile pet;
  final User user;

  @override
  State<AdoptionContactDialog> createState() => _AdoptionContactDialogState();
}

class _AdoptionContactDialogState extends State<AdoptionContactDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _message = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final displayName = widget.user.displayName?.trim() ?? '';
    _name.text = displayName.isNotEmpty
        ? displayName
        : (widget.user.email?.split('@').first ?? '');
    _email.text = widget.user.email ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await AdoptionService.instance.sendRequest(
        pet: widget.pet,
        requesterId: widget.user.uid,
        requesterName: _name.text,
        requesterEmail: _email.text,
        message: _message.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.code == 'permission-denied'
            ? 'Firestore rechazó el envío. Publica las reglas nuevas.'
            : 'No se pudo enviar. Inténtalo otra vez.';
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo enviar. Inténtalo otra vez.');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Consultar por ' + widget.pet.name),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width < 600
            ? MediaQuery.sizeOf(context).width * 0.82
            : 460.0,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'El dueño verá estos datos en sus solicitudes recibidas.',
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Tu nombre'),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) return 'Escribe tu nombre';
                    if (text.length > 80) return 'Máximo 80 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _email,
                  readOnly: true,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Tu correo',
                    helperText: 'Usamos el correo de tu cuenta.',
                  ),
                  validator: (value) {
                    final email = (value ?? '').trim();
                    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
                        ? null
                        : 'Escribe un correo válido';
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _message,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 800,
                  decoration: const InputDecoration(
                    labelText: 'Mensaje',
                    hintText: 'Cuéntale al dueño por qué te interesa...',
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Escribe un mensaje'
                      : null,
                ),
                if (_error != null)
                  Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFB3261E)),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _sending ? null : _send,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.orange,
            foregroundColor: Colors.white,
          ),
          child: _sending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Enviar solicitud'),
        ),
      ],
    );
  }
}

class AdoptionRequestsDialog extends StatelessWidget {
  const AdoptionRequestsDialog({required this.ownerId, super.key});

  final String ownerId;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Solicitudes recibidas'),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width < 600
            ? MediaQuery.sizeOf(context).width * 0.82
            : 540.0,
        height: MediaQuery.sizeOf(context).height < 700
            ? MediaQuery.sizeOf(context).height * 0.65
            : 430.0,
        child: StreamBuilder<List<AdoptionRequest>>(
          stream: AdoptionService.instance.watchIncomingRequests(ownerId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'No pudimos cargar las solicitudes. Revisa las reglas.',
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final requests = snapshot.data ?? const <AdoptionRequest>[];
            if (requests.isEmpty) {
              return const Center(
                child: Text('Todavía no recibiste solicitudes.'),
              );
            }
            return ListView.separated(
              itemCount: requests.length,
              separatorBuilder: (_, _) => const Divider(height: 22),
              itemBuilder: (context, index) {
                final request = requests[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.requesterName +
                          ' consulta por ' +
                          request.petName,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(request.requesterEmail),
                    const SizedBox(height: 7),
                    Text(request.message),
                    if (request.createdAt != null)
                      Text(
                        _dateLabel(request.createdAt!),
                        style: const TextStyle(
                          color: Color(0xFF657279),
                          fontSize: 12,
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}

String _dateLabel(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return day + '/' + month + '/' + date.year.toString();
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppTheme.orange),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(text, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
