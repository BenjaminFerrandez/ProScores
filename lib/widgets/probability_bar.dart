import 'package:flutter/material.dart';
import '../config/theme.dart';

class ProbabilityBar extends StatelessWidget {
  const ProbabilityBar(
      {super.key, required this.probability, required this.oddLabel});
  final double probability;
  final String oddLabel;

  @override
  Widget build(BuildContext context) {
    final pct = (probability * 100).round();
    return Row(
      children: [
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.dark,
                  borderRadius: BorderRadius.zero,
                ),
              ),
              FractionallySizedBox(
                widthFactor: probability.clamp(0.0, 1.0),
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Text('$pct%',
                      style: tabularNumberStyle(const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white))),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 44,
          child: Text(oddLabel,
              textAlign: TextAlign.right,
              style: tabularNumberStyle(TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.light))),
        ),
      ],
    );
  }
}
