import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../widgets/app_logo.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});
  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _analytics = true;
  bool _personalized = true;
  bool _location = false;
  bool _crashReports = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const AppLogoText(height: 28),
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? AppColors.primary : AppColors.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            'Privacy & Data',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPri(context),
            ),
          ),
          const SizedBox(height: 14),

          _section(context, 'Data Sharing'),
          _toggleCard(
            context,
            icon: Icons.analytics_outlined,
            title: 'Anonymous Usage Analytics',
            subtitle: 'Help us improve the app',
            value: _analytics,
            onChanged: (v) => setState(() => _analytics = v),
          ),
          _toggleCard(
            context,
            icon: Icons.person_outline,
            title: 'Personalized Recommendations',
            subtitle: 'Based on your pantry & history',
            value: _personalized,
            onChanged: (v) => setState(() => _personalized = v),
          ),
          _toggleCard(
            context,
            icon: Icons.location_on_outlined,
            title: 'Location for Local Recipes',
            subtitle: 'Get region-appropriate ideas',
            value: _location,
            onChanged: (v) => setState(() => _location = v),
          ),
          _toggleCard(
            context,
            icon: Icons.bug_report_outlined,
            title: 'Crash Reports',
            subtitle: 'Send diagnostic data automatically',
            value: _crashReports,
            onChanged: (v) => setState(() => _crashReports = v),
          ),

          const SizedBox(height: 18),
          _section(context, 'Your Data'),
          _navTile(context, Icons.download_outlined, 'Export My Data',
              'Get a copy of everything', () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Export started…')),
            );
          }),
          _navTile(context, Icons.history, 'Login Activity',
              'Recent sign-ins and devices', () {}),
          _navTile(context, Icons.devices_other, 'Connected Devices',
              '2 active devices', () {}),

          const SizedBox(height: 18),
          _section(context, 'Legal'),
          _navTile(context, Icons.description_outlined, 'Terms of Service',
              null, () {}),
          _navTile(context, Icons.policy_outlined, 'Privacy Policy', null,
              () {}),
          _navTile(context, Icons.gavel, 'Cookie Settings', null, () {}),

          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => _showClearDataDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_sweep_outlined, color: AppColors.danger),
                  SizedBox(width: 8),
                  Text(
                    'Clear All My Data',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
            'This removes all your pantry items, shopping list, and preferences. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data cleared.')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
      child: Text(
        s,
        style: const TextStyle(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w700,
          fontSize: 14,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _toggleCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textPri(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPri(context),
                    )),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSec(context),
                    )),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _navTile(BuildContext context, IconData icon, String title,
      String? subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textPri(context)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPri(context),
                      )),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSec(context),
                        )),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: AppColors.textSec(context), size: 20),
          ],
        ),
      ),
    );
  }
}
