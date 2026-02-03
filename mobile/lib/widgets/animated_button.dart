import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// High-performance animated button with:
/// - Tap scale animation (0.95 → 1.0)
/// - Haptic feedback on interaction
/// - Smooth visual feedback
/// - Optimized frame rate (60fps)
class AnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Duration duration;
  final Curve curve;
  final bool enableHaptics;
  final double minScale;
  
  const AnimatedButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.duration = const Duration(milliseconds: 100),
    this.curve = Curves.easeOutCubic,
    this.enableHaptics = true,
    this.minScale = 0.95,
  }) : super(key: key);

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.minScale).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTapDown(TapDownDetails details) async {
    setState(() => _isPressed = true);
    
    if (widget.enableHaptics) {
      await HapticFeedback.lightImpact();
    }
    
    _controller.forward();
  }

  Future<void> _handleTapUp(TapUpDetails details) async {
    _controller.reverse();
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    _controller.reverse();
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Enhanced button variant with built-in Material styling
class AnimatedElevatedButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final IconData? icon;
  final bool enableHaptics;

  const AnimatedElevatedButton({
    Key? key,
    required this.onPressed,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 44,
    this.borderRadius,
    this.icon,
    this.enableHaptics = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Theme.of(context).primaryColor;
    final textCol = textColor ?? Colors.white;

    return AnimatedButton(
      onPressed: onPressed,
      enableHaptics: enableHaptics,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: bgColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: icon != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: textCol, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: textCol,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              )
            : Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: textCol,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
      ),
    );
  }
}

/// Icon button variant with haptic feedback
class AnimatedIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final Color? color;
  final double size;
  final bool enableHaptics;
  final EdgeInsets padding;

  const AnimatedIconButton({
    Key? key,
    required this.onPressed,
    required this.icon,
    this.color,
    this.size = 24,
    this.enableHaptics = true,
    this.padding = const EdgeInsets.all(8),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedButton(
      onPressed: onPressed,
      enableHaptics: enableHaptics,
      child: Padding(
        padding: padding,
        child: Icon(
          icon,
          color: color ?? Theme.of(context).iconTheme.color,
          size: size,
        ),
      ),
    );
  }
}
