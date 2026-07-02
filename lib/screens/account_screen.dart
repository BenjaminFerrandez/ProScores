import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
          backgroundColor: AppColors.dark, title: const Text('Mon compte')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(user.email,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          Text('Membre depuis le ${DateFormat('d MMM yyyy', 'fr_FR').format(user.createdAt)}',
              style: TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 20),

          const _SectionTitle('Préférences'),
          Container(
            decoration: BoxDecoration(
                color: AppColors.card, borderRadius: BorderRadius.circular(12)),
            child: SwitchListTile(
              value: ref.watch(themeModeProvider) == ThemeMode.dark,
              onChanged: (_) =>
                  ref.read(themeModeProvider.notifier).toggle(),
              activeThumbColor: AppColors.teal,
              title: const Text('Thème sombre',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              secondary: Icon(
                  ref.watch(themeModeProvider) == ThemeMode.dark
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  color: AppColors.teal),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.card, borderRadius: BorderRadius.circular(12)),
            child: Text(
                '⚠️ Démo pédagogique : les comptes sont stockés localement '
                'sur cet appareil. Aucun argent réel n\'est impliqué.',
                style: TextStyle(color: AppColors.muted, fontSize: 11)),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
            style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE35F5F),
                side: const BorderSide(color: Color(0xFFE35F5F)),
                minimumSize: const Size.fromHeight(48)),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Se déconnecter',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text.toUpperCase(),
            style: const TextStyle(
                color: AppColors.teal,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 1)),
      );
}
