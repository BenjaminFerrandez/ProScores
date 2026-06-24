import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/assets.dart';

/// Kickoff-time badge drawn on the hand-drawn "case temps" SVG background,
/// with the time label centered on top.
class TimeChip extends StatelessWidget {
  const TimeChip(this.time, {super.key, this.height = 26});
  final String time;
  final double height;

  @override
  Widget build(BuildContext context) {
    // Keep the SVG's native 53x25 aspect ratio.
    final width = height * (53 / 25);
    return SizedBox(
      height: height,
      width: width,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: SvgPicture.asset(Assets.caseTemps, fit: BoxFit.fill),
          ),
          Text(time,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12)),
        ],
      ),
    );
  }
}
