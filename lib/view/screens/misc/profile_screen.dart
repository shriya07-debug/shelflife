import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../constants/app_strings.dart';
import '../../../viewmodel/auth_vm.dart';
import '../../../viewmodel/home_vm.dart';
import '../../../viewmodel/pantry_vm.dart';
import '../../../viewmodel/profile_vm.dart';
import '../../widgets/vm_listener.dart';
import 'edit_profile_screen.dart';
import 'privacy_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VMListener(
      listenable: Listenable.merge([authVM, profileVM, pantryVM, homeVM]),
      builder: (ctx) {
        final displayName = authVM.currentUser?.displayName ??
            authVM.profile?.displayName ??
            AppStrings.defaultName;
        final email = authVM.currentUser?.email ??
            authVM.profile?.email ??
            'guest@shelflife.app';
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.pageHPad, 12, AppSizes.pageHPad, 32),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPri(context),
                            )),
                        Text(email,
                            style: TextStyle(
                                color: AppColors.textSec(context),
                                fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit_outlined,
                        color: AppColors.textSec(context)),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EditProfileScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _analyticsSection(context),
              const SizedBox(height: 20),
              _settingsGroup(context, 'Preferences', [
                _switchTile(
                  context,
                  Icons.dark_mode_outlined,
                  'Dark mode',
                  profileVM.darkMode,
                  (v) => profileVM.setDarkMode(v),
                ),
                _tile(context, Icons.lock_outline, 'Privacy', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PrivacyScreen()),
                  );
                }),
              ]),
              const SizedBox(height: 20),
              _settingsGroup(context, 'Data', [
                _tile(context, Icons.refresh, 'Reset demo data', () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dc) => AlertDialog(
                      title: const Text('Reset all data?'),
                      content: const Text(
                          'This will restore the original 20 seed items and clear your current pantry, shopping list, and favorites.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(dc, false),
                            child: const Text(AppStrings.cancel)),
                        TextButton(
                            onPressed: () => Navigator.pop(dc, true),
                            style: TextButton.styleFrom(
                                foregroundColor: AppColors.danger),
                            child: const Text('Reset')),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await profileVM.resetDemoData();
                    pantryVM.notifyListeners();
                    homeVM.notifyListeners();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Demo data reset')),
                      );
                    }
                  }
                }),
              ]),
              const SizedBox(height: 20),
              _settingsGroup(context, 'Account', [
                _tile(context, Icons.logout, 'Log out', () async {
                  await authVM.signOut();
                  // AuthGate reacts
                }),
                _tile(context, Icons.delete_forever_outlined,
                    'Delete account', () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dc) => AlertDialog(
                      title: const Text('Delete your account?'),
                      content: const Text(
                          'This will permanently delete your account and all your data. This cannot be undone.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(dc, false),
                            child: const Text(AppStrings.cancel)),
                        TextButton(
                            onPressed: () => Navigator.pop(dc, true),
                            style: TextButton.styleFrom(
                                foregroundColor: AppColors.danger),
                            child: const Text('Delete')),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    final ok = await authVM.deleteAccount();
                    if (!ok && authVM.error != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(authVM.error!)),
                      );
                    }
                  }
                }, danger: true),
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _analyticsSection(BuildContext context) {
    // Real waste % (bug fix #5) and real category distribution (bug fix #4)
    final wasted = homeVM.wastedPercent;
    final trend = homeVM.wasteTrend;
    final categories = homeVM.categoryDistribution;

    // If no data, hide charts and show a message
    if (categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(Icons.pie_chart_outline,
                color: AppColors.textMut(context), size: 40),
            const SizedBox(height: 10),
            Text('Add some items to see analytics',
                style: TextStyle(color: AppColors.textSec(context))),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Analytics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPri(context),
              )),
          const SizedBox(height: 12),
          Row(
            children: [
              // Waste %
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Wasted %',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSec(context))),
                    Text('${wasted.toStringAsFixed(1)}%',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPri(context))),
                    SizedBox(
                      height: 40,
                      child: LineChart(LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              for (int i = 0; i < trend.length; i++)
                                FlSpot(i.toDouble(), trend[i])
                            ],
                            isCurved: true,
                            color: AppColors.primary,
                            barWidth: 2,
                            dotData: const FlDotData(show: false),
                          ),
                        ],
                      )),
                    ),
                  ],
                ),
              ),
              // Category donut
              Expanded(
                child: SizedBox(
                  height: 110,
                  child: PieChart(PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 24,
                    sections: _pieSections(categories),
                  )),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 4,
            children: categories.entries.map((e) {
              final color = _categoryColor(e.key);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, color: color),
                  const SizedBox(width: 4),
                  Text('${e.key} (${e.value})',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSec(context))),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _pieSections(Map<String, int> data) {
    final total = data.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return [];
    return data.entries.map((e) {
      final pct = e.value / total * 100;
      return PieChartSectionData(
        value: e.value.toDouble(),
        title: '${pct.toStringAsFixed(0)}%',
        color: _categoryColor(e.key),
        radius: 32,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      );
    }).toList();
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'Dairy':     return const Color(0xFF60A5FA);
      case 'Produce':   return AppColors.primary;
      case 'Meat':      return const Color(0xFFEF4444);
      case 'Grains':    return const Color(0xFFF59E0B);
      case 'Beverages': return const Color(0xFF8B5CF6);
      case 'Snacks':    return const Color(0xFFEC4899);
      default:          return AppColors.neutral;
    }
  }

  Widget _settingsGroup(
      BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSec(context),
              )),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _tile(BuildContext context, IconData icon, String label,
      VoidCallback onTap,
      {bool danger = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(icon,
                color: danger
                    ? AppColors.danger
                    : AppColors.textPri(context),
                size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                    fontSize: 15,
                    color: danger
                        ? AppColors.danger
                        : AppColors.textPri(context),
                  )),
            ),
            Icon(Icons.chevron_right,
                color: AppColors.textMut(context), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _switchTile(BuildContext context, IconData icon, String label,
      bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textPri(context), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textPri(context),
                )),
          ),
          Switch(
            activeThumbColor: AppColors.primary,
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
