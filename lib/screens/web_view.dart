import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebView extends StatefulWidget {
  WebView({required this.arguments, Key? key}) : super(key: key);
  final String arguments;

  @override
  State<WebView> createState() => _WebViewState();
}

class _WebViewState extends State<WebView> {
  String? url;
  bool isLoading = false;
  double progress = 0;

  @override
  void initState() {
    url = widget.arguments;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: IconButton(
        padding: EdgeInsets.all(0),
        constraints: BoxConstraints(maxWidth: 30, maxHeight: 30),
        icon: Icon(Icons.arrow_back_ios, size: 25, color: Colors.black),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      title: Text(
        'Sarathi Innovations',
        style: TextStyle(fontSize: 20, color: Colors.black),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 0,
    );
  }

  Widget _buildBody() {
    return Stack(children: [_buildWebView(), _buildProgressBar()]);
  }

  Widget _buildWebView() {
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(url ?? '')),
      onLoadStart: (controller, url) {
        isLoading = true;
        if (mounted) setState(() {});
      },
      onLoadStop: (controller, url) {
        isLoading = false;
        if (mounted) setState(() {});
      },
      onProgressChanged: (InAppWebViewController controller, int progress) {
        setState(() {
          this.progress = progress / 100;
        });
      },
    );
  }

  Widget _buildProgressBar() {
    if (progress != 1.0) {
      return Align(
        alignment: Alignment.center,
        child: CircularProgressIndicator(),
      );
    }
    return Container();
  }
}
