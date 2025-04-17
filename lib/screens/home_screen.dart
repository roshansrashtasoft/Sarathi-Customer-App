import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:sarathi_customer/screens/profile_screen.dart';
import 'package:sarathi_customer/services/customer_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'document_slider_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> mediaItems = [];
  VideoPlayerController? _videoController;
  final CustomerService _customerService = CustomerService();
  late final Stream<QuerySnapshot> _customerStream;
  
  @override
  void initState() {
    super.initState();
    _carouselController = CarouselSliderController();
    _fetchMedia();
    _customerStream = _customerService.getCurrentCustomerStream();
  }

  Future<void> _fetchMedia() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('marketing_images')
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        for (var doc in querySnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['files'] != null) {
            final files = List<Map<String, dynamic>>.from(data['files']);
            // Convert Google Drive view URLs to direct download URLs
            final processedFiles = files.map((file) {
              if (file['url'] != null && file['url'].toString().contains('drive.google.com')) {
                final fileId = _extractDriveFileId(file['url'].toString());
                file['url'] = 'https://drive.google.com/uc?export=view&id=$fileId';
              }
              return file;
            }).toList();
            
            setState(() {
              mediaItems.addAll(processedFiles);
            });
          }
        }
        if (mediaItems.isNotEmpty) {
          _initializeFirstVideo();
        }
      }
    } catch (e) {
      print('Error fetching media: $e');
    }
  }

  String _extractDriveFileId(String url) {
    final RegExp regExp = RegExp(r'/d/([a-zA-Z0-9_-]+)');
    final match = regExp.firstMatch(url);
    return match?.group(1) ?? '';
  }

  Widget _buildSlider() {
    if (mediaItems.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return CarouselSlider.builder(
      itemCount: mediaItems.length,
      options: CarouselOptions(
        height: 240,
        viewportFraction: 1.0,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 5),
        onPageChanged: (index, reason) {
          _handlePageChange(index);
        },
      ),
      itemBuilder: (context, index, _) {
        final media = mediaItems[index];
        
        if (media['type'] == 'video') {
          return _buildVideoItem(media['url']);
        } else {
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
            ),
            child: Image.network(
              media['url'],
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / 
                          loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                print('Image error: $error');
                return Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.error_outline, size: 40, color: Colors.red),
                  ),
                );
              },
            ),
          );
        }
      },
    );
  }

  void _initializeFirstVideo() async {
    if (mediaItems.first['type'] == 'video') {
      _videoController = VideoPlayerController.network(mediaItems.first['url'])
        ..initialize().then((_) {
          setState(() {});
          _videoController?.play();
        });
    }
  }

  Widget _buildVideoItem(String url) {
    if (_videoController?.dataSource != url) {
      _videoController?.dispose();
      _videoController = VideoPlayerController.network(url)
        ..initialize().then((_) {
          setState(() {});
          _videoController?.play();
        });
    }

    return _videoController?.value.isInitialized == true
        ? AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          )
        : const Center(child: CircularProgressIndicator());
  }

  void _handlePageChange(int index) {
    final currentMedia = mediaItems[index];
    if (currentMedia['type'] == 'video') {
      _videoController?.dispose();
      _videoController = VideoPlayerController.network(currentMedia['url'])
        ..initialize().then((_) {
          setState(() {});
          _videoController?.play();
        });
    } else {
      _videoController?.dispose();
      _videoController = null;
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }
  int _currentIndex = 0;
  DateFormat dateFormat = DateFormat("dd MMMM yyyy");
  CarouselSliderController? _carouselController;



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

  // Future<void> _fetchMedia() async {
  //   final doc = await FirebaseFirestore.instance
  //       .collection('marketing_images')
  //       .get();
  //
  //   if (doc.docs.isNotEmpty) {
  //     final files = doc.docs.first['files'];
  //     setState(() {
  //       mediaItems = List<Map<String, dynamic>>.from(files);
  //     });
  //     _prepareVideoIfNeeded(0);
  //   }
  // }

  void _prepareVideoIfNeeded(int index) async {
    final media = mediaItems[index];
    if (media['type'] == 'video') {
      _videoController?.dispose();
      _videoController = VideoPlayerController.network(media['url']);
      await _videoController!.initialize();
      _videoController!.play();
      _videoController!.setLooping(false);
      _videoController!.addListener(() {
        if (_videoController!.value.position >= _videoController!.value.duration) {
          _carouselController?.nextPage();
        }
      });
      setState(() {});
    }
  }

  void _videoEndListener() {
    if (_videoController != null &&
        _videoController!.value.position >= _videoController!.value.duration &&
        !_videoController!.value.isPlaying) {
      _carouselController?.nextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppbar(),
      body: Column(
        children: [
          SizedBox(
            height: 240,
            child: _buildSlider(),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (data['documents'] != null) ...[
                          const SizedBox(height: 24),
                          _buildSectionTitle('Documents'),
                          const SizedBox(height: 16),
                          _buildDocumentsGrid(data['documents'] as List),
                        ],
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppbar() {
    return AppBar(
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
          icon: const Icon(Icons.logout, color: Colors.black87),
        )
      ],
    );
  }


  // Widget _buildSlider() {
  //   return mediaItems.isEmpty
  //       ? const Center(child: CircularProgressIndicator())
  //       : CarouselSlider.builder(
  //     itemCount: mediaItems.length,
  //     carouselController: _carouselController,
  //     options: CarouselOptions(
  //       viewportFraction: 1.0,
  //       autoPlay: false,
  //       height: double.infinity,
  //       onPageChanged: (index, reason) {
  //         setState(() => _currentIndex = index);
  //         _prepareVideoIfNeeded(index);
  //       },
  //     ),
  //     itemBuilder: (context, index, _) {
  //       final media = mediaItems[index];
  //       final url = media['url'];
  //
  //       if (media['type'] == 'image') {
  //         return Image.network(
  //           url,
  //           fit: BoxFit.cover,
  //           width: double.infinity,
  //           errorBuilder: (context, error, stackTrace) =>
  //           const Center(child: Text("Image failed to load")),
  //         );
  //       } else if (media['type'] == 'video') {
  //         if (_videoController != null && _videoController!.value.isInitialized) {
  //           return AspectRatio(
  //             aspectRatio: _videoController!.value.aspectRatio,
  //             child: VideoPlayer(_videoController!),
  //           );
  //         } else {
  //           return const Center(child: CircularProgressIndicator());
  //         }
  //       } else {
  //         return const Center(child: Text("Unsupported media type"));
  //       }
  //     },
  //   );
  // }


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
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        await FirebaseAuth.instance.signOut();
        if (context.mounted) {
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

}
