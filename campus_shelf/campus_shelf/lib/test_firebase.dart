import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

class FirebaseTest {
  static Future<void> testConnection() async {
    try {
      print('Testing Firebase connection...');
      
      // Test Firebase initialization
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase initialized successfully');
      
      // Test FirebaseAuth
      final auth = FirebaseAuth.instance;
      print('✅ FirebaseAuth instance created');
      
      // Check current user
      final user = auth.currentUser;
      print('Current user: ${user?.email ?? "None"}');
      
      // Test auth state changes
      auth.authStateChanges().listen((User? user) {
        print('Auth state changed: ${user?.email ?? "No user"}');
      });
      
      print('✅ Firebase test completed successfully');
      
    } catch (e) {
      print('❌ Firebase test failed: $e');
    }
  }
}
