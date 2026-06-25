import 'package:flutter/material.dart';
import '../config/theme.dart';

class ResponsibleGamingNote extends StatelessWidget {
  const ResponsibleGamingNote({super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          '🔞 Jeu responsable — pariez avec modération. Les pronostics ne '
          'garantissent aucun gain.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      );
}
