import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/theme.dart';

void main() => runApp(const ProviderScope(child: ProScoresApp()));

class ProScoresApp extends StatelessWidget {
  const ProScoresApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'ProScores',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const Scaffold(body: Center(child: Text('ProScores'))),
      );
}
