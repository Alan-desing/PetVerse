import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_gate.dart';
import 'firebase_options.dart';
import 'providers/auth_form_provider.dart';
import 'theme/app_theme.dart';

/// Starts the PetVerse web application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
      home: const AuthGate(),
    );
  }
}
