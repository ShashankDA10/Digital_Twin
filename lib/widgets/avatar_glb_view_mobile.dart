import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/app_theme.dart';

class AvatarGlbView extends StatefulWidget {
  final double size;
  const AvatarGlbView({super.key, this.size = 140});

  @override
  State<AvatarGlbView> createState() => _AvatarGlbViewState();
}

class _AvatarGlbViewState extends State<AvatarGlbView>
    with SingleTickerProviderStateMixin {
  late final WebViewController _controller;
  bool _loaded = false;

  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0C1323))
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _loaded = true);
        },
      ))
      ..loadFlutterAsset('assets/avatar.html');
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Shimmer placeholder while loading
        if (!_loaded)
          AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, _) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Opacity(
                    opacity: 0.3 + _shimmerController.value * 0.4,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: widget.size * 0.45,
                          color: AppColors.accentBlue,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: AppColors.accentBlue.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        AnimatedOpacity(
          opacity: _loaded ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
          child: WebViewWidget(controller: _controller),
        ),
      ],
    );
  }
}
