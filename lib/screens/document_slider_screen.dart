import 'package:flutter/material.dart';

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
      return 'https://drive.google.com/uc?export=view&id=$fileId';
    }
    return url;
  }

  @override
  void dispose() {
    _pageController.dispose();
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
              setState(() {
              });
            },
            itemBuilder: (context, index) {
              final doc = widget.documents[index];
              return doc['type'] == 'pdf'
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.picture_as_pdf,
                            size: 72,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            doc['name'],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    )
                  : Image.network(
                      _getDirectGoogleDriveUrl(doc['url']),
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
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
          // Navigation arrows
          // Positioned.fill(
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //     children: [
          //       IconButton(
          //         icon: const Icon(Icons.arrow_left, color: Colors.white, size: 40),
          //         onPressed: _currentIndex > 0
          //             ? () {
          //                 _pageController.previousPage(
          //                   duration: const Duration(milliseconds: 300),
          //                   curve: Curves.easeInOut,
          //                 );
          //               }
          //             : null,
          //       ),
          //       IconButton(
          //         icon: const Icon(Icons.arrow_right, color: Colors.white, size: 40),
          //         onPressed: _currentIndex < widget.documents.length - 1
          //             ? () {
          //                 _pageController.nextPage(
          //                   duration: const Duration(milliseconds: 300),
          //                   curve: Curves.easeInOut,
          //                 );
          //               }
          //             : null,
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }
}