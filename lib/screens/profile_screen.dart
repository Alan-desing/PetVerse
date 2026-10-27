import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../theme/app_theme.dart';
import 'adoptions_screen.dart';
import 'chat_screen.dart';
import 'feed_screen.dart';
import 'gamification_screen.dart';
import 'notifications_screen.dart';
import 'pets_section.dart';
import '../widgets/pwa_install_button.dart';

/// Main authenticated area with the social feed and editable profile.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({required this.user, super.key});

  final User user;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _photoUrlController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await UserProfileService.instance.getOrCreateProfile(
        widget.user,
      );
      if (!mounted) return;

      _displayNameController.text = profile.displayName;
      _bioController.text = profile.bio;
      _photoUrlController.text = profile.photoUrl ?? '';
      setState(() {
        _isLoading = false;
        _loadError = null;
      });
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = error.code == 'permission-denied'
            ? 'Firestore bloqueó el perfil. Publica las reglas actualizadas.'
            : 'No pudimos cargar el perfil. Revisa tu conexión e inténtalo otra vez.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'No pudimos cargar el perfil. Inténtalo otra vez.';
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      await UserProfileService.instance.updateProfile(
        user: widget.user,
        displayName: _displayNameController.text,
        bio: _bioController.text,
        photoUrl: _photoUrlController.text,
      );
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Perfil guardado.')));
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() {
        _saveError = error.code == 'permission-denied'
            ? 'Firestore rechazó el cambio. Publica las reglas actualizadas.'
            : 'No pudimos guardar el perfil. Inténtalo otra vez.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saveError = 'No pudimos guardar el perfil. Inténtalo otra vez.';
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _validatePhotoUrl(String? value) {
    final url = value?.trim() ?? '';
    if (url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      return 'Pega un enlace web válido a una imagen.';
    }
    return null;
  }

  Future<void> _signOut() async {
    try {
      await AuthService.instance.signOut();
    } on FirebaseAuthException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos cerrar la sesión.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'PetVerse',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(
                icon: Icon(Icons.dynamic_feed_rounded),
                text: 'Publicaciones',
              ),
              Tab(icon: Icon(Icons.pets_rounded), text: 'Adopciones'),
              Tab(
                icon: Icon(Icons.chat_bubble_outline_rounded),
                text: 'Mensajes',
              ),
              Tab(icon: Icon(Icons.notifications_none_rounded), text: 'Avisos'),
              Tab(icon: Icon(Icons.emoji_events_outlined), text: 'Logros'),
              Tab(icon: Icon(Icons.person_outline_rounded), text: 'Mi perfil'),
            ],
          ),
          actions: [
            const PwaInstallButton(),
            IconButton(
              tooltip: 'Cerrar sesión',
              onPressed: _signOut,
              icon: const Icon(Icons.logout_rounded),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: TabBarView(
          children: [
            FeedScreen(user: widget.user),
            AdoptionsScreen(user: widget.user),
            ChatScreen(user: widget.user),
            NotificationsScreen(user: widget.user),
            GamificationScreen(user: widget.user),
            _buildProfileTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return _LoadError(message: _loadError!, onRetry: _loadProfile);
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProfileForm(context),
              const SizedBox(height: 20),
              PetsSection(ownerId: widget.user.uid),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileForm(BuildContext context) {
    final displayName = _displayNameController.text.trim();
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'P';
    final photoUrl = _photoUrlController.text.trim();

    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF0EEEB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D263238),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Column(
                children: [
                  _ProfileAvatar(photoUrl: photoUrl, initial: initial),
                  const SizedBox(height: 12),
                  Text(
                    'Tu perfil',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Edita tus datos y comparte el enlace de una foto.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _ProfileFieldLabel(label: 'Nombre'),
            TextFormField(
              controller: _displayNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Tu nombre',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Escribe tu nombre';
                }
                if (value.trim().length > 80) {
                  return 'El nombre no puede superar los 80 caracteres';
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 18),
            const _ProfileFieldLabel(label: 'Correo electrónico'),
            TextFormField(
              initialValue: widget.user.email ?? '',
              readOnly: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.mail_outline_rounded),
                helperText: 'El correo se administra desde tu cuenta.',
              ),
            ),
            const SizedBox(height: 18),
            const _ProfileFieldLabel(label: 'Sobre mí'),
            TextFormField(
              controller: _bioController,
              minLines: 3,
              maxLines: 5,
              maxLength: 240,
              decoration: const InputDecoration(
                hintText: 'Cuéntale algo a la comunidad...',
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 50),
                  child: Icon(Icons.chat_bubble_outline_rounded),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _ProfileFieldLabel(label: 'Enlace de foto (opcional)'),
            TextFormField(
              controller: _photoUrlController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                hintText: 'https://sitio.com/mi-foto.jpg',
                prefixIcon: Icon(Icons.link_rounded),
                helperText:
                    'Sin Storage, pega un enlace web directo a la imagen.',
              ),
              validator: _validatePhotoUrl,
              onChanged: (_) => setState(() {}),
            ),
            if (_saveError != null) ...[
              const SizedBox(height: 8),
              Text(
                _saveError!,
                style: const TextStyle(color: Color(0xFFB3261E)),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Guardar perfil',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.photoUrl, required this.initial});

  final String photoUrl;
  final String initial;

  @override
  Widget build(BuildContext context) {
    final placeholder = CircleAvatar(
      radius: 46,
      backgroundColor: const Color(0xFFFFE0D2),
      foregroundColor: AppTheme.orange,
      child: Text(
        initial,
        style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
      ),
    );

    if (photoUrl.isEmpty) return placeholder;
    return ClipOval(
      child: Image.network(
        photoUrl,
        width: 92,
        height: 92,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}

class _ProfileFieldLabel extends StatelessWidget {
  const _ProfileFieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.ink,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 42, color: AppTheme.orange),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Volver a intentar'),
          ),
        ],
      ),
    );
  }
}
