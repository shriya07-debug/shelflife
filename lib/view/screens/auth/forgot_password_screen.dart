import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../viewmodel/auth_vm.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _busy = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy) return;
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _snack('Please enter your email.');
      return;
    }
    setState(() => _busy = true);
    final error = await authVM.sendPasswordReset(email);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _sent = error == null;
    });
    if (error != null) _snack(error);
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPri(context)),
        title: Text('Reset Password',
            style: TextStyle(color: AppColors.textPri(context))),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _sent
                  ? 'If an account exists for that email, a reset link is on its way. Check your inbox.'
                  : "Enter your account email and we'll send you a password reset link.",
              style: TextStyle(color: AppColors.textSec(context), fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.mail_outline),
                hintText: 'you@example.com',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : _send,
                child: Text(_sent ? 'Resend link' : 'Send reset link'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
