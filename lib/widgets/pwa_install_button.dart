import 'dart:html' as html;

import 'package:flutter/material.dart';

/// Offers the browser's install prompt, with manual steps as a fallback.
class PwaInstallButton extends StatefulWidget {
  const PwaInstallButton({super.key});

  @override
  State<PwaInstallButton> createState() => _PwaInstallButtonState();
}

class _PwaInstallButtonState extends State<PwaInstallButton> {
  bool _installAvailable = false;
  bool _isInstalled = false;

  @override
  void initState() {
    super.initState();
    final trigger = html.document.getElementById('petverse-install-trigger');
    _installAvailable = trigger?.dataset['installAvailable'] == 'true';
    _isInstalled = trigger?.dataset['installed'] == 'true';
    html.window.addEventListener(
      'petverse-install-available',
      _onInstallAvailable,
    );
    html.window.addEventListener(
      'petverse-install-complete',
      _onInstallComplete,
    );
  }

  @override
  void dispose() {
    html.window.removeEventListener(
      'petverse-install-available',
      _onInstallAvailable,
    );
    html.window.removeEventListener(
      'petverse-install-complete',
      _onInstallComplete,
    );
    super.dispose();
  }

  void _onInstallAvailable(html.Event _) {
    if (mounted) setState(() => _installAvailable = true);
  }

  void _onInstallComplete(html.Event _) {
    if (mounted) {
      setState(() {
        _installAvailable = false;
        _isInstalled = true;
      });
    }
  }

  Future<void> _install() async {
    if (_installAvailable) {
      html.document.getElementById('petverse-install-trigger')?.click();
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Instalar PetVerse'),
        content: const Text(
          'Abre el menú del navegador y elige “Instalar aplicación” o '
          '“Añadir a pantalla de inicio”. En algunos navegadores, esa opción '
          'aparece después de volver a visitar el sitio.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInstalled) return const SizedBox.shrink();
    return IconButton(
      tooltip: 'Instalar PetVerse',
      onPressed: _install,
      icon: Icon(
        _installAvailable
            ? Icons.install_mobile_rounded
            : Icons.download_rounded,
      ),
    );
  }
}
