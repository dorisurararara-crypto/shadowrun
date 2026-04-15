import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadowrun/core/services/sfx_service.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  const SplashScreen({super.key, this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    SfxService().splash();
    SfxService().heartbeatSingle();

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        if (widget.onComplete != null) {
          widget.onComplete!();
        } else {
          context.go('/');
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Image.asset(
            'assets/icon/splash_logo.png',
            width: screenWidth * 0.75,
            height: screenWidth * 0.75,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
