import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../viewmodel/auth_vm.dart';
import '../main/main_shell.dart';
import 'login_screen.dart';

/// Watches authStateChanges and routes to Login or MainShell accordingly.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authVM.authStateChanges,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.bg(context),
            body: const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          );
        }
        if (snap.hasData) {
          return const MainShell();
        }
        return const LoginScreen();
      },
    );
  }
}
