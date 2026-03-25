import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AvatarGlbView extends StatefulWidget {
  final double size;
  const AvatarGlbView({super.key, this.size = 140});

  @override
  State<AvatarGlbView> createState() => _AvatarGlbViewState();
}

class _AvatarGlbViewState extends State<AvatarGlbView> {
  late final WebViewController _controller;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _loaded = true);
        },
      ))
      // loadFlutterAsset serves the file from a local HTTPS origin on Android
      // (https://appassets.androidplatform.net/flutter_assets/assets/avatar.html)
      // so model-viewer can fetch "images/avatar.glb" relative to it with no CORS issues.
      ..loadFlutterAsset('assets/avatar.html');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _loaded ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: WebViewWidget(controller: _controller),
    );
  }
}
