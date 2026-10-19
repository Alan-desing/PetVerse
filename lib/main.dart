import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_form_provider.dart';
import 'screens/auth_screen.dart';
import 'theme/app_theme.dart';

/// Starts the PetVerse web application.
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthFormProvider(),
      child: const PetVerseApp(),
    ),
  );
}

/// Configures the app-wide theme and initial route.
class PetVerseApp extends StatelessWidget {
  /// Creates the root PetVerse widget.
  const PetVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetVerse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthScreen(),
    );
  }
}
