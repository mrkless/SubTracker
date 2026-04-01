import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, 
                    color: isDarkMode ? Colors.white : AppTheme.textLight),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Settings',
                  style: TextStyle(
                      color: isDarkMode ? Colors.white : AppTheme.textLight, 
                      fontWeight: FontWeight.bold, 
                      fontSize: 18)),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 54, bottom: 16),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDarkMode 
                      ? [const Color(0xFF1A0E2E), theme.scaffoldBackgroundColor]
                      : [const Color(0xFFF3F4F6), theme.scaffoldBackgroundColor],
                  ),
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 16),
              
              // Profile Section
              _buildSectionHeader('Account', isDarkMode),
              _buildSettingItem(
                context,
                icon: Icons.person_outline_rounded,
                title: 'Email',
                subtitle: user?.email ?? 'Not signed in',
                isDarkMode: isDarkMode,
                onTap: () {},
              ),
              _buildSettingItem(
                context,
                icon: Icons.key_outlined,
                title: 'Change Password',
                subtitle: 'Update your security',
                isDarkMode: isDarkMode,
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textMutedDark),
                onTap: () => _showChangePasswordDialog(context),
              ),

              const SizedBox(height: 24),
              _buildSectionHeader('App Settings', isDarkMode),
              
              // Theme Toggle
              _buildSettingItem(
                context,
                icon: isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                title: 'Appearance',
                subtitle: isDarkMode ? 'Dark Mode' : 'Light Mode',
                isDarkMode: isDarkMode,
                trailing: Switch.adaptive(
                  value: isDarkMode,
                  activeColor: AppTheme.secondaryAccent,
                  inactiveTrackColor: isDarkMode ? AppTheme.surfaceDarkLighter : Colors.grey.shade300,
                  onChanged: (val) {
                    ref.read(themeModeProvider.notifier).toggle();
                  },
                ),
                onTap: () => ref.read(themeModeProvider.notifier).toggle(),
              ),

              _buildSettingItem(
                context,
                icon: Icons.currency_exchange_rounded,
                title: 'Currency',
                subtitle: ref.watch(currencyProvider) == 'USD' ? 'US Dollar (\$)' : 'Philippine Peso (₱)',
                isDarkMode: isDarkMode,
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textMutedDark),
                onTap: () => _showCurrencyDialog(context),
              ),

              _buildSettingItem(
                context,
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                subtitle: 'Manage app alerts',
                isDarkMode: isDarkMode,
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textMutedDark),
                onTap: () {},
              ),

              const SizedBox(height: 24),
              _buildSectionHeader('Support', isDarkMode),
              _buildSettingItem(
                context,
                icon: Icons.help_outline_rounded,
                title: 'Help Center',
                isDarkMode: isDarkMode,
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textMutedDark),
                onTap: () {},
              ),
              _buildSettingItem(
                context,
                icon: Icons.info_outline_rounded,
                title: 'About',
                subtitle: 'Version 1.0.0',
                isDarkMode: isDarkMode,
                onTap: () {},
              ),

              const SizedBox(height: 48),
              
              // Logout Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextButton(
                  onPressed: () => _showLogoutDialog(context),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.error.withOpacity(isDarkMode ? 0.05 : 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: AppTheme.error.withOpacity(0.3)),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: isDarkMode ? AppTheme.secondaryAccent : AppTheme.primaryAccent,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDarkMode ? AppTheme.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isDarkMode ? [] : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Icon(icon, color: isDarkMode ? Colors.white : AppTheme.primaryAccent, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(
                    color: isDarkMode ? Colors.white : AppTheme.textLight, 
                    fontSize: 16, 
                    fontWeight: FontWeight.w600
                  )),
                  if (subtitle != null)
                    Text(subtitle, style: const TextStyle(color: AppTheme.textMutedDark, fontSize: 13)),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: ref.read(themeModeProvider) ? AppTheme.surfaceDark : Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Change Password', 
              style: TextStyle(
                  color: ref.read(themeModeProvider) ? Colors.white : AppTheme.textLight,
                  fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your new password below.', 
                  style: TextStyle(color: AppTheme.textMutedDark)),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: TextStyle(color: ref.read(themeModeProvider) ? Colors.white : AppTheme.textLight),
                decoration: InputDecoration(
                  hintText: 'New Password',
                  filled: true,
                  fillColor: ref.read(themeModeProvider) ? Colors.black26 : Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textMutedDark)),
            ),
            ElevatedButton(
              onPressed: _isChangingPassword ? null : () async {
                final newPass = passwordController.text.trim();
                if (newPass.length < 6) return;
                
                setDialogState(() => _isChangingPassword = true);
                try {
                  await Supabase.instance.client.auth.updateUser(
                    UserAttributes(password: newPass),
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password updated successfully')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                } finally {
                  setDialogState(() => _isChangingPassword = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isChangingPassword 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ref.read(themeModeProvider) ? AppTheme.surfaceDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Select Currency', 
            style: TextStyle(
                color: ref.read(themeModeProvider) ? Colors.white : AppTheme.textLight, 
                fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCurrencyOption(context, 'USD', 'US Dollar (\$)', ref.read(currencyProvider) == 'USD'),
            const SizedBox(height: 8),
            _buildCurrencyOption(context, 'PHP', 'Philippine Peso (₱)', ref.read(currencyProvider) == 'PHP'),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyOption(BuildContext context, String code, String name, bool isSelected) {
    final isDarkMode = ref.read(themeModeProvider);
    return ListTile(
      onTap: () {
        ref.read(currencyProvider.notifier).setCurrency(code);
        Navigator.pop(context);
      },
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: isSelected ? AppTheme.secondaryAccent : AppTheme.textMutedDark,
      ),
      title: Text(name, style: TextStyle(color: isDarkMode ? Colors.white : AppTheme.textLight)),
      trailing: Text(code, style: const TextStyle(color: AppTheme.textMutedDark, fontWeight: FontWeight.bold)),
      tileColor: isSelected ? AppTheme.primaryAccent.withOpacity(0.05) : Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ref.read(themeModeProvider) ? AppTheme.surfaceDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Log Out', 
            style: TextStyle(
                color: ref.read(themeModeProvider) ? Colors.white : AppTheme.textLight, 
                fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out?', style: TextStyle(color: AppTheme.textMutedDark)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMutedDark)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
