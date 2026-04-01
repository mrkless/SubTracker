import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme.dart';
import '../../subscriptions/data/subscription_repository.dart';
import '../../subscriptions/models/subscription_model.dart';
import '../../../core/currency_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _touchedIndex = -1;

  static const Map<String, Color> _categoryColors = {
    'Entertainment': Color(0xFFFF6B6B),
    'Productivity': Color(0xFF4AC3FF),
    'Music': Color(0xFFFF8B94),
    'Gaming': Color(0xFF7B61FF),
    'Health&Fitness': Color(0xFFFFA07A),
    'Education': Color(0xFF4ECDC4),
    'Shopping': Color(0xFFBA68C8),
    'Utilities': Color(0xFF81C784),
    'Others': Color(0xFF8A2BE2),
  };

  @override
  Widget build(BuildContext context) {
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
                    child: const Icon(Icons.pie_chart_outline,
                        size: 44, color: AppTheme.primaryAccent),
                  ),
                  const SizedBox(height: 24),
                  Text('No data yet',
                      style: TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.textLight)),
                  const SizedBox(height: 8),
                  const Text('Add subscriptions to see analytics',
                      style: TextStyle(color: AppTheme.textMutedDark)),
                ],
              ),
            );
          }

          final categoryTotals = <String, double>{};
          double grandTotal = 0;
          for (var sub in subs) {
            double normalized = sub.price;
            if (sub.billingCycle.toLowerCase() == 'yearly') {
              normalized = sub.price / 12;
            } else if (sub.billingCycle.toLowerCase() == 'weekly') {
              normalized = sub.price * 4.33;
            }
            categoryTotals[sub.category] =
                (categoryTotals[sub.category] ?? 0) + normalized;
            grandTotal += normalized;
          }

          final sortedEntries = categoryTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          int idx = 0;
          final defaultColors = [
            const Color(0xFFFF6B6B),
            const Color(0xFFFFBF47),
            const Color(0xFF4ECDC4),
            const Color(0xFFFF8B94),
            const Color(0xFF8A2BE2),
          ];

          final sections = sortedEntries.asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            final isTouched = _touchedIndex == i;
            final color = _categoryColors[e.key] ??
                defaultColors[idx++ % defaultColors.length];
            return PieChartSectionData(
              color: color,
              value: e.value,
              title: isTouched
                  ? '$currencySymbol${e.value.toStringAsFixed(0)}'
                  : '${(e.value / grandTotal * 100).toStringAsFixed(0)}%',
              radius: isTouched ? 72 : 58,
              titleStyle: TextStyle(
                fontSize: isTouched ? 15 : 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList();

          // Logic for additional stats
          final mostExpensive = List<Subscription>.from(subs)..sort((a, b) => b.price.compareTo(a.price));
          final avgPrice = subs.fold<double>(0, (p, c) => p + c.price) / subs.length;
          
          final cycles = <String, int>{'monthly': 0, 'yearly': 0, 'weekly': 0};
          for (var s in subs) cycles[s.billingCycle.toLowerCase()] = (cycles[s.billingCycle.toLowerCase()] ?? 0) + 1;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(subscriptionsProvider),
            color: AppTheme.primaryAccent,
            backgroundColor: isDark ? AppTheme.surfaceDarkLighter : Colors.white,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Analytics',
                      style: TextStyle(
                          fontSize: 28, 
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.textLight)),
                  const SizedBox(height: 4),
                  const Text('Data-driven spending insights',
                      style: TextStyle(
                          color: AppTheme.textMutedDark, fontSize: 13)),
                  const SizedBox(height: 28),

                // Premium Header Stats
                Row(
                  children: [
                    _buildQuickStat(context, 'Monthly', '$currencySymbol${grandTotal.toStringAsFixed(0)}', Icons.payments_rounded, AppTheme.primaryAccent),
                    const SizedBox(width: 12),
                    _buildQuickStat(context, 'Avg. Bill', '$currencySymbol${avgPrice.toStringAsFixed(0)}', Icons.analytics_rounded, AppTheme.secondaryAccent),
                  ],
                ),
                const SizedBox(height: 24),

                // Spending Extremes Card
                _buildExtremesCard(context, mostExpensive.first, currencySymbol),
                const SizedBox(height: 40),

                // Chart Header
                _buildSectionHeader('Spending by Category'),
                const SizedBox(height: 16),
                
                // Chart
                SizedBox(
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (event, response) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    response == null ||
                                    response.touchedSection == null) {
                                  _touchedIndex = -1;
                                  return;
                                }
                                _touchedIndex =
                                    response.touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 4,
                          centerSpaceRadius: 50,
                          sections: sections,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('TOTAL', style: TextStyle(color: AppTheme.textMutedDark, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          Text('$currencySymbol${grandTotal.toStringAsFixed(0)}', style: TextStyle(color: isDark ? Colors.white : AppTheme.textLight, fontSize: 18, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                _buildSectionHeader('Billing Distribution'),
                const SizedBox(height: 16),
                _buildCycleDistribution(context, cycles, subs.length),

                const SizedBox(height: 40),
                _buildSectionHeader('Category Breakdown'),
                const SizedBox(height: 12),

                // Breakdown list
                ...sortedEntries.map((e) {
                  final color = _categoryColors[e.key] ?? AppTheme.primaryAccent;
                  return _CategoryTile(
                    category: e.key,
                    amount: e.value,
                    percent: e.value / grandTotal * 100,
                    color: color,
                    currencySymbol: currencySymbol,
                  );
                }),
              ],
            ),
          ),
        );
      },
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryAccent)),
        error: (err, __) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildQuickStat(BuildContext context, String label, String val, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 12),
            Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.textLight)),
            Text(label, style: const TextStyle(color: AppTheme.textMutedDark, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildExtremesCard(BuildContext context, Subscription mostExpensive, String symbol) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.error.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(color: AppTheme.error.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.error.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Heaviest Bill', style: TextStyle(color: AppTheme.textMutedDark, fontSize: 12, fontWeight: FontWeight.bold)),
                Text(mostExpensive.name, style: TextStyle(color: isDark ? Colors.white : AppTheme.textLight, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Text('$symbol${mostExpensive.price.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.w900, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title.toUpperCase(), style: const TextStyle(color: AppTheme.textMutedDark, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5));
  }

  Widget _buildCycleDistribution(BuildContext context, Map<String, int> cycles, int total) {
    if (total == 0) return const SizedBox.shrink();
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                if (cycles['weekly']! > 0) Expanded(flex: cycles['weekly']!, child: Container(color: AppTheme.primaryAccent)),
                if (cycles['monthly']! > 0) Expanded(flex: cycles['monthly']!, child: Container(color: AppTheme.secondaryAccent)),
                if (cycles['yearly']! > 0) Expanded(flex: cycles['yearly']!, child: Container(color: AppTheme.success)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildCycleLegend('Weekly', AppTheme.primaryAccent, cycles['weekly']!),
            _buildCycleLegend('Monthly', AppTheme.secondaryAccent, cycles['monthly']!),
            _buildCycleLegend('Yearly', AppTheme.success, cycles['yearly']!),
          ],
        ),
      ],
    );
  }

  Widget _buildCycleLegend(String label, Color color, int count) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label ($count)', style: const TextStyle(color: AppTheme.textMutedDark, fontSize: 11)),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String category;
  final double amount;
  final double percent;
  final Color color;
  final String currencySymbol;

  const _CategoryTile({
    required this.category,
    required this.amount,
    required this.percent,
    required this.color,
    required this.currencySymbol,
  });

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
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(category,
                style: TextStyle(
                    fontWeight: FontWeight.w600, 
                    color: isDark ? Colors.white : AppTheme.textLight)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$currencySymbol${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      color: isDark ? Colors.white : AppTheme.textLight)),
              Text('${percent.toStringAsFixed(1)}%',
                  style: const TextStyle(
                      color: AppTheme.textMutedDark, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
