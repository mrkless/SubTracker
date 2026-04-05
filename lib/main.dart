import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'core/constants.dart';
import 'core/auth_provider.dart';
import 'core/services/notification_service.dart';
import 'core/services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Local Storage
  await Hive.initFlutter();
  
  // TODO: Register Hive Adapters here
  // Hive.registerAdapter(SubscriptionAdapter());
  
  // Open Boxes for Caching and Settings
  await Hive.openBox('settings');
  await Hive.openBox('subscriptions_box');

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Initialize Notifications
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();

  // Register background tasks (keep notifications alive when app is closed)
  await registerBackgroundTasks();

  // Completely hide system navigation bar — full immersive screen
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch Theme state (default to Light if not overridden)
    final isDarkMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Subscription Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}

// Provider for controlling Theme Mode
class ThemeModeNotifier extends Notifier<bool> {
  String? get _userId => ref.watch(userIdProvider);

  @override
  bool build() {
    final uid = _userId;
    if (uid == null) return false;
    final settingsBox = Hive.box('settings');
    return settingsBox.get('isDarkMode_$uid', defaultValue: true);
  }

  void toggle() {
    final uid = _userId;
    if (uid == null) return;
    state = !state;
    Hive.box('settings').put('isDarkMode_$uid', state);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, bool>(() {
  return ThemeModeNotifier();
});
