import 'package:flutter/material.dart';
class MatchDetailScreen extends StatelessWidget {
  const MatchDetailScreen({super.key, required this.fixtureId});
  final int fixtureId;
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Détail')));
}
