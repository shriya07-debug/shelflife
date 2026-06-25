import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_strings.dart';
import '../../widgets/app_logo.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameCtrl =
      TextEditingController(text: AppStrings.userName);
  final _emailCtrl =
      TextEditingController(text: AppStrings.userEmail);
  final _phoneCtrl = TextEditingController(text: '+977 98XXXXXXXX');
  final _bioCtrl =
      TextEditingController(text: 'Trying to waste less and cook more.');

  bool _currentObscure = true;
  bool _newObscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

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
            'Edit Profile',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPri(context),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.chipBg(context),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/profile/avatar_default.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.person,
                        size: 50,
                        color: AppColors.textMut(context),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryDark,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ---- Personal info ----
          _sectionLabel('Personal Information'),
          const SizedBox(height: 8),
          _formCard(
            context,
            child: Column(
              children: [
                _field('Full Name', _nameCtrl, Icons.person_outline),
                const SizedBox(height: 12),
                _field('Email Address', _emailCtrl, Icons.email_outlined,
                    type: TextInputType.emailAddress),
                const SizedBox(height: 12),
                _field('Phone Number', _phoneCtrl, Icons.phone_outlined,
                    type: TextInputType.phone),
                const SizedBox(height: 12),
                _field('Bio', _bioCtrl, Icons.notes, maxLines: 3),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ---- Password ----
          _sectionLabel('Change Password'),
          const SizedBox(height: 8),
          _formCard(
            context,
            child: Column(
              children: [
                TextField(
                  obscureText: _currentObscure,
                  decoration: InputDecoration(
                    hintText: 'Current password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_currentObscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () => setState(
                          () => _currentObscure = !_currentObscure),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  obscureText: _newObscure,
                  decoration: InputDecoration(
                    hintText: 'New password',
                    prefixIcon: const Icon(Icons.lock_reset),
                    suffixIcon: IconButton(
                      icon: Icon(_newObscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () => setState(() => _newObscure = !_newObscure),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile saved.')),
              );
              Navigator.pop(context);
            },
            child: const Text('Save Changes'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String s) {
    return Text(
      s,
      style: const TextStyle(
        color: AppColors.primaryDark,
        fontWeight: FontWeight.w700,
        fontSize: 14,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _formCard(BuildContext context, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  Widget _field(String hint, TextEditingController c, IconData icon,
      {TextInputType type = TextInputType.text, int maxLines = 1}) {
    return TextField(
      controller: c,
      keyboardType: type,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
    );
  }
}
