import 'package:flutter/material.dart';

/// Static advertisement slot placeholder (no real ad network in the MVP).
class AdPlaceholder extends StatelessWidget {
  const AdPlaceholder({super.key, this.height = 72});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: const Color(0xFFF45B5B),
      child: Stack(
        children: [
          const Center(
            child: Text('Espace publicitaire',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ),
          Positioned(
            right: 8,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              color: Colors.black.withValues(alpha: 0.35),
              child: const Text('AD',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 10)),
            ),
          ),
        ],
      ),
    );
  }
}
