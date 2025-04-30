import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class DocumentSliderScreen extends StatefulWidget {
  final List<Map<String, dynamic>> documents;
  final int initialIndex;

  const DocumentSliderScreen({
    Key? key,
    required this.documents,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<DocumentSliderScreen> createState() => _DocumentSliderScreenState();
}

class _DocumentSliderScreenState extends State<DocumentSliderScreen> {
  late PageController _pageController;
  final Dio _dio = Dio();
  final Map<String, String> _cachedPaths = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _precacheDocuments();
  }

  void _precacheDocuments() {
    for (var doc in widget.documents) {
      if (doc['type'] == 'pdf') {
        _downloadAndCachePdf(doc['url']).then((path) {
          if (path.isNotEmpty) {
            _cachedPaths[doc['url']] = path;
          }
        });
      } else {
        _downloadAndCacheImage(doc['url']).then((path) {
          if (path.isNotEmpty) {
            _cachedPaths[doc['url']] = path;
          }
        });
      }
    }
  }

  Future<String> _downloadAndCachePdf(String url) async {
    try {
      // Check if already cached in memory
      if (_cachedPaths.containsKey(url)) {
        final file = File(_cachedPaths[url]!);
        if (await file.exists() && (await file.length()) > 0) {
          return _cachedPaths[url]!;
        }
      }

      final dir = await getApplicationDocumentsDirectory();
      final fileId = _extractDriveFileId(url);
      final filePath = '${dir.path}/$fileId.pdf';

      // Check if file exists in storage
      final file = File(filePath);
      if (await file.exists()) {
        if ((await file.length()) > 0) {
          _cachedPaths[url] = filePath;
          return filePath;
        } else {
          await file.delete();
        }
      }

      final downloadUrl = _getDirectGoogleDriveUrl(url);
      final response = await _dio.get(
        downloadUrl,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        await file.writeAsBytes(response.data);
        _cachedPaths[url] = filePath;
        return filePath;
      }
      return '';
    } catch (e) {
      print('Error downloading PDF: $e');
      return '';
    }
  }

  Widget _buildPdfViewer(String url) {
    // Check if already cached in memory
    if (_cachedPaths.containsKey(url)) {
      final file = File(_cachedPaths[url]!);
      return SfPdfViewer.file(file);
    }

    return FutureBuilder<String>(
      future: _downloadAndCachePdf(url),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'Error loading PDF',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        return SfPdfViewer.file(
          File(snapshot.data!),
          canShowScrollHead: true,
          enableDoubleTapZooming: true,
        );
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _dio.close();
    _cachedPaths.clear();
    super.dispose();
  }

  String _getDirectGoogleDriveUrl(String url) {
    final regex = RegExp(r'/d/([a-zA-Z0-9_-]+)');
    final match = regex.firstMatch(url);
    if (match != null && match.groupCount >= 1) {
      final fileId = match.group(1);
      return 'https://drive.google.com/uc?export=download&id=$fileId';
    }
    return url;
  }

  String _extractDriveFileId(String url) {
    final regex = RegExp(r'/d/([a-zA-Z0-9_-]+)');
    final match = regex.firstMatch(url);
    return match?.group(1) ?? DateTime.now().millisecondsSinceEpoch.toString();
  }

  Future<String> _downloadAndCacheImage(String url) async {
    try {
      // Check if already cached in memory
      if (_cachedPaths.containsKey(url)) {
        final file = File(_cachedPaths[url]!);
        if (await file.exists() && (await file.length()) > 0) {
          return _cachedPaths[url]!;
        }
      }

      final dir = await getApplicationDocumentsDirectory();
      final fileId = _extractDriveFileId(url);
      final filePath = '${dir.path}/$fileId.jpg';

      // Check if file exists in storage
      final file = File(filePath);
      if (await file.exists()) {
        if ((await file.length()) > 0) {
          _cachedPaths[url] = filePath;
          return filePath;
        } else {
          await file.delete();
        }
      }

      final downloadUrl = _getDirectGoogleDriveUrl(url);
      final response = await _dio.get(
        downloadUrl,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        await file.writeAsBytes(response.data);
        _cachedPaths[url] = filePath;
        return filePath;
      }
      return '';
    } catch (e) {
      print('Error downloading image: $e');
      return '';
    }
  }

  Widget _buildImageViewer(String url) {
    // Check if already cached in memory
    if (_cachedPaths.containsKey(url)) {
      final file = File(_cachedPaths[url]!);
      return Image.file(
        file,
        fit: BoxFit.contain,
      );
    }

    return FutureBuilder<String>(
      future: _downloadAndCacheImage(url),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'Error loading image',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        return Image.file(
          File(snapshot.data!),
          fit: BoxFit.contain,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.documents.length,
            onPageChanged: (index) {
              setState(() {});
            },
            itemBuilder: (context, index) {
              final doc = widget.documents[index];
              return doc['type'] == 'pdf'
                  ? _buildPdfViewer(doc['url'])
                  : _buildImageViewer(doc['url']);
            },
          ),
        ],
      ),
    );
  }
}
