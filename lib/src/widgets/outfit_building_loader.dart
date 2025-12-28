import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Outfit Building Loading Animation
/// Shows clothing items flying in and assembling together
class OutfitBuildingLoader extends StatefulWidget {
  const OutfitBuildingLoader({
    this.size = 200,
    this.color,
    super.key,
  });

  final double size;
  final Color? color;

  @override
  State<OutfitBuildingLoader> createState() => _OutfitBuildingLoaderState();
}

class _OutfitBuildingLoaderState extends State<OutfitBuildingLoader>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _rotationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Main animation controller (2 seconds loop)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Rotation controller for items
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    // Fade in/out animation
    _fadeAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Scale pulse animation
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_controller, _rotationController]),
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Center hanger
              _buildHanger(color),

              // Shirt (top)
              _buildClothingItem(
                icon: Icons.checkroom,
                angle: 0,
                distance: _getDistance(0),
                color: color,
                delay: 0,
              ),

              // Pants (right)
              _buildClothingItem(
                icon: Icons.dry_cleaning,
                angle: math.pi / 2,
                distance: _getDistance(0.25),
                color: color,
                delay: 0.25,
              ),

              // Shoes (bottom)
              _buildClothingItem(
                icon: Icons.shopping_bag,
                angle: math.pi,
                distance: _getDistance(0.5),
                color: color,
                delay: 0.5,
              ),

              // Accessories (left)
              _buildClothingItem(
                icon: Icons.watch,
                angle: 3 * math.pi / 2,
                distance: _getDistance(0.75),
                color: color,
                delay: 0.75,
              ),
            ],
          );
        },
      ),
    );
  }

  /// Calculate distance based on animation progress
  double _getDistance(double delay) {
    final progress = (_controller.value + delay) % 1.0;

    // Items move in and out
    if (progress < 0.5) {
      // Moving in (from far to center)
      return 60 * (1 - (progress * 2));
    } else {
      // Moving out (from center to far)
      return 60 * ((progress - 0.5) * 2);
    }
  }

  /// Build the center hanger icon
  Widget _buildHanger(Color color) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Icon(
          Icons.checkroom_outlined,
          size: widget.size * 0.25,
          color: color.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  /// Build individual clothing item
  Widget _buildClothingItem({
    required IconData icon,
    required double angle,
    required double distance,
    required Color color,
    required double delay,
  }) {
    final progress = (_controller.value + delay) % 1.0;

    // Calculate opacity based on position
    final opacity = progress < 0.5
        ? 0.3 + (progress * 1.4) // Fade in
        : 1.3 - ((progress - 0.5) * 1.4); // Fade out

    // Calculate position
    final x = distance * math.cos(angle);
    final y = distance * math.sin(angle);

    // Calculate rotation
    final rotation = _rotationController.value * 2 * math.pi;

    return Transform.translate(
      offset: Offset(x, y),
      child: Transform.rotate(
        angle: rotation,
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Icon(
            icon,
            size: widget.size * 0.15,
            color: color,
          ),
        ),
      ),
    );
  }
}
