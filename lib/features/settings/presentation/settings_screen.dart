import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/theme.dart';
import '../../../main.dart';
import '../../../core/currency_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isChangingPassword = false;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _notificationsEnabled =
        Hive.box('settings').get('notifications_enabled', defaultValue: true);
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      // Force external application for better reliability
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        throw 'Launch failed';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open link: $url'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeModeProvider);
    ref.watch(currencyProvider);
    final theme = Theme.of(context);
    final user = Supabase.instance.client.auth.currentUser;
    final currencyCode = ref.read(currencyProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 100.0,
            floating: false,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: isDarkMode ? Colors.white : AppTheme.headingLight,
                  size: 20),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Settings',
                  style: TextStyle(
                      color: isDarkMode ? Colors.white : AppTheme.headingLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 20)),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 54, bottom: 16),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDarkMode
                        ? [const Color(0xFF1A0E2E), theme.scaffoldBackgroundColor]
                        : [const Color(0xFFE0E7FF), theme.scaffoldBackgroundColor], // Indigo-tinted bg for light mode
                  ),
                ),
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 8),

              // ── Profile Card ──────────────────────────────────
              _ProfileCard(user: user, isDarkMode: isDarkMode),

              const SizedBox(height: 28),

              // ── Appearance ───────────────────────────────────
              _SectionLabel(label: 'Appearance', isDarkMode: isDarkMode),
              _SettingsCard(
                isDarkMode: isDarkMode,
                children: [
                  _SettingRow(
                    icon: isDarkMode
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    iconColor: const Color(0xFF7B61FF),
                    title: 'Theme',
                    subtitle: isDarkMode ? 'Dark Mode' : 'Light Mode',
                    isDarkMode: isDarkMode,
                    trailing: Switch.adaptive(
                      value: isDarkMode,
                      activeColor: isDarkMode ? AppTheme.secondaryAccent : AppTheme.primaryLight,
                      inactiveTrackColor: isDarkMode
                          ? AppTheme.surfaceDarkLighter
                          : Colors.grey.shade300,
                      onChanged: (_) =>
                          ref.read(themeModeProvider.notifier).toggle(),
                    ),
                    onTap: () => ref.read(themeModeProvider.notifier).toggle(),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Preferences ──────────────────────────────────
              _SectionLabel(label: 'Preferences', isDarkMode: isDarkMode),
              _SettingsCard(
                isDarkMode: isDarkMode,
                children: [
                  _SettingRow(
                    icon: Icons.currency_exchange_rounded,
                    iconColor: const Color(0xFF4ECDC4),
                    title: 'Currency',
                    subtitle: currencyCode == 'USD'
                        ? 'US Dollar (\$)'
                        : 'Philippine Peso (₱)',
                    isDarkMode: isDarkMode,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isDarkMode ? AppTheme.primaryAccent : AppTheme.primaryLight).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(currencyCode,
                          style: TextStyle(
                              color: isDarkMode ? AppTheme.primaryAccent : AppTheme.primaryLight,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ),
                    onTap: () => _showCurrencyDialog(),
                  ),
                  _Divider(isDarkMode: isDarkMode),
                  _SettingRow(
                    icon: Icons.notifications_active_outlined,
                    iconColor: const Color(0xFFFF8B94),
                    title: 'Notifications',
                    subtitle: _notificationsEnabled
                        ? 'Subscription alerts enabled'
                        : 'Notifications off',
                    isDarkMode: isDarkMode,
                    trailing: Switch.adaptive(
                      value: _notificationsEnabled,
                      activeColor: isDarkMode ? AppTheme.secondaryAccent : AppTheme.primaryLight,
                      inactiveTrackColor: isDarkMode
                          ? AppTheme.surfaceDarkLighter
                          : Colors.grey.shade300,
                      onChanged: (val) {
                        setState(() => _notificationsEnabled = val);
                        Hive.box('settings')
                            .put('notifications_enabled', val);
                      },
                    ),
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Account ──────────────────────────────────────
              _SectionLabel(label: 'Account', isDarkMode: isDarkMode),
              _SettingsCard(
                isDarkMode: isDarkMode,
                children: [
                  _SettingRow(
                    icon: Icons.key_outlined,
                    iconColor: const Color(0xFFFFBF47),
                    title: 'Change Password',
                    subtitle: 'Update your security credentials',
                    isDarkMode: isDarkMode,
                    trailing: Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: AppTheme.textMutedDark),
                    onTap: () => _showChangePasswordDialog(),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Developer & Info ─────────────────────────────
              _SectionLabel(label: 'Developer & Info', isDarkMode: isDarkMode),
              _SettingsCard(
                isDarkMode: isDarkMode,
                children: [
                  // Developer profile row
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDarkMode 
                                ? [AppTheme.primaryAccent, AppTheme.secondaryAccent]
                                : [AppTheme.primaryLight, AppTheme.skyBlue],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: Text('LB',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Lester Bucag',
                                  style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white
                                          : AppTheme.headingLight,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              const Text('Developer',
                                  style: TextStyle(
                                      color: AppTheme.textMutedDark,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _Divider(isDarkMode: isDarkMode),
                  // Email
                  _SettingRow(
                    icon: Icons.mail_outline_rounded,
                    iconColor: const Color(0xFF4AC3FF),
                    title: 'Contact',
                    subtitle: 'mrklessbucag@gmail.com',
                    isDarkMode: isDarkMode,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4AC3FF).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Email',
                          style: TextStyle(
                              color: Color(0xFF4AC3FF),
                              fontWeight: FontWeight.w600,
                              fontSize: 12)),
                    ),
                    onTap: () =>
                        _launchUrl('mailto:mrklessbucag@gmail.com'),
                  ),
                  _Divider(isDarkMode: isDarkMode),
                  // Portfolio
                  _SettingRow(
                    icon: Icons.public_rounded,
                    iconColor: const Color(0xFF81C784),
                    title: 'Portfolio',
                    subtitle: 'mrkless-portfolio.vercel.app',
                    isDarkMode: isDarkMode,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF81C784).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Visit',
                          style: TextStyle(
                              color: Color(0xFF81C784),
                              fontWeight: FontWeight.w600,
                              fontSize: 12)),
                    ),
                    onTap: () => _launchUrl(
                        'https://mrkless-portfolio.vercel.app'),
                  ),
                  _Divider(isDarkMode: isDarkMode),
                  // About / Disclaimer
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFBF47).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.info_outline_rounded,
                              color: Color(0xFFFFBF47), size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('SubTracker v1.0.0',
                                  style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white
                                          : AppTheme.headingLight,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              const SizedBox(height: 4),
                              const Text(
                                'This app is intended for testing and personal use only. '
                                'It is not an official commercial product.',
                                style: TextStyle(
                                    color: AppTheme.textMutedDark,
                                    fontSize: 12,
                                    height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── Logout Button ────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GestureDetector(
                  onTap: () => _showLogoutDialog(),
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppTheme.error.withOpacity(isDarkMode ? 0.08 : 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppTheme.error.withOpacity(0.3), width: 1),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded,
                            color: AppTheme.error, size: 20),
                        SizedBox(width: 10),
                        Text('Log Out',
                            style: TextStyle(
                                color: AppTheme.error,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ]),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // DIALOGS
  // ──────────────────────────────────────────────────────────────

  void _showCurrencyDialog() {
    final isDarkMode = ref.read(themeModeProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? AppTheme.surfaceDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Select Currency',
            style: TextStyle(
                color: isDarkMode ? Colors.white : AppTheme.headingLight,
                fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CurrencyOption(
              code: 'USD',
              name: 'US Dollar',
              symbol: '\$',
              isSelected: ref.read(currencyProvider) == 'USD',
              isDarkMode: isDarkMode,
              onTap: () {
                ref.read(currencyProvider.notifier).setCurrency('USD');
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
            _CurrencyOption(
              code: 'PHP',
              name: 'Philippine Peso',
              symbol: '₱',
              isSelected: ref.read(currencyProvider) == 'PHP',
              isDarkMode: isDarkMode,
              onTap: () {
                ref.read(currencyProvider.notifier).setCurrency('PHP');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final isDarkMode = ref.read(themeModeProvider);
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: isDarkMode ? AppTheme.surfaceDark : Colors.white,
          surfaceTintColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Change Password',
              style: TextStyle(
                  color: isDarkMode ? Colors.white : AppTheme.headingLight,
                  fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your new password below.',
                  style: TextStyle(color: AppTheme.textMutedDark)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                obscureText: true,
                style: TextStyle(
                    color: isDarkMode ? Colors.white : AppTheme.headingLight),
                decoration: InputDecoration(
                  hintText: 'New Password (min 6 chars)',
                  hintStyle:
                      const TextStyle(color: AppTheme.textMutedDark),
                  filled: true,
                  fillColor:
                      isDarkMode ? Colors.black26 : Colors.grey.shade100,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textMutedDark)),
            ),
            ElevatedButton(
              onPressed: _isChangingPassword
                  ? null
                  : () async {
                      final newPass = ctrl.text.trim();
                      if (newPass.length < 6) return;
                      setDialogState(() => _isChangingPassword = true);
                      try {
                        await Supabase.instance.client.auth
                            .updateUser(UserAttributes(password: newPass));
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Password updated successfully')),
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      } finally {
                        setDialogState(() => _isChangingPassword = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? AppTheme.primaryAccent : AppTheme.primaryLight,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isChangingPassword
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    final isDarkMode = ref.read(themeModeProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? AppTheme.surfaceDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Log Out',
            style: TextStyle(
                color: isDarkMode ? Colors.white : AppTheme.headingLight,
                fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out?',
            style: TextStyle(color: AppTheme.textMutedDark)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textMutedDark)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// REUSABLE COMPONENTS
// ──────────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final dynamic user;
  final bool isDarkMode;
  const _ProfileCard({required this.user, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final email = user?.email ?? 'Not signed in';
    final firstName =
        user?.userMetadata?['first_name'] as String? ?? '';
    final lastName =
        user?.userMetadata?['last_name'] as String? ?? '';
    final displayName =
        (firstName.isNotEmpty || lastName.isNotEmpty)
            ? '$firstName $lastName'.trim()
            : email.split('@').first;
    final initials = firstName.isNotEmpty
        ? '${firstName[0]}${lastName.isNotEmpty ? lastName[0] : ''}'
            .toUpperCase()
        : email[0].toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode 
              ? [AppTheme.primaryAccent.withOpacity(0.25), AppTheme.secondaryAccent.withOpacity(0.1)]
              : [AppTheme.primaryLight.withOpacity(0.15), AppTheme.skyBlue.withOpacity(0.08)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppTheme.primaryAccent
                  .withOpacity(isDarkMode ? 0.3 : 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDarkMode 
                    ? [AppTheme.primaryAccent, AppTheme.secondaryAccent]
                    : [AppTheme.primaryLight, AppTheme.skyBlue],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(initials,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName,
                      style: TextStyle(
                          color: isDarkMode ? Colors.white : AppTheme.headingLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 17)),
                  const SizedBox(height: 3),
                  Text(email,
                      style: const TextStyle(
                          color: AppTheme.textMutedDark, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDarkMode;
  const _SectionLabel({required this.label, required this.isDarkMode});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: isDarkMode
                ? AppTheme.secondaryAccent
                : AppTheme.primaryLight,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
      );
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  final bool isDarkMode;
  const _SettingsCard(
      {required this.children, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? AppTheme.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isDarkMode
                  ? AppTheme.surfaceDarkLighter
                  : AppTheme.borderLight),
          boxShadow: isDarkMode
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(children: children),
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _SettingRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: isDarkMode
                              ? Colors.white
                              : AppTheme.headingLight,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: const TextStyle(
                            color: AppTheme.textMutedDark,
                            fontSize: 12)),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDarkMode;
  const _Divider({required this.isDarkMode});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Divider(
          height: 1,
          color: isDarkMode
              ? AppTheme.surfaceDarkLighter
              : AppTheme.borderLight,
        ),
      );
}

class _CurrencyOption extends StatelessWidget {
  final String code;
  final String name;
  final String symbol;
  final bool isSelected;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _CurrencyOption({
    required this.code,
    required this.name,
    required this.symbol,
    required this.isSelected,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDarkMode ? AppTheme.primaryAccent : AppTheme.primaryLight).withOpacity(0.1)
              : (isDarkMode
                  ? AppTheme.surfaceDark
                  : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isSelected
                  ? (isDarkMode ? AppTheme.primaryAccent : AppTheme.primaryLight).withOpacity(0.5)
                  : (isDarkMode
                      ? AppTheme.surfaceDarkLighter
                      : Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDarkMode ? AppTheme.primaryAccent : AppTheme.primaryLight)
                    : AppTheme.textMutedDark.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(symbol,
                    style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppTheme.textMutedDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: TextStyle(
                          color: isDarkMode
                              ? Colors.white
                              : AppTheme.headingLight,
                          fontWeight: FontWeight.w600)),
                  Text(code,
                      style: const TextStyle(
                          color: AppTheme.textMutedDark,
                          fontSize: 12)),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded,
                  color: isDarkMode ? AppTheme.primaryAccent : AppTheme.primaryLight, size: 22),
          ],
        ),
      ),
    );
  }
}
