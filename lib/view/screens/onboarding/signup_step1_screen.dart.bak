import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../widgets/onboarding_header.dart';
import 'signup_step2_screen.dart';

class SignupStep1Screen extends StatefulWidget {
  const SignupStep1Screen({super.key});
  @override
  State<SignupStep1Screen> createState() => _SignupStep1ScreenState();
}

class _SignupStep1ScreenState extends State<SignupStep1Screen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _bdayCtrl = TextEditingController();
  String? _gender;
  bool _obscure = true;
  DateTime? _birthdate;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _bdayCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthdate ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select your birthdate',
    );
    if (picked != null) {
      setState(() {
        _birthdate = picked;
        _bdayCtrl.text =
            '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            const OnboardingHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Step 1 of 3',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDark)),
                        Text('Account Basics',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDark)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        value: 0.33,
                        minHeight: 5,
                        backgroundColor: Color(0xFFCFE7D2),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Create your account',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPri(context),
                        )),
                    const SizedBox(height: 8),
                    Text(
                      "Let's start with some basic information to get your pantry organized.",
                      style: TextStyle(
                          color: AppColors.textSec(context), fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        'assets/onboarding/signup_pantry.png',
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 180,
                          color: const Color(0xFFE9DCC4),
                          child: const Center(
                            child: Icon(Icons.kitchen,
                                size: 64, color: Colors.brown),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _label(context, 'Full Name'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person_outline),
                        hintText: 'Enter your full name',
                      ),
                    ),
                    const SizedBox(height: 16),
                    _label(context, 'Email Address'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.mail_outline),
                        hintText: 'example@email.com',
                      ),
                    ),
                    const SizedBox(height: 16),
                    _label(context, 'Password'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline),
                        hintText: 'Min. 8 characters',
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(builder: (_, c) {
                      if (c.maxWidth < 340) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label(context, 'Birthdate'),
                            const SizedBox(height: 6),
                            _bdayField(),
                            const SizedBox(height: 16),
                            _label(context, 'Gender'),
                            const SizedBox(height: 6),
                            _genderField(isExpanded: true),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label(context, 'Birthdate'),
                                const SizedBox(height: 6),
                                _bdayField(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label(context, 'Gender'),
                                const SizedBox(height: 6),
                                _genderField(isExpanded: true),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SignupStep2Screen()),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Next Step'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                                color: AppColors.textPri(context),
                                fontSize: 14),
                            children: const [
                              TextSpan(text: 'Already have an account? '),
                              TextSpan(
                                text: 'Log in',
                                style: TextStyle(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bdayField() => TextField(
        controller: _bdayCtrl,
        readOnly: true,
        onTap: _pickBirthdate,
        decoration: InputDecoration(
          hintText: 'mm/dd/yyyy',
          isDense: true,
          suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_today, size: 18),
            onPressed: _pickBirthdate,
          ),
        ),
      );

  Widget _genderField({bool isExpanded = false}) =>
      DropdownButtonFormField<String>(
        initialValue: _gender,
        isExpanded: isExpanded,
        decoration: const InputDecoration(isDense: true),
        hint: const Text('Select'),
        items: const [
          DropdownMenuItem(value: 'M', child: Text('Male')),
          DropdownMenuItem(value: 'F', child: Text('Female')),
          DropdownMenuItem(value: 'O', child: Text('Other')),
          DropdownMenuItem(value: 'N', child: Text('Prefer not to say')),
        ],
        onChanged: (v) => setState(() => _gender = v),
      );

  Widget _label(BuildContext c, String s) => Text(s,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: AppColors.textPri(c),
      ));
}
