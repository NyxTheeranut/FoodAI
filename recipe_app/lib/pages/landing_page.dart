import 'package:flutter/material.dart';
import 'package:recipe_app/pages/ingredients_page.dart';
import 'dart:ui';
import 'dart:math' as math;

class LandingPage extends StatefulWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _logoController;
  late Animation<double> _logoPulseAnimation;

  @override
  void initState() {
    super.initState();
    // Animation for the moving background
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Animation for the logo pulsing effect
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _logoPulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Background with Moving Circles
          AnimatedBackground(animationController: _animationController),
          // Blurred Overlay for the Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.withOpacity(0.7),
                  Colors.blueGrey.withOpacity(0.7),
                  Colors.white.withOpacity(0.7),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          // Foreground Content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // App Logo (Replaced "RA" with an Icon)
                ScaleTransition(
                  scale: _logoPulseAnimation,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.restaurant_menu,
                        size: 80,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Title
                const Text(
                  'Welcome to Recipe App',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 20),
                // Description with blurred background
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        color: Colors.white.withOpacity(0.15),
                        child: const Text(
                          'Discover delicious recipes tailored to your ingredients and nutritional needs.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                // Get Started Button with Animation
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: AnimatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => const IngredientsPage(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            const begin = Offset(1.0, 0.0);
                            const end = Offset.zero;
                            const curve = Curves.easeInOut;
                            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                            var offsetAnimation = animation.drive(tween);
                            return SlideTransition(
                              position: offsetAnimation,
                              child: child,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Animated Background with Moving Circles
class AnimatedBackground extends StatelessWidget {
  final AnimationController animationController;

  const AnimatedBackground({Key? key, required this.animationController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue.withOpacity(0.3), // Base color for the background
      child: AnimatedBuilder(
        animation: animationController,
        builder: (context, child) {
          return Stack(
            children: [
              MovingCircle(
                animation: animationController,
                size: 100,
                color: Colors.white.withOpacity(0.3),
                offsetX: 0.3,
                offsetY: 0.5,
              ),
              MovingCircle(
                animation: animationController,
                size: 80,
                color: Colors.blue.withOpacity(0.4),
                offsetX: 0.7,
                offsetY: 0.2,
              ),
              MovingCircle(
                animation: animationController,
                size: 120,
                color: Colors.blueGrey.withOpacity(0.3),
                offsetX: 0.5,
                offsetY: 0.8,
              ),
            ],
          );
        },
      ),
    );
  }
}

// Widget for a single moving circle
class MovingCircle extends StatelessWidget {
  final Animation<double> animation;
  final double size;
  final Color color;
  final double offsetX;
  final double offsetY;

  const MovingCircle({
    Key? key,
    required this.animation,
    required this.size,
    required this.color,
    required this.offsetX,
    required this.offsetY,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Positioned(
      left: math.sin(animation.value * 2 * math.pi + offsetX) * screenWidth * 0.2 + screenWidth * offsetX,
      top: math.cos(animation.value * 2 * math.pi + offsetY) * screenHeight * 0.2 + screenHeight * offsetY,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Animated Button Widget
class AnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;

  const AnimatedButton({Key? key, required this.onPressed}) : super(key: key);

  @override
  _AnimatedButtonState createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () {
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Get Started',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      ),
    );
  }
}