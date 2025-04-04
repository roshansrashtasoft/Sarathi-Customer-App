import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<DocumentSnapshot?> getCurrentCustomer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('userEmail');
      
      if (userEmail != null) {
        final snapshot = await _firestore
            .collection('customers')
            .where('email', isEqualTo: userEmail)
            .get();
            
        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs.first;
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get customer data: $e');
    }
  }
}