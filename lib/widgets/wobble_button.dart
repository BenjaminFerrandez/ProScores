import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/assets.dart';

/// Full-width call-to-action using the hand-drawn rectangle SVG as background,
/// with a centered label on top.
class WobbleButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: SvgPicture.asset(Assets.buttonRectangle,
                    fit: BoxFit.fill),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  label.toUpperCase(),
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
