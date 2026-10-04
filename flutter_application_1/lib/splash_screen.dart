import 'package:flutter/material.dart';
import 'dart:async';
import 'login_page.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => LoginPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: Duration(milliseconds: 800),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: Colors.white),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(),
              // Animated Pet Icon
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      padding: EdgeInsets.all(35),
                      decoration: BoxDecoration(
                        color: Color(0xFFFF6B35),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFFF6B35).withOpacity(0.4),
                            blurRadius: 40,
                            offset: Offset(0, 20),
                          ),
                        ],
                      ),
                      child: Icon(Icons.pets, size: 100, color: Colors.white),
                    ),
                  );
                },
              ),
              SizedBox(height: 50),

              // Animated App Name
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Column(
                      children: [
                        Text(
                          'Pet Care',
                          style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF6B35),
                            letterSpacing: 3,
                            shadows: [
                              Shadow(
                                color: Color(0xFFFF6B35).withOpacity(0.3),
                                offset: Offset(0, 4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          '& Adoption',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w300,
                            color: Colors.grey[700],
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(height: 40),
                        // Loading indicator
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFFF6B35),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              Spacer(),

              // Bottom tagline
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 50),
                      child: Text(
                        'Find Your Perfect Companion',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
