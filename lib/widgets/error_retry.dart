import 'package:flutter/material.dart';
import '../config/theme.dart';

class ErrorRetry extends StatelessWidget {
  const ErrorRetry({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 12),
            FilledButton(
                onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      );
}
