import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> validateUser(String email, String password) async {
    try {
      final querySnapshot = await _firestore
          .collection('customers')
          .where('email', isEqualTo: email.trim())
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        return userData['password'] == password;
      }
      return false;
    } catch (e) {
      throw Exception('Authentication failed: $e');
    }
  }
}