import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_form_provider.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../theme/app_theme.dart';

/// Responsive sign-in and registration screen for PetVerse.
class AuthScreen extends StatefulWidget {
  /// Creates the PetVerse authentication screen.
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _authErrorMessage(FirebaseAuthException error) {
    return switch (error.code) {
      'email-already-in-use' => 'Ya existe una cuenta con ese correo.',
      'invalid-email' => 'El formato del correo no es válido.',
      'user-disabled' => 'Esta cuenta está deshabilitada.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'El correo o la contraseña son incorrectos.',
      'weak-password' => 'Elige una contraseña más segura.',
      'operation-not-allowed' =>
        'El acceso por correo todavía no está activado en Firebase.',
      'too-many-requests' =>
        'Hubo demasiados intentos. Espera un momento y vuelve a probar.',
      'network-request-failed' =>
        'No hay conexión. Revisa internet e inténtalo otra vez.',
      _ => 'No pudimos completar el acceso. Inténtalo de nuevo.',
    };
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final isRegistering = context.read<AuthFormProvider>().isRegistering;
    setState(() => _isSubmitting = true);

    try {
      if (isRegistering) {
        final displayName = _nameController.text.trim();
        final credential = await AuthService.instance.createAccount(
          email: _emailController.text,
          password: _passwordController.text,
        );
        final user = credential.user;
        if (user != null) {
          await AuthService.instance.updateDisplayName(user, displayName);
          await UserProfileService.instance.getOrCreateProfile(
            user,
            fallbackName: displayName,
          );
        }
      } else {
        await AuthService.instance.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) _showMessage(_authErrorMessage(error));
    } on FirebaseException catch (error) {
      if (!mounted) return;
      _showMessage(
        error.code == 'permission-denied'
            ? 'La cuenta se creó, pero Firestore todavía no permite guardar el perfil. Publica las reglas del proyecto.'
            : 'La cuenta se creó, pero no pudimos guardar el perfil todavía.',
      );
    } catch (_) {
      if (mounted) {
        _showMessage('No pudimos completar el registro. Inténtalo de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showMessage(
        'Escribe tu correo para enviarte el enlace de recuperación.',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await AuthService.instance.sendPasswordResetEmail(email);
      if (mounted) {
        _showMessage('Si hay una cuenta con ese correo, recibirá un enlace.');
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) _showMessage(_authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showGoogleSetupNotice() {
    _showMessage(
      'Para usar Google, activa ese proveedor en Firebase. En este bloque funciona el acceso por correo y contraseña.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 960;

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 1320),
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 52 : 22,
                      vertical: isWide ? 42 : 28,
                    ),
                    child: isWide
                        ? Row(
                            children: [
                              const Expanded(child: _WelcomePanel()),
                              const SizedBox(width: 64),
                              SizedBox(width: 440, child: _buildFormPanel()),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildCompactBrand(),
                              const SizedBox(height: 28),
                              _buildFormPanel(),
                              const SizedBox(height: 24),
                              const _FooterNote(),
                            ],
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompactBrand() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _BrandMark(size: 46),
        SizedBox(width: 11),
        Text(
          'PetVerse',
          style: TextStyle(
            color: AppTheme.ink,
            fontSize: 25,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
          ),
        ),
      ],
    );
  }

  Widget _buildFormPanel() {
    return Consumer<AuthFormProvider>(
      builder: (context, formState, _) {
        return Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFFF0EEEB)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D263238),
                blurRadius: 36,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  formState.isRegistering
                      ? 'Crea tu cuenta'
                      : '¡Qué bueno verte!',
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontSize: 30),
                ),
                const SizedBox(height: 8),
                Text(
                  formState.isRegistering
                      ? 'Únete a una comunidad que ama a sus mascotas.'
                      : 'Entra a tu comunidad de personas y mascotas.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 26),
                if (formState.isRegistering) ...[
                  _LabeledField(
                    label: 'Tu nombre',
                    child: TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.name],
                      decoration: const InputDecoration(
                        hintText: '¿Cómo te llamas?',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Escribe tu nombre';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 17),
                ],
                _LabeledField(
                  label: 'Correo electrónico',
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      hintText: 'nombre@correo.com',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isEmpty || !email.contains('@')) {
                        return 'Ingresa un correo válido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 17),
                _LabeledField(
                  label: 'Contraseña',
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: !formState.passwordVisible,
                    autofillHints: formState.isRegistering
                        ? const [AutofillHints.newPassword]
                        : const [AutofillHints.password],
                    decoration: InputDecoration(
                      hintText: 'Al menos 6 caracteres',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        tooltip: formState.passwordVisible
                            ? 'Ocultar contraseña'
                            : 'Mostrar contraseña',
                        onPressed: formState.togglePasswordVisibility,
                        icon: Icon(
                          formState.passwordVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'Usa al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                ),
                if (formState.isRegistering) ...[
                  const SizedBox(height: 17),
                  _LabeledField(
                    label: 'Repite la contraseña',
                    child: TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !formState.passwordVisible,
                      decoration: const InputDecoration(
                        hintText: 'Vuelve a escribirla',
                        prefixIcon: Icon(Icons.lock_reset_rounded),
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
                if (!formState.isRegistering)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isSubmitting ? null : _sendPasswordReset,
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.orange,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('¿Olvidaste tu contraseña?'),
                    ),
                  )
                else
                  const SizedBox(height: 22),
                SizedBox(
                  height: 54,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            formState.isRegistering
                                ? 'Crear mi cuenta'
                                : 'Iniciar sesión',
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                const _DividerLabel(label: 'o continúa con'),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: _isSubmitting ? null : _showGoogleSetupNotice,
                  icon: const Icon(Icons.g_mobiledata_rounded, size: 27),
                  label: const Text('Continuar con Google'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.ink,
                    minimumSize: const Size.fromHeight(52),
                    side: const BorderSide(color: Color(0xFFE5E7E5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      formState.isRegistering
                          ? '¿Ya tienes cuenta? '
                          : '¿Todavía no tienes cuenta? ',
                      style: const TextStyle(color: Color(0xFF657279)),
                    ),
                    TextButton(
                      onPressed: formState.toggleMode,
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.orange,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      child: Text(
                        formState.isRegistering
                            ? 'Inicia sesión'
                            : 'Regístrate',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Row(
          children: [
            _BrandMark(size: 52),
            SizedBox(width: 13),
            Text(
              'PetVerse',
              style: TextStyle(
                color: AppTheme.ink,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 52),
        Container(
          height: 290,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFD9C9), Color(0xFFFFEEE1)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -15,
                top: -52,
                child: _SoftCircle(size: 210, color: Color(0x44FFFFFF)),
              ),
              Positioned(
                left: 42,
                bottom: -83,
                child: _SoftCircle(size: 190, color: Color(0x33FF7043)),
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 174,
                  height: 174,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.82),
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x20A94F30),
                        blurRadius: 30,
                        offset: Offset(0, 15),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.pets_rounded,
                    size: 86,
                    color: AppTheme.orange,
                  ),
                ),
              ),
              const Positioned(
                right: 72,
                top: 54,
                child: _FloatingPaw(size: 26, rotation: 0.24),
              ),
              const Positioned(
                left: 68,
                bottom: 45,
                child: _FloatingPaw(size: 34, rotation: -0.22),
              ),
              const Positioned(
                right: 54,
                bottom: 50,
                child: Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFFFF8F75),
                  size: 28,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 34),
        Text(
          'Un mundo más feliz\npara vos y tu mascota.',
          style: Theme.of(context).textTheme.headlineLarge
              ?.copyWith(fontSize: 42, height: 1.12),
        ),
        const SizedBox(height: 16),
        Text(
          'Comparte momentos, encuentra nuevos amigos y descubre una comunidad hecha para quienes aman a los animales.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 26),
        const _CommunityPill(),
        const SizedBox(height: 34),
        const _FooterNote(),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.orange,
        borderRadius: BorderRadius.circular(size * 0.34),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30FF7043),
            blurRadius: 15,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Icon(Icons.pets_rounded, size: size * 0.55, color: Colors.white),
    );
  }
}

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _FloatingPaw extends StatelessWidget {
  const _FloatingPaw({required this.size, required this.rotation});

  final double size;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Icon(
        Icons.pets_rounded,
        color: const Color(0x99FF7043),
        size: size,
      ),
    );
  }
}

class _CommunityPill extends StatelessWidget {
  const _CommunityPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFF0EEEB)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_rounded, size: 17, color: AppTheme.orange),
          SizedBox(width: 8),
          Text(
            'Una comunidad que mueve colitas',
            style: TextStyle(
              color: AppTheme.ink,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE9EAE8))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF90999D), fontSize: 12),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFE9EAE8))),
      ],
    );
  }
}

class _FooterNote extends StatelessWidget {
  const _FooterNote();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Al continuar, aceptas nuestros Términos de uso y la Política de privacidad.',
      textAlign: TextAlign.center,
      style: TextStyle(color: Color(0xFF929B9F), fontSize: 11, height: 1.5),
    );
  }
}
