import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/subscriptions/models/subscription_model.dart';
import '../theme.dart';
import 'insights_engine.dart';

// ─────────────────────────────────────────────────────────────
// Notification Channel IDs
// ─────────────────────────────────────────────────────────────
const _channelUpcoming = 'upcoming_renewals';
const _channelOverdue  = 'overdue_alerts';
const _channelInsights = 'spending_insights';
const _channelDailyTip = 'daily_tips';

// ─────────────────────────────────────────────────────────────
// Notification ID helpers — keeps IDs unique per sub + type
// Using different hash offsets per reminder type.
// ─────────────────────────────────────────────────────────────
int _id(String subId, int offset) =>
    (subId.hashCode.abs() % 99999) * 10 + offset;
// offset 0 = 7-day reminder
// offset 1 = 3-day reminder
// offset 2 = 1-day reminder
// offset 3 = same-day / due today
// offset 4 = overdue alert
// offset 5 = insight (weekly digest)

// ─────────────────────────────────────────────────────────────
// Daily Tips Pool — rotates by day-of-year
// ─────────────────────────────────────────────────────────────
const List<Map<String, String>> _dailyTips = [
  // Money & subscription insights
  {'title': '💡 Tip of the Day', 'body': 'The average person wastes \$348/year on subscriptions they forgot about. Check yours now!'},
  {'title': '📊 Did You Know?', 'body': 'Bundling streaming services can save up to 40% vs subscribing to each individually.'},
  {'title': '💰 Money Tip', 'body': 'Set a monthly subscription budget. Even \$5 savings per service adds up to \$60/year!'},
  {'title': '🎯 Smart Habit', 'body': 'Review your subscriptions every 3 months. Cancel anything you haven\'t used in 30 days.'},
  {'title': '📅 Reminder', 'body': 'Most services offer annual billing discounts of 15–20%. Worth checking if you use it daily!'},
  {'title': '🔍 Insight', 'body': 'Streaming, fitness apps, and cloud storage are the top 3 most-forgotten subscriptions worldwide.'},
  {'title': '💡 Tip of the Day', 'body': 'Free trials auto-charge when they end. Always mark the trial end date in SubTracker!'},
  {'title': '📊 Financial Fact', 'body': 'Households typically subscribe to 12 services, but only actively use 7 of them.'},
  {'title': '💰 Save More', 'body': 'Share family or group plans when possible — you can split Netflix, Spotify & more!'},
  {'title': '⚡ Quick Tip', 'body': 'Switch to annual billing on your most-used apps and save up to 2 months free per year.'},
  {'title': '🧠 Trivia', 'body': 'The subscription economy has grown over 435% in the last 9 years. Tracking yours keeps you in control.'},
  {'title': '🎯 Smart Move', 'body': 'Downgrade plans you\'re overqualified for. A basic plan often covers 90% of what you need.'},
  {'title': '📅 Check-In', 'body': 'Have you opened all your subscriptions this week? If not, consider pausing or cancelling some.'},
  {'title': '💡 Tip of the Day', 'body': 'Always check for student, nonprofit, or loyalty discounts — they can cut subscription costs in half.'},
  {'title': '🔔 Good Morning!', 'body': 'Start your day by reviewing what bills are coming up this week in SubTracker!'},
  {'title': '💸 Money Fact', 'body': 'Unused gym memberships cost Americans over \$1.8 billion per year. Is yours worth keeping?'},
  {'title': '📊 Insight', 'body': 'Price hikes are common in subscription services. Check annually if you\'re still getting value.'},
  {'title': '🎯 Daily Goal', 'body': 'Challenge: review one subscription today and ask — do I really need this?'},
  {'title': '💡 Tip of the Day', 'body': 'Enable SubTracker notifications to never miss a billing date again!'},
  {'title': '🌟 Motivation', 'body': 'Every peso/dollar you save on unused subscriptions is money back in your pocket. Keep tracking!'},
  {'title': '🧠 Trivia', 'body': 'Netflix started as a DVD rental service in 1997. Subscriptions were \$15.95/month — now it\'s much more!'},
  {'title': '💰 Budgeting Tip', 'body': 'The 50/30/20 rule: 50% needs, 30% wants (incl. subscriptions), 20% savings. Are you balanced?'},
  {'title': '📅 Weekend Check', 'body': 'Weekends are a great time to audit your subscriptions. Clear 10 mins today!'},
  {'title': '⚡ Quick Win', 'body': 'Cancel one subscription you haven\'t used this month — instant savings, zero effort.'},
  {'title': '🔍 Did You Know?', 'body': 'Subscription apps charge at the same time each cycle. Keep your balance positive the night before!'},
  {'title': '💡 Tip of the Day', 'body': 'Pausing a subscription is often better than cancelling — many services allow 1–3 month pauses.'},
  {'title': '📊 Fact', 'body': 'Cloud storage subscriptions: free tiers often cover most casual users. Check if you need to upgrade.'},
  {'title': '🎯 This Week', 'body': 'Set a goal: know exactly what you spend on subscriptions per month by the end of this week.'},
];

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Helpers to get currency formatting
  String get _currencySymbol {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return '\$';
      final box = Hive.box('settings');
      final code = box.get('currency_$uid', defaultValue: 'USD');
      return code == 'PHP' ? '₱' : '\$';
    } catch (_) {
      return '\$';
    }
  }

  double _getDisplayPrice(double usdPrice) {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return usdPrice;
      final box = Hive.box('settings');
      final code = box.get('currency_$uid', defaultValue: 'USD');
      return code == 'PHP' ? usdPrice * 56.0 : usdPrice;
    } catch (_) {
      return usdPrice;
    }
  }

  // ─────────────────────────────────────────────────────────
  // INITIALIZE
  // ─────────────────────────────────────────────────────────
  Future<void> initialize() async {
    if (_isInitialized || kIsWeb) return;

    tz.initializeTimeZones();
    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
    } catch (_) {}

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (_) {},
    );

    _isInitialized = true;
  }

  // ─────────────────────────────────────────────────────────
  // REQUEST PERMISSIONS
  // ─────────────────────────────────────────────────────────
  Future<void> requestPermissions() async {
    if (kIsWeb) return;
    
    final platform = defaultTargetPlatform;

    if (platform == TargetPlatform.iOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (platform == TargetPlatform.android) {
      final android =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
    }
  }

  // ─────────────────────────────────────────────────────────
  // CANCEL helpers
  // ─────────────────────────────────────────────────────────
  Future<void> cancelAllForSubscription(String subId) async {
    if (kIsWeb) return;
    for (int offset = 0; offset <= 4; offset++) {
      await _plugin.cancel(id: _id(subId, offset));
    }
  }

  Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;
    await _plugin.cancel(id: id);
  }

  // ─────────────────────────────────────────────────────────
  // SCHEDULE ALL NOTIFICATIONS FOR ONE SUBSCRIPTION
  // ─────────────────────────────────────────────────────────
  Future<void> scheduleSubscriptionNotification(
      Subscription subscription) async {
    if (kIsWeb) return;
    await cancelAllForSubscription(subscription.id);

    final now = DateTime.now();
    final due = subscription.nextBillingDate;
    final daysUntil = due.difference(now).inDays;
    
    final sym = _currencySymbol;
    final displayPrice = _getDisplayPrice(subscription.price).toStringAsFixed(2);

    // ── 7-day reminder ──────────────────────────────────────
    await _trySchedule(
      id: _id(subscription.id, 0),
      targetDate: due.subtract(const Duration(days: 7)),
      hour: 9,
      title: '📅 7 Days Until Renewal',
      body:
          '${subscription.name} renews in 7 days. Make sure your payment method is ready.',
      channelId: _channelUpcoming,
      channelName: 'Upcoming Renewals',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    // ── 3-day reminder ──────────────────────────────────────
    await _trySchedule(
      id: _id(subscription.id, 1),
      targetDate: due.subtract(const Duration(days: 3)),
      hour: 9,
      title: '⏰ 3 Days Until Renewal',
      body:
          '${subscription.name} renews in 3 days for $sym$displayPrice.',
      channelId: _channelUpcoming,
      channelName: 'Upcoming Renewals',
      importance: Importance.high,
      priority: Priority.high,
    );

    // ── 1-day reminder ──────────────────────────────────────
    await _trySchedule(
      id: _id(subscription.id, 2),
      targetDate: due.subtract(const Duration(days: 1)),
      hour: 9,
      title: '🔔 Renewing Tomorrow!',
      body:
          '${subscription.name} renews TOMORROW for $sym$displayPrice. Check your balance.',
      channelId: _channelUpcoming,
      channelName: 'Upcoming Renewals',
      importance: Importance.high,
      priority: Priority.high,
    );

    // ── Same-day / Due today reminder at 8 AM ───────────────
    await _trySchedule(
      id: _id(subscription.id, 3),
      targetDate: due,
      hour: 8,
      title: '💳 Renewing Today: ${subscription.name}',
      body:
          'Your ${subscription.name} subscription charges $sym$displayPrice today.',
      channelId: _channelUpcoming,
      channelName: 'Upcoming Renewals',
      importance: Importance.max,
      priority: Priority.max,
    );

    // ── Overdue alert (1 day after due) at 10 AM ────────────
    if (daysUntil >= -1) {
      await _trySchedule(
        id: _id(subscription.id, 4),
        targetDate: due.add(const Duration(days: 1)),
        hour: 10,
        title: '🚨 Overdue: ${subscription.name}',
        body:
            '${subscription.name} was due yesterday! Check your payment status immediately.',
        channelId: _channelOverdue,
        channelName: 'Overdue Alerts',
        importance: Importance.max,
        priority: Priority.max,
      );
    }
  }

  // ─────────────────────────────────────────────────────────
  // SCHEDULE ALL AT ONCE (called on app start / data refresh)
  // ─────────────────────────────────────────────────────────
  Future<void> scheduleAllSubscriptions(
      List<Subscription> subscriptions) async {
    if (kIsWeb) return;
    await _plugin.cancelAll();

    for (final sub in subscriptions) {
      await scheduleSubscriptionNotification(sub);
    }

    // ── Weekly spending digest (every Monday at 9 AM) ────────
    await _scheduleWeeklyDigest(subscriptions);

    // ── Mid-week Smart Insight (every Thursday at 4 PM) ───────
    await _scheduleMidWeekInsight(subscriptions);

    // ── Daily tip/insight/trivia (every day at 10 AM) ─────────
    await scheduleDailyTip();
  }

  // ─────────────────────────────────────────────────────────
  // DAILY TIP — every day at 10:00 AM, rotates content
  // ─────────────────────────────────────────────────────────
  Future<void> scheduleDailyTip() async {
    if (kIsWeb) return;
    await _plugin.cancel(id: 999999);

    final now = DateTime.now();
    // Pick tip based on day-of-year so it's predictably different each day
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    final tip = _dailyTips[dayOfYear % _dailyTips.length];

    // Schedule for 10 AM today; if already past 10 AM, schedule for tomorrow
    DateTime notifyAt = DateTime(now.year, now.month, now.day, 10, 0);
    if (notifyAt.isBefore(now)) {
      notifyAt = notifyAt.add(const Duration(days: 1));
    }

    final scheduled = tz.TZDateTime.from(notifyAt, tz.local);

    await _plugin.zonedSchedule(
      id: 999999,
      title: tip['title']!,
      body: tip['body']!,
      scheduledDate: scheduled,
      notificationDetails: _buildDetails(
        channelId: _channelDailyTip,
        channelName: 'Daily Tips & Insights',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // Repeat daily at same time
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ─────────────────────────────────────────────────────────
  // WEEKLY SPENDING DIGEST — every Monday 9 AM
  // ─────────────────────────────────────────────────────────
  Future<void> _scheduleWeeklyDigest(
      List<Subscription> subscriptions) async {
    if (kIsWeb) return;
    if (subscriptions.isEmpty) return;

    final sym = _currencySymbol;
    final double monthlyTotal = subscriptions.fold(0.0, (sum, s) {
      if (s.billingCycle.toLowerCase() == 'monthly') return sum + s.price;
      if (s.billingCycle.toLowerCase() == 'yearly') return sum + s.price / 12;
      if (s.billingCycle.toLowerCase() == 'weekly') return sum + s.price * 4.33;
      return sum;
    });

    final int overdueCount = subscriptions
        .where((s) => s.nextBillingDate.isBefore(DateTime.now()))
        .length;

    final String overdueNote = overdueCount > 0
        ? ' ⚠️ $overdueCount overdue!'
        : ' All payments are on track ✅';

    await _plugin.cancel(id: 777777);

    final now = DateTime.now();
    // Find next Monday
    int daysToMonday = (DateTime.monday - now.weekday + 7) % 7;
    if (daysToMonday == 0) daysToMonday = 7;
    final nextMonday = DateTime(
        now.year, now.month, now.day + daysToMonday, 9, 0);

    if (nextMonday.isAfter(now)) {
      final tz.TZDateTime scheduled =
          tz.TZDateTime.from(nextMonday, tz.local);

      await _plugin.zonedSchedule(
        id: 777777,
        title: '📊 Weekly Spending Digest',
        body:
            'You spend ~$sym${_getDisplayPrice(monthlyTotal).toStringAsFixed(2)}/month on ${subscriptions.length} subscriptions.$overdueNote',
        scheduledDate: scheduled,
        notificationDetails: _buildDetails(
          channelId: _channelInsights,
          channelName: 'Spending Insights',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  // ─────────────────────────────────────────────────────────
  // MID-WEEK SMART INSIGHT — every Thursday 4 PM
  // ─────────────────────────────────────────────────────────
  Future<void> _scheduleMidWeekInsight(List<Subscription> subscriptions) async {
    if (kIsWeb) return;
    if (subscriptions.isEmpty) return;

    final insights = InsightsEngine.generateDynamicInsights(subscriptions, _currencySymbol);
    if (insights.isEmpty) return;
    
    // Pick the most critical insight (first one)
    final topInsight = insights.first;

    await _plugin.cancel(id: 666666);

    final now = DateTime.now();
    // Find next Thursday
    int daysToThursday = (DateTime.thursday - now.weekday + 7) % 7;
    if (daysToThursday == 0 && now.hour >= 16) daysToThursday = 7; 
    
    final nextThursday = DateTime(
        now.year, now.month, now.day + daysToThursday, 16, 0);

    if (nextThursday.isAfter(now)) {
      final tz.TZDateTime scheduled =
          tz.TZDateTime.from(nextThursday, tz.local);

      await _plugin.zonedSchedule(
        id: 666666,
        title: '💡 ${topInsight.title}',
        body: topInsight.message,
        scheduledDate: scheduled,
        notificationDetails: _buildDetails(
          channelId: _channelInsights,
          channelName: 'Spending Insights',
          importance: Importance.high,
          priority: Priority.high,
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  // ─────────────────────────────────────────────────────────
  // SEND IMMEDIATE OVERDUE ALERT (called when opening app
  // and overdue subs are detected)
  // ─────────────────────────────────────────────────────────
  Future<void> sendOverdueAlert(List<Subscription> overdueSubs) async {
    if (kIsWeb) return;
    if (overdueSubs.isEmpty) return;

    final names = overdueSubs.take(3).map((s) => s.name).join(', ');
    final more = overdueSubs.length > 3
        ? ' +${overdueSubs.length - 3} more'
        : '';

    await _plugin.show(
      id: 888888,
      title: '🚨 Overdue Subscriptions!',
      body: 'Overdue: $names$more. Open SubTracker to review.',
      notificationDetails: _buildDetails(
        channelId: _channelOverdue,
        channelName: 'Overdue Alerts',
        importance: Importance.max,
        priority: Priority.max,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // INTERNAL HELPERS
  // ─────────────────────────────────────────────────────────

  /// Schedule a single notification at [hour]:00 on [targetDate].
  /// Silently skips if the target time is already in the past.
  Future<void> _trySchedule({
    required int id,
    required DateTime targetDate,
    required int hour,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    required Importance importance,
    required Priority priority,
  }) async {
    final notifyAt = DateTime(
        targetDate.year, targetDate.month, targetDate.day, hour, 0);
    if (notifyAt.isBefore(DateTime.now())) return;

    final scheduled = tz.TZDateTime.from(notifyAt, tz.local);

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails:
          _buildDetails(channelId: channelId, channelName: channelName,
              importance: importance, priority: priority),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  NotificationDetails _buildDetails({
    required String channelId,
    required String channelName,
    required Importance importance,
    required Priority priority,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription:
            'SubTracker subscription alerts',
        importance: importance,
        priority: priority,
        color: AppTheme.primaryAccent,
        styleInformation: const BigTextStyleInformation(''),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }
}
