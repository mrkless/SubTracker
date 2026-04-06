import 'package:flutter/material.dart';
import '../../features/subscriptions/models/subscription_model.dart';
import '../theme.dart';

class InsightData {
  final IconData icon;
  final String title;
  final String message;
  final Color color;
  InsightData({required this.icon, required this.title, required this.message, required this.color});
}

class InsightsEngine {
  static List<InsightData> generateDynamicInsights(List<Subscription> subs, String symbol) {
    if (subs.isEmpty) return [];

    final insights = <InsightData>[];
    final names = subs.map((s) => s.name.toLowerCase()).toList();
    final now = DateTime.now();

    // 1. Math-Based Savings (Always priority)
    final monthlySubs = subs.where((s) => s.billingCycle.toLowerCase() == 'monthly').toList();
    if (monthlySubs.isNotEmpty) {
      final potentialSavings = monthlySubs.fold<double>(0, (p, c) => p + (c.price * 0.15));
      if (potentialSavings > 0) {
        insights.add(InsightData(
          icon: Icons.auto_graph_rounded,
          title: 'Smart Savings',
          message: 'Annual savings potential: ~$symbol${potentialSavings.toStringAsFixed(0)} by switching to Yearly plans.',
          color: AppTheme.success,
        ));
      }
    }

    // 2. The "Overlapping Music" Alert
    if (names.contains('spotify') && (names.contains('youtube music') || names.contains('apple music'))) {
        insights.add(InsightData(
        icon: Icons.music_off_rounded,
        title: 'Music Overlap',
        message: 'You have multiple music services. You could save by picking just one premium library!',
        color: AppTheme.error,
      ));
    }

    // 3. Apple One Ecosystem Nudge
    if (names.contains('apple music') && names.contains('icloud+')) {
      insights.add(InsightData(
        icon: Icons.apple_rounded,
        title: 'Apple One Hack',
        message: 'You\'re paying for Apple Music and iCloud+. Switching to "Apple One" could bundle these and save you up to ${symbol}5/mo.',
        color: AppTheme.primaryAccent,
      ));
    }

    // 4. Duplicate Service Check
    final duplicateNames = names.where((n) => names.where((x) => x == n).length > 1).toSet();
    if (duplicateNames.isNotEmpty) {
      insights.add(InsightData(
        icon: Icons.copy_rounded,
        title: 'Duplicate Alert',
        message: 'You have ${duplicateNames.length} duplicate services (e.g., ${duplicateNames.first}). Is this a mistake?',
        color: AppTheme.error,
      ));
    }

    // 5. Gaming Rotation Strategy
    final gamingCount = subs.where((s) => s.category == 'Gaming').length;
    if (gamingCount >= 3) {
      insights.add(InsightData(
        icon: Icons.gamepad_rounded,
        title: 'Gaming Rotation',
        message: 'You have $gamingCount active gaming subs. Consider a "Rotation" strategy: Pause what you aren\'t playing!',
        color: AppTheme.primaryAccent,
      ));
    }

    // 6. AI Power Stack
    bool hasAI = names.contains('chatgpt plus') || names.contains('github copilot') || names.contains('midjourney');
    if (hasAI && names.length > 5) {
       insights.add(InsightData(
        icon: Icons.bolt_rounded,
        title: 'AI Power User',
        message: 'You have a premium AI stack! Monitor your usage to ensure you\'re getting full value from these high-cost tools.',
        color: AppTheme.primaryAccent,
      ));
    }

    // 7. Streaming Rotator
    final entSubs = subs.where((s) => s.category == 'Entertainment').length;
    if (entSubs >= 4) {
      insights.add(InsightData(
        icon: Icons.sync_rounded,
        title: 'Streaming Rotator',
        message: 'With $entSubs entertainment subs, you might save ${symbol}30+/mo by rotating services based on new releases.',
        color: AppTheme.secondaryAccent,
      ));
    }

    // 8. Family Share Optimization
    final streamCount = subs.where((s) => s.category == 'Entertainment' || s.category == 'Music').length;
    if (streamCount >= 5) {
       insights.add(InsightData(
        icon: Icons.group_work_rounded,
        title: 'Family Plan Audit',
        message: 'With $streamCount streaming services, ensure you\'re using Family Plans where possible to share the cost!',
        color: AppTheme.secondaryAccent,
      ));
    }

    // 9. The "Silent Burner" Alert
    final microSubs = subs.where((s) => s.price > 0 && s.price < 3).toList();
    if (microSubs.isNotEmpty) {
       final microTotal = microSubs.fold<double>(0, (p, c) => p + (c.price * 12));
       insights.add(InsightData(
        icon: Icons.blur_on_rounded,
        title: 'Silent Burners',
        message: 'You have ${microSubs.length} low-cost bills ($symbol${microSubs.first.price}). They add up to ~$symbol${microTotal.toStringAsFixed(0)} annually!',
        color: AppTheme.secondaryAccent,
      ));
    }

    // 10. Weekend Bill Warning
    final billsThisWeekend = subs.where((s) => 
      s.nextBillingDate.weekday == DateTime.saturday || 
      s.nextBillingDate.weekday == DateTime.sunday
    ).toList();
    if (billsThisWeekend.isNotEmpty) {
      insights.add(InsightData(
        icon: Icons.warning_rounded,
        title: 'Weekend Renewal',
        message: '${billsThisWeekend.length} bills are due this weekend. Check for early charges or banking delays!',
        color: AppTheme.warning,
      ));
    }

    // 11. 1st of the Month Spike
    final firstOfMonth = subs.where((s) => s.nextBillingDate.day == 1).length;
    if (firstOfMonth >= 3) {
      insights.add(InsightData(
        icon: Icons.event_note_rounded,
        title: 'Monthly Cash Crunch',
        message: 'You have $firstOfMonth bills due on the 1st. Consider staggering dates for smoother monthly cashflow.',
        color: AppTheme.error,
      ));
    }

    // 12. Free Trial Shadow
    final trials = subs.where((s) => s.price == 0).toList();
    if (trials.isNotEmpty) {
      insights.add(InsightData(
        icon: Icons.timer_outlined,
        title: 'Trial Shadow',
        message: 'You have ${trials.length} active trials. Don\'t forget to cancel before they convert to full-priced bills!',
        color: AppTheme.warning,
      ));
    }

    // 13. Categorization Clean-up
    final otherCount = subs.where((s) => s.category == 'Others').length;
    if (otherCount >= 5) {
       insights.add(InsightData(
        icon: Icons.label_important_outline_rounded,
        title: 'Clean Up Tip',
        message: 'You have $otherCount items in the "Others" category. Try re-assigning them for better spending analytics!',
        color: AppTheme.primaryAccent,
      ));
    }

    // 14. Long-term Projection
    final monthlyTotal = subs.fold<double>(0, (p, c) {
      if (c.billingCycle.toLowerCase() == 'yearly') return p + (c.price / 12);
      if (c.billingCycle.toLowerCase() == 'weekly') return p + (c.price * 4.33);
      return p + c.price;
    });
    if (monthlyTotal > 150) {
      final twoYearSpent = monthlyTotal * 24;
      insights.add(InsightData(
        icon: Icons.timeline_rounded,
        title: '2-Year Outlook',
        message: 'At your current rate, you\'ll spend $symbol${twoYearSpent.toStringAsFixed(0)} in 2 years. Is your portfolio optimized?',
        color: AppTheme.warning,
      ));
    }

    // 15. Ghost Subscription Detection
    final ghostSubs = subs.where((s) => s.nextBillingDate.isBefore(now.subtract(const Duration(days: 1)))).toList();
    if (ghostSubs.isNotEmpty) {
       insights.add(InsightData(
        icon: Icons.visibility_off_rounded,
        title: 'Ghost Detection',
        message: 'Found ${ghostSubs.length} subscriptions past their due date. Are these still active or should you delete them?',
        color: AppTheme.error,
      ));
    }

    // 16. Balanced Portfolio Nudge
    final entSpend = getCategoryAnalytics(subs)['Entertainment'] ?? 0;
    final eduSpend = getCategoryAnalytics(subs)['Education'] ?? 0;
    if (entSpend > eduSpend * 3 && entSpend > 50) {
      insights.add(InsightData(
        icon: Icons.psychology_alt_rounded,
        title: 'Life Balance Tip',
        message: 'Your Entertainment spend is 3x higher than Education. Consider investing in a new course or skill!',
        color: AppTheme.secondaryAccent,
      ));
    }

    // 17. Bundle Recommendation
    if (names.contains('disney+') && names.contains('hulu')) {
      insights.add(InsightData(
        icon: Icons.auto_awesome_motion_rounded,
        title: 'Bundle Opportunity',
        message: 'Disney+ and Hulu have a combined "Disney Bundle". Switch to save up to 40% every month!',
        color: AppTheme.secondaryAccent,
      ));
    }

    return insights;
  }

  static Map<String, double> getCategoryAnalytics(List<Subscription> subs) {
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
