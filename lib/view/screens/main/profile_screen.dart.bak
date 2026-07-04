import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_strings.dart';
import '../../../viewmodel/profile_vm.dart';
import '../../../viewmodel/pantry_vm.dart';
import '../../widgets/main_app_bar.dart';
import '../../widgets/vm_listener.dart';
import '../auth/login_screen.dart';
import '../misc/edit_profile_screen.dart';
import '../misc/privacy_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(),
      body: VMListener(
        listenable: Listenable.merge([profileVM, pantryVM]),
        builder: (ctx) {
          final darkOn = profileVM.darkMode;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              _avatar(),
              const SizedBox(height: 12),
              Center(
                child: Text(AppStrings.userName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPri(context),
                    )),
              ),
              Center(
                child: Text(AppStrings.userEmail,
                    style: TextStyle(
                        color: AppColors.textSec(context), fontSize: 14)),
              ),
              const SizedBox(height: 20),
              _settingsCard(context, darkOn),
              const SizedBox(height: 14),
              _dietaryCard(context),
              const SizedBox(height: 14),
              _allergiesCard(context),
              const SizedBox(height: 14),
              _analyticsCard(context),
              const SizedBox(height: 14),
              _navTile(context, Icons.manage_accounts, 'Edit Profile Details',
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const EditProfileScreen()),
                );
              }),
              const SizedBox(height: 10),
              _navTile(context, Icons.shield_outlined, 'Privacy & Data',
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                );
              }),
              const SizedBox(height: 10),
              _navTile(context, Icons.restart_alt, 'Reset Demo Data', () {
                _showResetDialog(context);
              }),
              const SizedBox(height: 20),
              // ---- Log Out ----
              GestureDetector(
                onTap: () => _confirmLogout(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: AppColors.primaryDark),
                      SizedBox(width: 8),
                      Text('Log Out',
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // ---- Delete Account ----
              GestureDetector(
                onTap: () => _confirmDeleteAccount(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline, color: AppColors.danger),
                      SizedBox(width: 8),
                      Text('Delete Account',
                          style: TextStyle(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text('ShelfLife Version 4.0.0',
                    style: TextStyle(
                        color: AppColors.textMut(context), fontSize: 12)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
            'You will be returned to the login screen. Your data stays on this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark),
            onPressed: () {
              profileVM.logout();
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
            'This wipes ALL your pantry, shopping list and favorites permanently. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              await profileVM.deleteAccount();
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset Demo Data?'),
        content: const Text(
            'This wipes the pantry, shopping list and favorites, then reloads sample data. Useful for demos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await profileVM.resetDemoData();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Demo data reset.')),
                );
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Widget _avatar() {
    return Center(
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryLight, width: 3),
            ),
            child: CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.chipBg(context),
              child: ClipOval(
                child: Image.asset(
                  'assets/profile/avatar_default.png',
                  width: 96, height: 96,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.person,
                    size: 48,
                    color: AppColors.textMut(context),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0, bottom: 4,
            child: Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(
                color: AppColors.primaryDark,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsCard(BuildContext context, bool darkOn) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('App Settings',
              style: TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              )),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.dark_mode_outlined,
                  color: AppColors.textPri(context)),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Dark Mode',
                    style: TextStyle(
                        fontSize: 15, color: AppColors.textPri(context))),
              ),
              Switch(
                value: darkOn,
                onChanged: (v) => profileVM.setDarkMode(v),
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.notifications_active_outlined,
                  color: AppColors.textPri(context)),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Push Notifications',
                    style: TextStyle(
                        fontSize: 15, color: AppColors.textPri(context))),
              ),
              Switch(
                value: _notifications,
                onChanged: (v) => setState(() => _notifications = v),
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dietaryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('Dietary Focus',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  )),
              Spacer(),
              Icon(Icons.restaurant, color: AppColors.primaryDark),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              _pill('Vegetarian', AppColors.primaryLight,
                  AppColors.primaryDark),
              _pill('Organic', AppColors.primaryLight, AppColors.primaryDark),
              _pill('Gluten-Free', const Color(0xFFFFF3E0),
                  const Color(0xFFB45309)),
              _pill('+ Add Focus', AppColors.chipBg(context),
                  AppColors.textPri(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _allergiesCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        border: const Border(
          left: BorderSide(color: AppColors.danger, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Allergies & Sensitivities',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              )),
          const SizedBox(height: 12),
          _allergyRow(context, 'Peanuts & Tree Nuts'),
          const SizedBox(height: 8),
          _allergyRow(context, 'Shellfish'),
        ],
      ),
    );
  }

  Widget _allergyRow(BuildContext context, String s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bg(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.danger, size: 22),
          const SizedBox(width: 10),
          Expanded(
              child: Text(s,
                  style: TextStyle(
                      fontSize: 15, color: AppColors.textPri(context)))),
          Icon(Icons.close, color: AppColors.textPri(context), size: 20),
        ],
      ),
    );
  }

  Widget _analyticsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('Pantry Analytics',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  )),
              Spacer(),
              Icon(Icons.bar_chart, color: AppColors.primaryDark),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Waste Reduction',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSec(context))),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 80,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, _) {
                                  const labels = ['Jan', 'Feb', 'Mar', 'Apr'];
                                  if (v.toInt() < 0 ||
                                      v.toInt() >= labels.length) {
                                    return const SizedBox.shrink();
                                  }
                                  return Text(labels[v.toInt()],
                                      style: TextStyle(
                                        color:
                                            AppColors.textSec(context),
                                        fontSize: 11,
                                      ));
                                },
                                reservedSize: 20,
                              ),
                            ),
                          ),
                          minX: 0, maxX: 3,
                          minY: 0, maxY: 10,
                          lineBarsData: [
                            LineChartBarData(
                              spots: const [
                                FlSpot(0, 7),
                                FlSpot(1, 6),
                                FlSpot(2, 4),
                                FlSpot(3, 3),
                              ],
                              isCurved: true,
                              color: AppColors.primaryDark,
                              barWidth: 2.5,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppColors.primaryLight
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Category Distribution',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSec(context))),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 110,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 0,
                              centerSpaceRadius: 30,
                              startDegreeOffset: 270,
                              sections: _pieSections(),
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('${pantryVM.totalActiveCount}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPri(context),
                                  )),
                              Text('items',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color:
                                          AppColors.textSec(context))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _LegendDot(
                            color: AppColors.primaryDark,
                            label: 'Produce'),
                        SizedBox(width: 10),
                        _LegendDot(
                            color: AppColors.primaryLight,
                            label: 'Dairy'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _pieSections() {
    final items = pantryVM.active;
    if (items.isEmpty) {
      return [
        PieChartSectionData(
          value: 100,
          color: AppColors.chipBg(context),
          radius: 14,
          showTitle: false,
        ),
      ];
    }
    final produce = items.where((i) => i.category == 'Produce').length;
    final dairy = items.where((i) => i.category == 'Dairy').length;
    return [
      PieChartSectionData(
        value: produce.toDouble().clamp(0.1, 100),
        color: AppColors.primaryDark,
        radius: 14,
        showTitle: false,
      ),
      PieChartSectionData(
        value: dairy.toDouble().clamp(0.1, 100),
        color: AppColors.primaryLight,
        radius: 14,
        showTitle: false,
      ),
    ];
  }

  Widget _pill(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
    );
  }

  Widget _navTile(BuildContext context, IconData icon, String label,
      VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textPri(context)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPri(context),
                  )),
            ),
            Icon(Icons.chevron_right, color: AppColors.textSec(context)),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11, color: AppColors.textSec(context))),
      ],
    );
  }
}
