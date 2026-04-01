import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../subscriptions/data/subscription_repository.dart';

class VaultScreen extends ConsumerWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(subscriptionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                24, MediaQuery.of(context).padding.top + 20, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vault',
                    style: TextStyle(
                        fontSize: 28, 
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.textLight)),
                const SizedBox(height: 4),
                const Text('Securely store subscription details',
                    style: TextStyle(color: AppTheme.textMutedDark, fontSize: 14)),
              ],
            ),
          ),
        ),
        subscriptionsAsync.when(
          data: (subs) {
            if (subs.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryAccent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock_person_outlined,
                            size: 44, color: AppTheme.primaryAccent),
                      ),
                      const SizedBox(height: 24),
                      const Text('Empty Vault',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMutedDark)),
                    ],
                  ),
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _VaultTile(subscription: subs[index]),
                  childCount: subs.length,
                ),
              ),
            );
          },
          loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator())),
          error: (err, __) => SliverFillRemaining(
              child: Center(child: Text('Error: $err'))),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}

class _VaultTile extends StatelessWidget {
  final dynamic subscription;
  const _VaultTile({required this.subscription});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.surfaceDarkLighter : AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.password_rounded, color: AppTheme.primaryAccent, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subscription.name,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.textLight)),
                Text(subscription.notes ?? 'No credentials stored',
                    style: const TextStyle(color: AppTheme.textMutedDark, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18, color: AppTheme.textMutedDark),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard!')),
              );
            },
          ),
        ],
      ),
    );
  }
}
