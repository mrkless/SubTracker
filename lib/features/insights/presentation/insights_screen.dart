import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../subscriptions/data/subscription_repository.dart';
import '../../subscriptions/models/subscription_model.dart';
import '../../../core/currency_provider.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(subscriptionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencySymbol = ref.watch(currencyProvider.notifier).symbol;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(subscriptionsProvider),
      color: AppTheme.primaryAccent,
      backgroundColor: isDark ? AppTheme.surfaceDarkLighter : Colors.white,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  24, MediaQuery.of(context).padding.top + 20, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Insights',
                      style: TextStyle(
                          fontSize: 28, 
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.textLight)),
                  const SizedBox(height: 4),
                  const Text('Optimize your spending habits',
                      style: TextStyle(color: AppTheme.textMutedDark, fontSize: 14)),
                ],
              ),
            ),
          ),
          subscriptionsAsync.when(
            data: (List<Subscription> subs) {
              if (subs.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('Add subscriptions to see insights', style: TextStyle(color: AppTheme.textMutedDark))),
                );
              }
  
              final totalMonthly = subs.fold<double>(0, (sum, Subscription item) {
                if (item.billingCycle.toLowerCase() == 'monthly') return sum + item.price;
                if (item.billingCycle.toLowerCase() == 'yearly') return sum + (item.price / 12);
                return sum;
              });
  
              final insights = _generateDynamicInsights(subs, currencySymbol);
              final categoryAnalytics = _getCategoryAnalytics(subs);
  
              return SliverList(
                delegate: SliverChildListDelegate([
                  _buildSavingsCard(context, subs, totalMonthly, currencySymbol, categoryAnalytics.length),
                  const SizedBox(height: 32),
                  
                  if (insights.isNotEmpty) ...[
                    _buildInsightTitle('Smart Alerts'),
                    ...insights.map((insight) => _buildAlertTile(
                      context,
                      icon: insight.icon,
                      title: insight.title,
                      desc: insight.message,
                      color: insight.color,
                    )),
                    const SizedBox(height: 24),
                  ],
  
                  _buildInsightTitle('Category Breakdown'),
                  _buildCategoryOptimization(context, subs, categoryAnalytics),
                  const SizedBox(height: 40),
                ]),
              );
            },
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (err, __) => SliverFillRemaining(child: Center(child: Text('Error: $err'))),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildSavingsCard(BuildContext context, List subs, double monthly, String symbol, int categoryCount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate a mock "Health Score" based on consistency and number of categories
    final score = (100 - (subs.length * 2) - (categoryCount * 3)).clamp(40, 98);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryAccent.withOpacity(isDark ? 0.15 : 0.08),
            AppTheme.secondaryAccent.withOpacity(isDark ? 0.05 : 0.02),
          ],
        ),
        border: Border.all(color: AppTheme.primaryAccent.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Yearly Commitment', style: TextStyle(color: AppTheme.textMutedDark, fontSize: 13, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('Live Forecast', style: TextStyle(color: AppTheme.success.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('$symbol${(monthly * 12).toStringAsFixed(2)}', 
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.textLight, letterSpacing: -1)),
          const SizedBox(height: 20),
          const Divider(height: 1, color: AppTheme.textMutedDark),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat('Active', subs.length.toString()),
              _buildStat('Groups', categoryCount.toString()),
              _buildStat('Sub Score', '$score%'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStat(String label, String val) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryAccent)),
        Text(label, style: const TextStyle(color: AppTheme.textMutedDark, fontSize: 12)),
      ],
    );
  }

  Widget _buildInsightTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildAlertTile(BuildContext context, {required IconData icon, required String title, required String desc, required Color color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
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
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.textLight)),
                Text(desc, style: const TextStyle(color: AppTheme.textMutedDark, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryOptimization(BuildContext context, List<Subscription> subs, Map<String, double> analytic) {
    final sorted = analytic.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    if (sorted.isEmpty) return const SizedBox.shrink();

    final topCategory = sorted.first;
    final total = analytic.values.fold<double>(0, (p, c) => p + c);
    final percentage = (topCategory.value / total * 100).toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your highest spending category is ${topCategory.key}, accounting for $percentage% of your monthly budget.',
            style: const TextStyle(color: AppTheme.textMutedDark, fontStyle: FontStyle.italic, fontSize: 13),
          ),
          const SizedBox(height: 16),
          // Simple visual bar
          Container(
            height: 10,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.textMutedDark.withOpacity(0.1),
              borderRadius: BorderRadius.circular(5),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (topCategory.value / total).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.primaryAccent, AppTheme.secondaryAccent]),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_InsightData> _generateDynamicInsights(List<Subscription> subs, String symbol) {
    if (subs.isEmpty) return [];

    final insights = <_InsightData>[];
    final names = subs.map((s) => s.name.toLowerCase()).toList();
    final categories = subs.map((s) => s.category).toList();
    final now = DateTime.now();

    // 1. Math-Based Savings (Always priority)
    final monthlySubs = subs.where((s) => s.billingCycle.toLowerCase() == 'monthly').toList();
    if (monthlySubs.isNotEmpty) {
      final potentialSavings = monthlySubs.fold<double>(0, (p, c) => p + (c.price * 0.15));
      insights.add(_InsightData(
        icon: Icons.auto_graph_rounded,
        title: 'Smart Savings',
        message: 'Annual savings potential: ~$symbol${potentialSavings.toStringAsFixed(0)} by switching to Yearly plans.',
        color: AppTheme.success,
      ));
    }

    // 2. The "Overlapping Music" Alert (Specific Service Context)
    if (names.contains('spotify') && (names.contains('youtube music') || names.contains('apple music'))) {
      insights.add(_InsightData(
        icon: Icons.music_off_rounded,
        title: 'Music Overlap',
        message: 'You have multiple music services. You could save by picking just one premium library!',
        color: AppTheme.error,
      ));
    }

    // 3. Apple One Ecosystem Nudge (Ecosystem Bundling)
    if (names.contains('apple music') && names.contains('icloud+')) {
      insights.add(_InsightData(
        icon: Icons.apple_rounded,
        title: 'Apple One Hack',
        message: 'You\'re paying for Apple Music and iCloud+. Switching to "Apple One" could bundle these and save you up to ${symbol}5/mo.',
        color: AppTheme.primaryAccent,
      ));
    }

    // 4. Duplicate Service Check (Smart Safety)
    final duplicateNames = names.where((n) => names.where((x) => x == n).length > 1).toSet();
    if (duplicateNames.isNotEmpty) {
      insights.add(_InsightData(
        icon: Icons.copy_rounded,
        title: 'Duplicate Alert',
        message: 'You have ${duplicateNames.length} duplicate services (e.g., ${duplicateNames.first}). Is this a mistake?',
        color: AppTheme.error,
      ));
    }

    // 5. Gaming Rotation Strategy (Saturation)
    final gamingCount = subs.where((s) => s.category == 'Gaming').length;
    if (gamingCount >= 3) {
      insights.add(_InsightData(
        icon: Icons.gamepad_rounded,
        title: 'Gaming Rotation',
        message: 'You have $gamingCount active gaming subs. Consider a "Rotation" strategy: Pause what you aren\'t playing!',
        color: AppTheme.primaryAccent,
      ));
    }

    // 6. AI Power Stack (Modern Context)
    bool hasAI = names.contains('chatgpt plus') || names.contains('github copilot') || names.contains('midjourney');
    if (hasAI && names.length > 5) {
       insights.add(_InsightData(
        icon: Icons.bolt_rounded,
        title: 'AI Power User',
        message: 'You have a premium AI stack! Monitor your usage to ensure you\'re getting full value from these high-cost tools.',
        color: AppTheme.primaryAccent,
      ));
    }

    // 7. Streaming Rotator (Max Value)
    final entSubs = subs.where((s) => s.category == 'Entertainment').length;
    if (entSubs >= 4) {
      insights.add(_InsightData(
        icon: Icons.sync_rounded,
        title: 'Streaming Rotator',
        message: 'With $entSubs entertainment subs, you might save ${symbol}30+/mo by rotating services based on new releases.',
        color: AppTheme.secondaryAccent,
      ));
    }

    // 8. Family Share Optimization (Group Spending)
    final streamCount = subs.where((s) => s.category == 'Entertainment' || s.category == 'Music').length;
    if (streamCount >= 5) {
       insights.add(_InsightData(
        icon: Icons.group_work_rounded,
        title: 'Family Plan Audit',
        message: 'With $streamCount streaming services, ensure you\'re using Family Plans where possible to share the cost!',
        color: AppTheme.secondaryAccent,
      ));
    }

    // 9. The "Silent Burner" Alert (Micro-Expenses)
    final microSubs = subs.where((s) => s.price > 0 && s.price < 3).toList();
    if (microSubs.isNotEmpty) {
       final microTotal = microSubs.fold<double>(0, (p, c) => p + (c.price * 12));
       insights.add(_InsightData(
        icon: Icons.blur_on_rounded,
        title: 'Silent Burners',
        message: 'You have ${microSubs.length} low-cost bills ($symbol${microSubs.first.price}). They add up to ~$symbol${microTotal.toStringAsFixed(0)} annually!',
        color: AppTheme.secondaryAccent,
      ));
    }

    // 10. weekend Bill Warning (Cashflow Safety)
    final billsThisWeekend = subs.where((s) => 
      s.nextBillingDate.weekday == DateTime.saturday || 
      s.nextBillingDate.weekday == DateTime.sunday
    ).toList();
    if (billsThisWeekend.isNotEmpty) {
      insights.add(_InsightData(
        icon: Icons.warning_rounded,
        title: 'Weekend Renewal',
        message: '${billsThisWeekend.length} bills are due this weekend. Check for early charges or banking delays!',
        color: AppTheme.warning,
      ));
    }

    // 11. 1st of the Month Spike
    final firstOfMonth = subs.where((s) => s.nextBillingDate.day == 1).length;
    if (firstOfMonth >= 3) {
      insights.add(_InsightData(
        icon: Icons.event_note_rounded,
        title: 'Monthly Cash Crunch',
        message: 'You have $firstOfMonth bills due on the 1st. Consider staggering dates for smoother monthly cashflow.',
        color: AppTheme.error,
      ));
    }

    // 12. Free Trial Shadow (Future Spend)
    final trials = subs.where((s) => s.price == 0).toList();
    if (trials.isNotEmpty) {
      insights.add(_InsightData(
        icon: Icons.timer_outlined,
        title: 'Trial Shadow',
        message: 'You have ${trials.length} active trials. Don\'t forget to cancel before they convert to full-priced bills!',
        color: AppTheme.warning,
      ));
    }

    // 13. Categorization Clean-up
    final otherCount = subs.where((s) => s.category == 'Others').length;
    if (otherCount >= 5) {
       insights.add(_InsightData(
        icon: Icons.label_important_outline_rounded,
        title: 'Clean Up Tip',
        message: 'You have $otherCount items in the "Others" category. Try re-assigning them for better spending analytics!',
        color: AppTheme.primaryAccent,
      ));
    }

    // 14. Long-term Projection (Proactive Finance)
    final monthlyTotal = subs.fold<double>(0, (p, c) {
      if (c.billingCycle.toLowerCase() == 'yearly') return p + (c.price / 12);
      if (c.billingCycle.toLowerCase() == 'weekly') return p + (c.price * 4.33);
      return p + c.price;
    });
    if (monthlyTotal > 150) {
      final twoYearSpent = monthlyTotal * 24;
      insights.add(_InsightData(
        icon: Icons.timeline_rounded,
        title: '2-Year Outlook',
        message: 'At your current rate, you\'ll spend $symbol${twoYearSpent.toStringAsFixed(0)} in 2 years. Is your portfolio optimized?',
        color: AppTheme.warning,
      ));
    }

    // 15. Ghost Subscription Detection (Inactivity)
    final ghostSubs = subs.where((s) => s.nextBillingDate.isBefore(now.subtract(const Duration(days: 1)))).toList();
    if (ghostSubs.isNotEmpty) {
       insights.add(_InsightData(
        icon: Icons.visibility_off_rounded,
        title: 'Ghost Detection',
        message: 'Found ${ghostSubs.length} subscriptions past their due date. Are these still active or should you delete them?',
        color: AppTheme.error,
      ));
    }

    // 16. Balanced Portfolio Nudge (Spend Ratio)
    final entSpend = _getCategoryAnalytics(subs)['Entertainment'] ?? 0;
    final eduSpend = _getCategoryAnalytics(subs)['Education'] ?? 0;
    if (entSpend > eduSpend * 3 && entSpend > 50) {
      insights.add(_InsightData(
        icon: Icons.psychology_alt_rounded,
        title: 'Life Balance Tip',
        message: 'Your Entertainment spend is 3x higher than Education. Consider investing in a new course or skill!',
        color: AppTheme.secondaryAccent,
      ));
    }

    // 17. Bundle Recommendation (Service Grouping)
    if (names.contains('disney+') && names.contains('hulu')) {
      insights.add(_InsightData(
        icon: Icons.auto_awesome_motion_rounded,
        title: 'Bundle Opportunity',
        message: 'Disney+ and Hulu have a combined "Disney Bundle". Switch to save up to 40% every month!',
        color: AppTheme.secondaryAccent,
      ));
    }

    return insights;
  }

  Map<String, double> _getCategoryAnalytics(List<Subscription> subs) {
    final totals = <String, double>{};
    for (var s in subs) {
      double monthlyVal = s.price;
      if (s.billingCycle.toLowerCase() == 'yearly') monthlyVal = s.price / 12;
      if (s.billingCycle.toLowerCase() == 'weekly') monthlyVal = s.price * 4.33;
      
      totals[s.category] = (totals[s.category] ?? 0) + monthlyVal;
    }
    return totals;
  }
}

class _InsightData {
  final IconData icon;
  final String title;
  final String message;
  final Color color;
  _InsightData({required this.icon, required this.title, required this.message, required this.color});
}
