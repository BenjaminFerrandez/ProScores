import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../config/constants.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    if (user == null) return const SizedBox.shrink();
    final referrals = ref.read(authControllerProvider.notifier).myReferrals();

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
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 20),

          // Commission balance
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.teal)),
            child: Column(
              children: [
                const Text('Mes commissions',
                    style: TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
                const SizedBox(height: 4),
                Text('${user.commissionBalance.toStringAsFixed(2)} €',
                    style: tabularNumberStyle(const TextStyle(
                        color: AppColors.teal,
                        fontWeight: FontWeight.w800,
                        fontSize: 32))),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Affiliate code
          const _SectionTitle('Mon code de parrainage'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: AppColors.card, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Expanded(
                  child: Text(user.affiliateCode,
                      style: tabularNumberStyle(const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          letterSpacing: 3))),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: AppColors.teal),
                  tooltip: 'Copier',
                  onPressed: () {
                    Clipboard.setData(
                        ClipboardData(text: user.affiliateCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copié !')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
              'Partage ce code : tu gagnes ${kReferralCommission.toStringAsFixed(0)} € '
              '(virtuels) à chaque inscription avec ton code.',
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 18),

          // Referrals list
          _SectionTitle('Mes filleuls (${referrals.length})'),
          if (referrals.isEmpty)
            const Text('Personne ne s\'est encore inscrit avec ton code.',
                style: TextStyle(color: AppColors.muted))
          else
            ...referrals.map((r) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: AppColors.muted, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(r.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13))),
                      Text('+${kReferralCommission.toStringAsFixed(0)} €',
                          style: const TextStyle(
                              color: AppColors.teal,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ],
                  ),
                )),

          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.card, borderRadius: BorderRadius.circular(12)),
            child: const Text(
                '⚠️ Démo pédagogique : les commissions sont fictives et stockées '
                'localement. Aucun argent réel n\'est impliqué.',
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
