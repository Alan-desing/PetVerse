import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'screens/auth_screen.dart';
import 'screens/profile_screen.dart';
import 'services/auth_service.dart';

/// Selects the sign-in screen or profile screen from the Firebase session.
class AuthGate extends StatelessWidget {
  /// Creates the authentication state gate.
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _AuthStateMessage(
            message:
                'No pudimos consultar tu sesión. Intenta recargar la página.',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const AuthScreen();
        }

        return ProfileScreen(user: user);
      },
    );
  }
}

class _AuthStateMessage extends StatelessWidget {
  const _AuthStateMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(message)));
  }
}
