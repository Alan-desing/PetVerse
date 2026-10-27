import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_notification.dart';
import '../services/browser_notification_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

/// Lists private notices and browser alerts for a signed-in user.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({required this.user, super.key});

  final User user;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final Stream<List<AppNotification>> _notificationsStream;
  StreamSubscription<List<AppNotification>>? _subscription;
  final Set<String> _seenIds = <String>{};
  bool _isFirstSnapshot = true;
  bool _browserPermissionGranted =
      BrowserNotificationService.permission == 'granted';
  bool _isRequestingPermission = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _notificationsStream = NotificationService.instance.watchNotifications(
      widget.user.uid,
    );
    _subscription = _notificationsStream.listen(_handleNotifications);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _handleNotifications(List<AppNotification> notifications) {
    if (_isFirstSnapshot) {
      _seenIds.addAll(notifications.map((notice) => notice.id));
      _isFirstSnapshot = false;
      return;
    }

    for (final notice in notifications) {
      if (_seenIds.add(notice.id) && !notice.isRead) {
        BrowserNotificationService.show(
          title: 'PetVerse · ${notice.actorName}',
          body: notice.body,
        );
      }
    }
  }

  Future<void> _enableBrowserNotifications() async {
    setState(() {
      _isRequestingPermission = true;
      _message = null;
    });
    final granted = await BrowserNotificationService.requestPermission();
    if (!mounted) return;
    setState(() {
      _isRequestingPermission = false;
      _browserPermissionGranted = granted;
      _message = granted
          ? 'El navegador mostrará avisos nuevos mientras PetVerse esté abierto.'
          : 'No se concedió permiso para mostrar avisos del navegador.';
    });
  }

  Future<void> _markAllRead() async {
    try {
      await NotificationService.instance.markAllRead(widget.user.uid);
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'No pudimos marcar los avisos como leídos.');
      }
    }
  }

  Future<void> _markRead(AppNotification notice) async {
    if (notice.isRead) return;
    try {
      await NotificationService.instance.markRead(widget.user.uid, notice.id);
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'No pudimos actualizar ese aviso.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Avisos',
                      style: TextStyle(
                        color: AppTheme.ink,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _markAllRead,
                    child: const Text('Marcar todo leído'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Me gusta, comentarios y mensajes nuevos.'),
              const SizedBox(height: 12),
              if (BrowserNotificationService.isSupported &&
                  !_browserPermissionGranted)
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _isRequestingPermission
                        ? null
                        : _enableBrowserNotifications,
                    icon: _isRequestingPermission
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.notifications_active_outlined),
                    label: const Text('Activar avisos del navegador'),
                  ),
                ),
              if (_browserPermissionGranted)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Avisos del navegador activados mientras PetVerse esté abierto.',
                    style: TextStyle(color: Color(0xFF657279), fontSize: 12),
                  ),
                ),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _message!,
                    style: const TextStyle(color: Color(0xFF657279)),
                  ),
                ),
              Expanded(
                child: StreamBuilder<List<AppNotification>>(
                  stream: _notificationsStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          'No pudimos cargar tus avisos. Revisa las reglas de Firestore.',
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final notices = snapshot.data!;
                    if (notices.isEmpty) {
                      return const Center(
                        child: Text('Todavía no tienes avisos.'),
                      );
                    }
                    return ListView.separated(
                      itemCount: notices.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final notice = notices[index];
                        return Card(
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          color: notice.isRead
                              ? Colors.white
                              : const Color(0xFFFFF7F2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Color(0xFFF0EEEB)),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFFFE0D2),
                              foregroundColor: AppTheme.orange,
                              child: Icon(_iconFor(notice.type)),
                            ),
                            title: Text(
                              notice.actorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              _subtitle(notice),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: notice.createdAt == null
                                ? null
                                : Text(
                                    DateFormat('dd/MM HH:mm')
                                        .format(notice.createdAt!),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                            onTap: () => _markRead(notice),
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

  IconData _iconFor(String type) => switch (type) {
    'like' => Icons.favorite_rounded,
    'comment' => Icons.chat_bubble_rounded,
    'message' => Icons.mark_chat_unread_rounded,
    _ => Icons.notifications_rounded,
  };

  String _subtitle(AppNotification notice) {
    if (notice.type == 'like') return 'Le gustó tu publicación.';
    return notice.body;
  }
}
