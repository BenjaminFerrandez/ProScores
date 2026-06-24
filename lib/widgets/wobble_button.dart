import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/assets.dart';

/// Full-width call-to-action using the hand-drawn rectangle SVG. The lighter
/// front face (and label) slides toward the shadow on press for a tactile feel.
class WobbleButton extends StatefulWidget {
  const WobbleButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 64,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;

  @override
  State<WobbleButton> createState() => _WobbleButtonState();
}

class _WobbleButtonState extends State<WobbleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled
            ? (_) {
                setState(() => _pressed = false);
                widget.onPressed!();
              }
            : null,
        onTapCancel: () => setState(() => _pressed = false),
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: Stack(
            children: [
              // Fixed shadow / back face.
              Positioned.fill(
                child: SvgPicture.asset(Assets.buttonRectangleBack,
                    fit: BoxFit.fill),
              ),
              // Lighter front face + label, slides toward the shadow on press.
              Positioned.fill(
                child: AnimatedSlide(
                  offset: _pressed ? const Offset(0.015, 0.07) : Offset.zero,
                  duration: const Duration(milliseconds: 90),
                  curve: Curves.easeOut,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: SvgPicture.asset(Assets.buttonRectangleFront,
                            fit: BoxFit.fill),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          widget.label.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small square button using the square SVG background with a centered icon.
class SquareIconButton extends StatelessWidget {
  const SquareIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 44,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: size,
        width: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: SvgPicture.asset(Assets.buttonSquare, fit: BoxFit.fill),
            ),
            Icon(icon, color: Colors.white, size: size * 0.5),
          ],
        ),
      ),
    );
  }
}
