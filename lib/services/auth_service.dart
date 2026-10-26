import 'package:firebase_auth/firebase_auth.dart';

/// Wraps the Firebase Authentication actions used by PetVerse.
class AuthService {
  AuthService({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  /// Shared authentication service used by the application.
  static final AuthService instance = AuthService();

  final FirebaseAuth _firebaseAuth;

  /// Emits the current Firebase user whenever the session changes.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Creates an account with an email address and password.
  Future<UserCredential> createAccount({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Opens the Google sign-in popup for the Flutter Web app.
  Future<UserCredential> signInWithGoogle() {
    return _firebaseAuth.signInWithPopup(GoogleAuthProvider());
  }

  /// Updates the display name shown on the Firebase Authentication account.
  Future<void> updateDisplayName(User user, String displayName) {
    return user.updateDisplayName(displayName.trim());
  }

  /// Updates the profile photo shown on the Firebase Authentication account.
  Future<void> updatePhotoUrl(User user, String photoUrl) {
    return user.updatePhotoURL(photoUrl);
  }

  /// Signs in an existing email and password account.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sends a password reset email.
  Future<void> sendPasswordResetEmail(String email) {
    return _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  /// Signs out the current user.
  Future<void> signOut() => _firebaseAuth.signOut();
}
