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

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  String _getDirectGoogleDriveUrl(String url) {
    final regex = RegExp(r'/d/([a-zA-Z0-9_-]+)');
    final match = regex.firstMatch(url);
    if (match != null && match.groupCount >= 1) {
      final fileId = match.group(1);
      // Use export=download for PDF files to get the actual file instead of the viewer
      return 'https://drive.google.com/uc?export=download&id=$fileId';
    }
    return url;
  }

  Future<String> _downloadAndCachePdf(String url) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileId = _extractDriveFileId(url);
      final filePath = '${dir.path}/$fileId.pdf';

      // Check if file already exists
      final file = File(filePath);
      if (await file.exists()) {
        // Verify file is not empty
        if ((await file.length()) > 0) {
          return filePath;
        } else {
          await file.delete(); // Delete empty file
        }
      }

      // Get the direct download URL
      final downloadUrl = _getDirectGoogleDriveUrl(url);
      print('Downloading PDF from: $downloadUrl'); // Debug log

      // Download the file
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
        print('PDF downloaded successfully to: $filePath'); // Debug log
        return filePath;
      } else {
        print(
          'Failed to download PDF. Status: ${response.statusCode}',
        ); // Debug log
        return '';
      }
    } catch (e) {
      print('Error downloading PDF: $e');
      return '';
    }
  }

  String _extractDriveFileId(String url) {
    final regex = RegExp(r'/d/([a-zA-Z0-9_-]+)');
    final match = regex.firstMatch(url);
    return match?.group(1) ?? DateTime.now().millisecondsSinceEpoch.toString();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _dio.close();
    super.dispose();
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
                  : Image.network(
                    _getDirectGoogleDriveUrl(doc['url']),
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value:
                              loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                          color: Colors.white,
                        ),
                      );
                    },
                  );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPdfViewer(String url) {
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

        return SfPdfViewer.file(File(snapshot.data!));
      },
    );
  }
}
