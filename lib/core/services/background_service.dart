import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:sub_tracker/features/subscriptions/models/subscription_model.dart';
import 'notification_service.dart';

const String kDailyRescheduleTask  = 'subtracker.daily_reschedule';
const String kOverdueCheckTask     = 'subtracker.overdue_check';

// ─────────────────────────────────────────────────────────────────
// TOP-LEVEL dispatcher — runs OUTSIDE the Flutter engine.
// Must be a plain top-level function (no class).
// ─────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      // Boot Hive (no Flutter widgets needed)
      await Hive.initFlutter();
      final settingsBox = await Hive.openBox('settings');
      final subsBox     = await Hive.openBox('subscriptions_box');

      // Init timezone
      tz.initializeTimeZones();
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));

      // Init notification plugin (no UI needed)
      final plugin = FlutterLocalNotificationsPlugin();
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      await plugin.initialize(
        settings: const InitializationSettings(android: androidSettings),
      );

      switch (taskName) {

        // ── Reschedule daily tip ──────────────────────────────
        case kDailyRescheduleTask:
          final notificationsEnabled =
              settingsBox.get('notifications_enabled', defaultValue: true);
          if (!notificationsEnabled) break;

          // Pick today's tip
          final now        = DateTime.now();
          final dayOfYear  = now.difference(DateTime(now.year)).inDays;
          final tips       = _tips();
          final tip        = tips[dayOfYear % tips.length];

          // Schedule for tomorrow 10 AM (today's fires shortly)
          final tomorrow = DateTime(now.year, now.month, now.day + 1, 10, 0);
          final scheduled = tz.TZDateTime.from(tomorrow, tz.local);

          await plugin.zonedSchedule(
            id: 999999,
            title: tip['title']!,
            body: tip['body']!,
            scheduledDate: scheduled,
            notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                'daily_tips',
                'Daily Tips & Insights',
                channelDescription: 'Daily subscription tips and trivia',
                importance: Importance.defaultImportance,
                priority: Priority.defaultPriority,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
          );
          break;

        // ── Check overdue subscriptions ───────────────────────
        case kOverdueCheckTask:
          final notificationsEnabled =
              settingsBox.get('notifications_enabled', defaultValue: true);
          if (!notificationsEnabled) break;

          // Find any cached user key to read subscriptions
          final keys = subsBox.keys
              .where((k) => k.toString().startsWith('cache_'))
              .toList();

          for (final key in keys) {
            final cachedData = subsBox.get(key);
            if (cachedData == null) continue;

            final subs = (cachedData as List)
                .map((s) {
                  try {
                    return Subscription.fromJson(jsonDecode(s));
                  } catch (_) {
                    return null;
                  }
                })
                .whereType<Subscription>()
                .toList();

            final now      = DateTime.now();
            final overdue  = subs
                .where((s) => s.nextBillingDate.isBefore(now))
                .toList();

            if (overdue.isNotEmpty) {
              final names = overdue.take(3).map((s) => s.name).join(', ');
              final more  = overdue.length > 3
                  ? ' +${overdue.length - 3} more'
                  : '';

              await plugin.show(
                id: 888888,
                title: '🚨 Overdue Subscriptions!',
                body: 'Still unpaid: $names$more. Open SubTracker to review.',
                notificationDetails: const NotificationDetails(
                  android: AndroidNotificationDetails(
                    'overdue_alerts',
                    'Overdue Alerts',
                    channelDescription: 'Alerts for overdue subscription payments',
                    importance: Importance.max,
                    priority: Priority.max,
                  ),
                ),
              );
            }
          }
          break;
      }

      return Future.value(true);
    } catch (e) {
      return Future.value(false);
    }
  });
}

/// Registers both periodic background tasks.
/// Call once from main() after NotificationService.initialize().
Future<void> registerBackgroundTasks() async {
  if (kIsWeb) return;

  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );

  // Daily tip refresh — every 24 hours
  await Workmanager().registerPeriodicTask(
    kDailyRescheduleTask,
    kDailyRescheduleTask,
    frequency: const Duration(hours: 24),
    initialDelay: const Duration(minutes: 5),
  );

  // Overdue check — every 12 hours
  await Workmanager().registerPeriodicTask(
    kOverdueCheckTask,
    kOverdueCheckTask,
    frequency: const Duration(hours: 12),
    initialDelay: const Duration(minutes: 2),
  );
}

// Local copy of tips (same as NotificationService) so the
// dispatcher doesn't need to import the main app bundle.
List<Map<String, String>> _tips() => const [
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
