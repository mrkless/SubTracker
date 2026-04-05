import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../subscriptions/data/subscription_repository.dart';
import '../../subscriptions/models/subscription_model.dart';
import '../../../core/theme.dart';
import '../../../core/currency_provider.dart';
import '../../../main.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final notifier = ref.read(currencyProvider.notifier);
        if (!notifier.hasChosenCurrency) {
          _showCurrencyDialog();
        }
      }
    });
  }

  void _showCurrencyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: ref.read(themeModeProvider) ? AppTheme.surfaceDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Welcome! Let\'s setup', 
            style: TextStyle(
                color: ref.read(themeModeProvider) ? Colors.white : AppTheme.headingLight, 
                fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please choose your default currency. You can always change this later in Settings.', 
                style: TextStyle(color: AppTheme.textMutedDark)),
            const SizedBox(height: 16),
            _buildCurrencyOption('USD', 'US Dollar (\$)'),
            const SizedBox(height: 8),
            _buildCurrencyOption('PHP', 'Philippine Peso (₱)'),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyOption(String code, String name) {
    final isDarkMode = ref.read(themeModeProvider);
    return ListTile(
      onTap: () {
        ref.read(currencyProvider.notifier).setCurrency(code);
        Navigator.pop(context);
      },
      leading: const Icon(Icons.payments_outlined, color: AppTheme.secondaryAccent),
      title: Text(name, style: TextStyle(color: isDarkMode ? Colors.white : AppTheme.headingLight)),
      trailing: Text(code, style: const TextStyle(color: AppTheme.textMutedDark, fontWeight: FontWeight.bold)),
      tileColor: (isDarkMode ? AppTheme.primaryAccent : AppTheme.primaryLight).withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionsAsync = ref.watch(subscriptionsProvider);
    final user = Supabase.instance.client.auth.currentUser;
    final greeting = _getGreeting();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Watch state directly so widget rebuilds when currency changes
    ref.watch(currencyProvider);
    final currencySymbol = ref.read(currencyProvider.notifier).symbol;

    return RefreshIndicator(
      onRefresh: () async => ref.read(subscriptionsProvider.notifier).refresh(),
      color: isDark ? AppTheme.primaryAccent : AppTheme.primaryLight,
      backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
      displacement: 60,
      child: CustomScrollView(
        slivers: [
          // Premium Header
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  24, MediaQuery.of(context).padding.top + 20, 24, 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF1A0E2E), AppTheme.bgDark]
                      : [const Color(0xFFE0E7FF), Colors.white], // Soft indigo to white
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(greeting,
                                style: const TextStyle(
                                    color: AppTheme.textMutedDark,
                                    fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(
                              user?.userMetadata?['first_name'] ??
                                  user?.email?.split('@').first ??
                                  'User',
                              style: TextStyle(
                                color: isDark ? Colors.white : AppTheme.headingLight,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Settings button
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.surfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: isDark ? AppTheme.surfaceDarkLighter : AppTheme.borderLight),
                          boxShadow: isDark ? [] : [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(Icons.settings_outlined,
                              color: isDark ? AppTheme.textMutedDark : AppTheme.headingLight, size: 20),
                          onPressed: () => context.push('/settings'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  // Stats section
                  subscriptionsAsync.when(
                    data: (subs) => _buildHeaderStats(context, subs, currencySymbol, ref),
                    loading: () => SizedBox(
                        height: 120,
                        child: Center(
                            child: CircularProgressIndicator(
                                color: isDark ? AppTheme.primaryAccent : AppTheme.primaryLight,
                                strokeWidth: 2))),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),

          // Subscriptions list
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Your Subscriptions',
                      style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.headingLight)),
                  subscriptionsAsync.whenOrNull(
                        data: (subs) => subs.isNotEmpty
                            ? Text('${subs.length} active',
                                style: const TextStyle(
                                    color: AppTheme.textMutedDark, fontSize: 13))
                            : null,
                      ) ??
                      const SizedBox.shrink(),
                ],
              ),
            ),
          ),

          subscriptionsAsync.when(
            data: (subs) {
              if (subs.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(context),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _SubscriptionCard(subscription: subs[index], currencySymbol: currencySymbol),
                    childCount: subs.length,
                  ),
                ),
              );
            },
            loading: () => SliverFillRemaining(
              child: Center(
                  child: CircularProgressIndicator(color: isDark ? AppTheme.primaryAccent : AppTheme.primaryLight)),
            ),
            error: (err, stack) => SliverFillRemaining(
              child: Center(child: Text('Error: $err')),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildHeaderStats(BuildContext context, List<Subscription> subs, String symbol, WidgetRef ref) {
    final monthly = _calculateMonthly(subs);
    final displayMonthly = ref.watch(currencyProvider.notifier).convertToDisplay(monthly);
    final displayYearly = displayMonthly * 12;
    final now = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final upcomingCount = subs
        .where((s) =>
            s.nextBillingDate.isAfter(now) &&
            s.nextBillingDate.difference(now).inDays <= 7)
        .length;
    final overdueCount = subs
        .where((s) =>
            s.status == 'overdue' || s.nextBillingDate.isBefore(now))
        .length;

    return Column(
      children: [
        // Main total card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryAccent.withOpacity(isDark ? 0.3 : 0.1),
                AppTheme.primaryAccent.withOpacity(isDark ? 0.08 : 0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: (isDark ? AppTheme.primaryAccent : AppTheme.primaryLight).withOpacity(isDark ? 0.3 : 0.4), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Monthly Spending',
                  style:
                      TextStyle(color: AppTheme.textMutedDark, fontSize: 13)),
              const SizedBox(height: 6),
              Text(
                NumberFormat.currency(symbol: symbol).format(displayMonthly),
                style: TextStyle(
                  color: isDark ? Colors.white : AppTheme.headingLight,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${NumberFormat.currency(symbol: symbol).format(displayYearly)} / year',
                style: const TextStyle(
                    color: AppTheme.textMutedDark, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _MiniCard(
                title: 'Upcoming',
                value: upcomingCount.toString(),
                icon: Icons.schedule_outlined,
                color: AppTheme.secondaryAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniCard(
                title: 'Overdue',
                value: overdueCount.toString(),
                icon: Icons.warning_amber_rounded,
                color: AppTheme.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniCard(
                title: 'Active',
                value: subs.length.toString(),
                icon: Icons.check_circle_outline,
                color: AppTheme.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            child: Icon(Icons.subscriptions_outlined,
                size: 44, color: isDark ? AppTheme.primaryAccent : AppTheme.primaryLight),
          ),
          const SizedBox(height: 24),
          Text('No Subscriptions',
              style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.headingLight)),
          const SizedBox(height: 8),
          const Text(
            'Tap the Add button to track\nyour first subscription',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMutedDark),
          ),
        ],
      ),
    );
  }

  double _calculateMonthly(List<Subscription> subs) {
    double total = 0;
    for (var s in subs) {
      if (s.billingCycle.toLowerCase() == 'monthly') {
        total += s.price;
      } else if (s.billingCycle.toLowerCase() == 'yearly') {
        total += s.price / 12;
      } else if (s.billingCycle.toLowerCase() == 'weekly') {
        total += s.price * 4.33;
      }
    }
    return total;
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }
}

class _MiniCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.surfaceDarkLighter : AppTheme.borderLight),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  fontSize: 22, 
                  fontWeight: FontWeight.bold, 
                  color: isDark ? Colors.white : AppTheme.headingLight)),
          const SizedBox(height: 2),
          Text(title,
              style: const TextStyle(
                  color: AppTheme.textMutedDark, fontSize: 11)),
        ],
      ),
    );
  }
}

