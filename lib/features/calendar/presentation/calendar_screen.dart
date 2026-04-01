import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../subscriptions/data/subscription_repository.dart';
import '../../subscriptions/models/subscription_model.dart';
import '../../../core/currency_provider.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(subscriptionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencySymbol = ref.watch(currencyProvider.notifier).symbol;

    return SafeArea(
      child: subscriptionsAsync.when(
        data: (subs) {
          if (subs.isEmpty) {
            return Center(
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
                    child: const Icon(Icons.calendar_month_outlined,
                        size: 44, color: AppTheme.primaryAccent),
                  ),
                  const SizedBox(height: 24),
                  Text('No upcoming bills',
                      style: TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.textLight)),
                  const SizedBox(height: 8),
                  const Text('Add subscriptions to see your schedule',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textMutedDark)),
                ],
              ),
            );
          }

          final sorted = List<Subscription>.from(subs)
            ..sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));

          final grouped = <String, List<Subscription>>{};
          for (final sub in sorted) {
            final key = DateFormat('MMMM yyyy').format(sub.nextBillingDate);
            grouped.putIfAbsent(key, () => []).add(sub);
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(subscriptionsProvider),
            color: AppTheme.primaryAccent,
            backgroundColor: isDark ? AppTheme.surfaceDarkLighter : Colors.white,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Upcoming Bills',
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppTheme.textLight)),
                        const SizedBox(height: 4),
                        const Text('Sorted by billing date',
                            style: TextStyle(color: AppTheme.textMutedDark, fontSize: 14)),
                        const SizedBox(height: 24),
                        _buildUpcomingSummary(context, subs, currencySymbol),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                ...grouped.entries.map((entry) {
                  return SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 16,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppTheme.primaryAccent, AppTheme.secondaryAccent],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(entry.key.toUpperCase(),
                                  style: const TextStyle(
                                      color: AppTheme.textMutedDark,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: entry.value
                                .map((sub) => _CalendarTile(subscription: sub, currencySymbol: currencySymbol))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryAccent)),
        error: (err, __) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildUpcomingSummary(BuildContext context, List<Subscription> subs, String symbol) {
    final now = DateTime.now();
    final next7Days = now.add(const Duration(days: 7));
    final next30Days = now.add(const Duration(days: 30));

    double spending7Days = 0;
    double spending30Days = 0;

    for (final sub in subs) {
      if (sub.nextBillingDate.isAfter(now)) {
        if (sub.nextBillingDate.isBefore(next7Days)) {
          spending7Days += sub.price;
        }
        if (sub.nextBillingDate.isBefore(next30Days)) {
          spending30Days += sub.price;
        }
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppTheme.surfaceDarkLighter : AppTheme.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Next 7 Days',
                    style: TextStyle(color: AppTheme.textMutedDark, fontSize: 11)),
                const SizedBox(height: 6),
                Text('$symbol${spending7Days.toStringAsFixed(0)}',
                    style: TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold, 
                        color: isDark ? Colors.white : AppTheme.textLight)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppTheme.surfaceDarkLighter : AppTheme.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Next 30 Days',
                    style: TextStyle(color: AppTheme.textMutedDark, fontSize: 11)),
                const SizedBox(height: 6),
                Text('$symbol${spending30Days.toStringAsFixed(0)}',
                    style: TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold, 
                        color: isDark ? Colors.white : AppTheme.textLight)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CalendarTile extends StatelessWidget {
  final Subscription subscription;
  final String currencySymbol;

  const _CalendarTile({required this.subscription, required this.currencySymbol});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOverdue = subscription.nextBillingDate.isBefore(now);
    final daysUntil = subscription.nextBillingDate.difference(now).inDays;
    
    final color = _getCategoryColor(subscription.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverdue 
            ? AppTheme.error.withOpacity(0.3) 
            : (isDark ? AppTheme.surfaceDarkLighter : AppTheme.borderLight)
        ),
      ),
      child: Row(
        children: [
          // Date badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('dd').format(subscription.nextBillingDate),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  DateFormat('EEE').format(subscription.nextBillingDate).toUpperCase(),
                  style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subscription.name,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: isDark ? Colors.white : AppTheme.textLight)),
                Text(
                  isOverdue ? 'Overdue' : 'due in $daysUntil days',
                  style: TextStyle(
                    color: isOverdue ? AppTheme.error : AppTheme.textMutedDark,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$currencySymbol${subscription.price.toStringAsFixed(2)}',
            style: TextStyle(
                fontWeight: FontWeight.bold, 
                color: isDark ? Colors.white : AppTheme.textLight),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Entertainment': return const Color(0xFFFF6B6B);
      case 'Utilities': return const Color(0xFFFFBF47);
      case 'Education': return const Color(0xFF4ECDC4);
      case 'Health': return const Color(0xFFFF8B94);
      default: return AppTheme.primaryAccent;
    }
  }
}
