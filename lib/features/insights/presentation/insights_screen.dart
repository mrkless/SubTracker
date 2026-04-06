import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../subscriptions/data/subscription_repository.dart';
import '../../subscriptions/models/subscription_model.dart';
import '../../../core/currency_provider.dart';
import '../../../core/services/insights_engine.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(subscriptionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Watch state directly so widget rebuilds when currency changes
    ref.watch(currencyProvider);
    final currencyNotifier = ref.read(currencyProvider.notifier);
    final currencySymbol = currencyNotifier.symbol;

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
                          color: isDark ? Colors.white : AppTheme.headingLight)),
                  const SizedBox(height: 4),
                  const Text('Optimize your spending habits',
                      style: TextStyle(color: AppTheme.textMutedDark, fontSize: 14)),
                ],
              ),
            ),
          ),
          subscriptionsAsync.when(
            data: (List<Subscription> rawSubs) {
              final subs = rawSubs.map((s) => s.copyWith(price: currencyNotifier.convertToDisplay(s.price))).toList();
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
  
              final insights = InsightsEngine.generateDynamicInsights(subs, currencySymbol);
              final categoryAnalytics = InsightsEngine.getCategoryAnalytics(subs);
  
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
            loading: () => SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: isDark ? AppTheme.primaryAccent : AppTheme.primaryLight))),
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
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.headingLight, letterSpacing: -1)),
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
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.headingLight)),
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

}
