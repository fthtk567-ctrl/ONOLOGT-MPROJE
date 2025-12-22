import 'package:flutter/material.dart';
import 'dart:async';
import '../services/auth_service.dart';
import 'main_navigation_screen.dart'; // Bottom Navigation yapısı
import 'merchant_login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    // Animasyonu başlat
    _animationController.forward();
    
    // 3 saniye sonra kullanıcı durumunu kontrol et ve uygun sayfaya yönlendir
    _checkUserStatusAndNavigate();
  }

  Future<void> _checkUserStatusAndNavigate() async {
    // Animasyon bitene kadar bekle (1.5 saniye), sonra direkt geç
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (!mounted) { return; }
    
    // AuthService ile kontrol et
    final isLoggedIn = await AuthService.isUserLoggedIn();
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => isLoggedIn 
            ? const MainNavigationScreen()
            : const MerchantLoginPage(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'ON',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50), // Logonuzdaki yeşil
                          letterSpacing: 2.0,
                        ),
                      ),
                      TextSpan(
                        text: 'LOG',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111111), // Logonuzdaki siyah
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}




