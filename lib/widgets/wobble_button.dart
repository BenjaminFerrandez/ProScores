import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/assets.dart';

/// Captures the pressed state via raw pointer events (so it shows instantly
/// even inside a scrollable, where a tap recognizer would be delayed by the
/// gesture arena) and triggers [onPressed] on a real tap.
class _PressFeedback extends StatefulWidget {
  const _PressFeedback({required this.onPressed, required this.builder});
  final VoidCallback? onPressed;
  final Widget Function(bool pressed) builder;

  @override
  State<_PressFeedback> createState() => _PressFeedbackState();
}

class _PressFeedbackState extends State<_PressFeedback> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    void set(bool v) {
      if (_pressed != v) setState(() => _pressed = v);
    }

    return Listener(
      onPointerDown: enabled ? (_) => set(true) : null,
      onPointerUp: enabled ? (_) => set(false) : null,
      onPointerCancel: enabled ? (_) => set(false) : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? widget.onPressed : null,
        child: widget.builder(enabled && _pressed),
      ),
    );
  }
}

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
    return Opacity(
      opacity: onPressed != null ? 1 : 0.5,
      child: _PressFeedback(
        onPressed: onPressed,
        builder: (pressed) => SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(
            children: [
              Positioned.fill(
                child: SvgPicture.asset(Assets.buttonRectangleBack,
                    fit: BoxFit.fill),
              ),
              Positioned.fill(
                child: AnimatedSlide(
                  offset: pressed ? const Offset(0.015, 0.07) : Offset.zero,
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
            ],
          ),
        ),
      ),
    );
  }
}

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
    return _PressFeedback(
      onPressed: onPressed,
      builder: (pressed) => SizedBox(
        height: size,
        width: size,
        child: Stack(
          children: [
            Positioned.fill(
              child:
                  SvgPicture.asset(Assets.buttonSquareBack, fit: BoxFit.fill),
            ),
            Positioned.fill(
              child: AnimatedSlide(
                offset: pressed ? const Offset(0.08, 0.10) : Offset.zero,
                duration: const Duration(milliseconds: 90),
                curve: Curves.easeOut,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: SvgPicture.asset(Assets.buttonSquareFront,
                          fit: BoxFit.fill),
                    ),
                    Icon(icon, color: Colors.white, size: size * 0.5),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
