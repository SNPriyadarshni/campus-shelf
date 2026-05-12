import 'api_service.dart';

class User {
  final String email;
  final String? displayName;
  User({required this.email, this.displayName});
}

class AuthService {
  static User? _currentUser;
  
  // Get current user
  User? get currentUser => _currentUser;
  
  // Check if user is logged in
  bool get isLoggedIn => _currentUser != null;
  
  // Validate college email domain
  bool _isValidCollegeEmail(String email) {
    return email.endsWith('@francisxavier.ac.in');
  }
  
  // Sign up with email and password
  Future<String?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      print('Attempting to sign up with email: $email');
      
      // Validate email domain
      if (!_isValidCollegeEmail(email)) {
        print('Email domain validation failed');
        return 'Only college email addresses (@francisxavier.ac.in) are allowed';
      }
      
      final result = await ApiService.register(email, password);
      _currentUser = User(
        email: result['user']['email'],
        displayName: email.split('@')[0], // Use email prefix as default displayName
      );
      
      return null; // Success
    } catch (e) {
      print('Signup error: $e');
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  // Sign in with email and password
  Future<String?> signInWithEmailAndPassword(String email, String password) async {
    try {
      print('Attempting to sign in with email: $email');
      
      // Validate email domain
      if (!_isValidCollegeEmail(email)) {
        print('Email domain validation failed');
        return 'Only college email addresses (@francisxavier.ac.in) are allowed';
      }
      
      final result = await ApiService.login(email, password);
      _currentUser = User(
        email: result['user']['email'],
        displayName: email.split('@')[0],
      );
      
      return null; // Success
    } catch (e) {
      print('Signin error: $e');
      return e.toString().replaceFirst('Exception: ', '');
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      await ApiService.logout();
      _currentUser = null;
    } catch (e) {
      print('Error signing out: ${e.toString()}');
    }
  }

  // Reset password
  Future<String?> sendPasswordResetEmail(String email) async {
    return 'Password reset is currently unavailable. Please contact support.';
  }
}
