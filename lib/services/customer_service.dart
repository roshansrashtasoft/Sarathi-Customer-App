import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> _getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userEmail');
  }

  Stream<QuerySnapshot> getCurrentCustomerStream() async* {
    final userEmail = await _getUserEmail();
    if (userEmail != null) {
      yield* _firestore
          .collection('customers')
          .where('email', isEqualTo: userEmail)
          .snapshots();
    }
  }
}
