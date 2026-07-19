import 'dart:async';
import 'package:flutter/material.dart';

class DropchopSplashScreen extends StatefulWidget {
  final String nextRoute;

  const DropchopSplashScreen({super.key, required this.nextRoute});

  @override
  State<DropchopSplashScreen> createState() => _DropchopSplashScreenState();
}

class _DropchopSplashScreenState extends State<DropchopSplashScreen> {
  @override
  void initState() {
    super.initState();
    // Show the splash for a moment, then continue to whatever route
    // main() already decided on (welcome, selectUser, buyerHome, etc).
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(widget.nextRoute);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF32BB78), 
      body: Stack(
        children: [
          Center(
            child: Image.asset(
              'images/logo.png',
              width: size.width * 0.30,
              height: size.width * 0.30,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.restaurant_menu_rounded,
                size: size.width * 0.30,
                color: Colors.white,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 50.0),
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 24,
                    letterSpacing: -0.8,
                  ),
                  children: [
                    TextSpan(
                      text: 'Drop',
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                    TextSpan(
                      text: 'Chop',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFE8F5E9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}