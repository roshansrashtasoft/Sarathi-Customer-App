import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sarathi_customer/screens/profile_screen.dart';
import 'package:sarathi_customer/services/customer_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'document_slider_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'login_screen.dart';
import 'package:dio/dio.dart';

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
  final Dio _dio = Dio();
  final Map<String, double> _downloadProgress = {};

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
            final processedFiles = files.map((file) {
              if (file['url'] != null && file['url'].toString().contains('drive.google.com')) {
                final fileId = _extractDriveFileId(file['url'].toString());
                // Use direct download URL for videos
                file['url'] = file['type'] == 'video' 
                  ? 'https://drive.google.com/uc?export=download&id=$fileId'
                  : 'https://drive.google.com/uc?export=view&id=$fileId';
              }
              return file;
            }).toList();
            
            setState(() {
              mediaItems.addAll(processedFiles);
            });
          }
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
  final Map<String, VideoPlayerController> _cachedVideoControllers = {};

  Future<String> _getCachedVideoPath(String url) async {
    final fileId = _extractDriveFileId(url);
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$fileId.mp4';
  }

  Future<String> _ensureVideoCached(String url) async {
    final path = await _getCachedVideoPath(url);
    final file = File(path);
    if (await file.exists()) {
      return file.path;
    }
    try {
      await _dio.download(
        url,
        path,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress[url] = received / total;
            });
          }
        },
      );
      return file.path;
    } catch (e) {
      print('Video download error: $e');
      return url;
    }
  }

  Widget _buildVideoItem(String url) {
    return FutureBuilder<String>(
      future: _ensureVideoCached(url),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          final progress = _downloadProgress[url] ?? 0.0;
          return Center(
            child: CircularProgressIndicator(
              value: progress > 0 ? progress : null,
              color: Colors.white,
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: Icon(Icons.error_outline, color: Colors.red, size: 50),
          );
        }
        final videoPath = snapshot.data!;
        if (_cachedVideoControllers.containsKey(videoPath)) {
          _videoController = _cachedVideoControllers[videoPath];
          if (!_videoController!.value.isPlaying) {
            _videoController!.play();
          }
        } else {
          _videoController?.dispose();
          _videoController = videoPath.startsWith('/')
              ? VideoPlayerController.file(File(videoPath))
              : VideoPlayerController.network(videoPath);
          _videoController!.initialize().then((_) {
            if (mounted) {
              setState(() {});
              _videoController?.play();
              _videoController?.setLooping(true);
              _cachedVideoControllers[videoPath] = _videoController!;
            }
          });
        }
        return _videoController?.value.isInitialized == true
            ? AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              )
            : const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
      },
    );
  }

  @override
  void dispose() {
    for (var controller in _cachedVideoControllers.values) {
      controller.dispose();
    }
    _cachedVideoControllers.clear();
    _videoController?.dispose();
    _dio.close();
    super.dispose();
  }

  Widget _buildSlider() {
    if (mediaItems.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        CarouselSlider.builder(
          itemCount: mediaItems.length,
          options: CarouselOptions(
            height: 240,
            viewportFraction: 0.85,
            enlargeCenterPage: true,
            enlargeFactor: 0.2,
            autoPlay: false,
            enableInfiniteScroll: mediaItems.length > 1,
            onPageChanged: (index, reason) {
              setState(() => _currentIndex = index);
              if (reason != CarouselPageChangedReason.manual) {
                _handlePageChange(index);
              }
            },
          ),
          itemBuilder: (context, index, _) {
            final media = mediaItems[index];

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (media['type'] == 'video')
                      _buildVideoItem(media['url'])
                    else
                      CachedNetworkImage(
                        imageUrl: media['url'],
                        fit: BoxFit.cover,
                        memCacheWidth: 800,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        if (mediaItems.length > 1)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: mediaItems.asMap().entries.map((entry) {
                return Container(
                  width: 8.0,
                  height: 8.0,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(
                      _currentIndex == entry.key ? 0.9 : 0.4,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  void _handlePageChange(int index) {
    try {
      final currentMedia = mediaItems[index];
      if (currentMedia['type'] == 'video') {
        _videoController?.dispose();
        _videoController = VideoPlayerController.network(
          currentMedia['url'],
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        )..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _videoController?.play();
            _videoController?.setLooping(true);
          }
        });
      } else {
        _videoController?.dispose();
        _videoController = null;
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted && _currentIndex == index) {
            _carouselController?.nextPage();
          }
        });
      }
      setState(() => _currentIndex = index);
    } catch (e) {
      print('Page change error: $e');
    }
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
