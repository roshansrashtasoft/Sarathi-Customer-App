import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomerService {
  Stream<QuerySnapshot>? _customerStream;

  Stream<QuerySnapshot> getCurrentCustomerStream() {
    if (_customerStream == null) {
      _customerStream = FirebaseFirestore.instance
          .collection('customers')
          .where('uid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .snapshots()
          .asBroadcastStream();
    }
    return _customerStream!;
  }
}
