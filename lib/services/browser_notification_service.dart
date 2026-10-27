import 'dart:html' as html;

/// Displays browser notifications while the PetVerse page is running.
class BrowserNotificationService {
  BrowserNotificationService._();

  static bool get isSupported => html.Notification.supported;

  static String get permission => html.Notification.permission ?? 'default';

  /// Requests browser permission after a direct user action.
  static Future<bool> requestPermission() async {
    if (!isSupported) return false;
    return await html.Notification.requestPermission() == 'granted';
  }

  /// Shows a browser notification when permission has already been granted.
  static void show({required String title, required String body}) {
    if (!isSupported || permission != 'granted') return;
    html.Notification(title, body: body);
  }
}