class _SubscriptionCard extends ConsumerWidget {
  final Subscription subscription;
  final String currencySymbol;

  const _SubscriptionCard({required this.subscription, required this.currencySymbol});

  static const Map<String, IconData> _icons = {
    'Entertainment': Icons.movie_outlined,
    'Productivity': Icons.work_outline_rounded,
    'Music': Icons.music_note_outlined,
    'Gaming': Icons.sports_esports_outlined,
    'Health&Fitness': Icons.fitness_center_rounded,
    'Education': Icons.school_outlined,
    'Shopping': Icons.shopping_bag_outlined,
    'Utilities': Icons.bolt_outlined,
    'Others': Icons.category_outlined,
  };

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
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOverdue = subscription.nextBillingDate.isBefore(now);
    final daysUntil = subscription.nextBillingDate.difference(now).inDays;
    final color = _categoryColors[subscription.category] ?? AppTheme.primaryAccent;
    final icon = _icons[subscription.category] ?? Icons.category_outlined;
    final displayPrice = ref.watch(currencyProvider.notifier).convertToDisplay(subscription.price);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(subscription.id),
        direction: DismissDirection.horizontal,
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            // Swipe Right -> Edit
            context.push('/edit_subscription', extra: subscription);
            return false; // Don't dismiss
          } else {
            // Swipe Left -> Delete
            return await _showDeleteConfirm(context);
          }
        },
        onDismissed: (direction) {
          if (direction == DismissDirection.endToStart) {
            ref.read(subscriptionsProvider.notifier).removeSubscription(subscription.id);
          }
        },
        background: _buildSwipeAction(
          color: AppTheme.primaryAccent,
          icon: Icons.edit_outlined,
          alignment: Alignment.centerLeft,
          label: 'Edit',
        ),
        secondaryBackground: _buildSwipeAction(
          color: AppTheme.error,
          icon: Icons.delete_outline,
          alignment: Alignment.centerRight,
          label: 'Delete',
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isOverdue
                  ? AppTheme.error.withOpacity(0.4)
                  : (isDark ? AppTheme.surfaceDarkLighter : AppTheme.borderLight),
            ),
            boxShadow: isDark ? [] : [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => context.push('/edit_subscription', extra: subscription),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 14),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(subscription.name,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isDark ? Colors.white : AppTheme.headingLight)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(subscription.category,
                                    style: TextStyle(
                                        color: color,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isOverdue
                                    ? 'Overdue!'
                                    : daysUntil == 0
                                        ? 'Due today'
                                        : 'in $daysUntil d',
                                style: TextStyle(
                                  color: isOverdue
                                      ? AppTheme.error
                                      : daysUntil <= 3
                                          ? AppTheme.warning
                                          : AppTheme.textMutedDark,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$currencySymbol${displayPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: isDark ? Colors.white : AppTheme.headingLight),
                        ),
                        Text(
                          subscription.billingCycle.toLowerCase(),
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textMutedDark),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeAction({
    required Color color,
    required IconData icon,
    required Alignment alignment,
    required String label,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: alignment,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirm(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Delete Subscription',
            style: TextStyle(
                color: isDark ? Colors.white : AppTheme.headingLight,
                fontWeight: FontWeight.bold)),
        content: Text(
            'Are you sure you want to delete "${subscription.name}"?',
            style: const TextStyle(color: AppTheme.textMutedDark)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textMutedDark))),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Delete')),
        ],
      ),
    );
  }
}

