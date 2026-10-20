import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../theme/app_theme.dart';

/// Displays and edits the signed-in user's basic PetVerse profile.
class ProfileScreen extends StatefulWidget {
  /// Creates the profile screen for [user].
  const ProfileScreen({required this.user, super.key});

  /// The Firebase account whose profile is being displayed.
  final User user;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();

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
      setState(() {
        _isLoading = false;
        _loadError = null;
      });
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = error.code == 'permission-denied'
            ? 'Firestore todavía no permite guardar perfiles. Publica las reglas de seguridad del proyecto y vuelve a entrar.'
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
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Perfil guardado.')));
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() {
        _saveError = error.code == 'permission-denied'
            ? 'Firestore rechazó el cambio. Revisa las reglas de seguridad.'
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PetVerse',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Cerrar sesión'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildBody(context),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 100),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return _LoadError(message: _loadError!, onRetry: _loadProfile);
    }

    final trimmedName = _displayNameController.text.trim();
    final initial = trimmedName.isNotEmpty ? trimmedName[0].toUpperCase() : 'P';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: const Color(0xFFFFE0D2),
                foregroundColor: AppTheme.orange,
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Tu perfil',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 5),
              Text(
                'Completa tus datos para que la comunidad te conozca.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Container(
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
                const Text(
                  'Información personal',
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
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
        ),
      ],
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
      padding: const EdgeInsets.symmetric(vertical: 100),
      child: Column(
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
