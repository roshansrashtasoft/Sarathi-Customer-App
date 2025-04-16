import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:sarathi_customer/screens/profile_screen.dart';
import 'package:sarathi_customer/screens/web_view.dart';
import 'package:sarathi_customer/services/customer_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'document_slider_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CustomerService _customerService = CustomerService();
  late final Stream<QuerySnapshot> _customerStream;
  DateFormat dateFormat = DateFormat("dd MMMM yyyy");

  @override
  void initState() {
    super.initState();
    _customerStream = _customerService.getCurrentCustomerStream();
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    if (timestamp is Timestamp) {
      return dateFormat.format(timestamp.toDate());
    } else if (timestamp is String) {
      try {
        return dateFormat.format(DateTime.parse(timestamp));
      } catch (e) {
        return timestamp;
      }
    }
    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: StreamBuilder<QuerySnapshot>(
          stream: _customerStream,
          builder: (context, snapshot) {
            return IconButton(
              icon: const Icon(Icons.person_outline, color: Colors.black87),
              onPressed: () {
                if (snapshot.hasData) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => ProfileScreen(
                      userData: snapshot.data!.docs.first.data() as Map<String, dynamic>,
                    ),
                  );
                }
              },
            );
          },
        ),
        title: const Text(
          'Sarathi Innovations',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => handleLogout(context),
            icon: const Icon(Icons.logout, color: Colors.black87)
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _customerStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('No documents available', style: TextStyle(color: Colors.grey[600])),
            );
          }

          final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data['documents'] != null) ...[
                        _buildSectionTitle('Documents'),
                        const SizedBox(height: 16),
                        _buildDocumentsGrid(data['documents'] as List),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildDetailCard(List<Widget> children) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(children: children),
      ),
    );
  }

  // Widget _buildDetailRow(String label, String? value) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 12),
  //     child: Row(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         SizedBox(
  //           width: 100,
  //           child: Text(
  //             label,
  //             style: TextStyle(
  //               color: Colors.grey[600],
  //               fontSize: 15,
  //               fontWeight: FontWeight.w500,
  //             ),
  //           ),
  //         ),
  //         Expanded(
  //           child: Text(
  //             value ?? 'N/A',
  //             style: const TextStyle(
  //               fontSize: 15,
  //               fontWeight: FontWeight.w500,
  //               color: Colors.black87,
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildDocumentsGrid(List documents) {
    final List<Map<String, dynamic>> typedDocs = 
      documents.map((doc) => doc as Map<String, dynamic>).toList();
      
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: documents.length,
      itemBuilder: (context, index) => _buildDocumentCard(typedDocs[index], typedDocs),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc, List<Map<String, dynamic>> allDocs) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              final currentIndex = allDocs.indexWhere((d) => d['url'] == doc['url']);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => DocumentSliderScreen(
                    documents: allDocs,
                    initialIndex: currentIndex,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    doc['type'] == 'pdf' ? Icons.picture_as_pdf : Icons.image,
                    color: Colors.black,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      Text(
                        doc['name'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _formatTimestamp(   doc['uploadedAt']),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void handleLogout(BuildContext context) async {
    final confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout', textAlign: TextAlign.center),
          backgroundColor: Colors.white,
          content: const Text(
            'Are you sure you want to logout?',
            textAlign: TextAlign.center,
          ),
          actionsPadding: const EdgeInsets.all(16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: Colors.grey[200],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        // Clear all local data (SharedPreferences)
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        // Sign out from Firebase Auth
        await FirebaseAuth.instance.signOut();

        if (context.mounted) {
          // Navigate to login screen and remove all previous routes
          // Navigator.of(
          //   context,
          // ).pushNamedAndRemoveUntil('/login', (route) => false);
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginScreen()),
                (Route<dynamic> route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error during logout: $e')));
        }
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.inAppWebView)) {
      throw Exception('Could not launch $url');
    }
  }
}
