import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../repo/auth_repo.dart';
import '../../../viewmodel/auth_vm.dart';
import 'login_screen.dart';
import '../main/main_shell.dart';

/// Watches Firebase auth state and shows either the login flow or the main
/// app. Replaces the old direct navigation from splash to LoginScreen.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthUser?>(
      stream: authVM.authState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.bg(context),
            body: const Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
          );
        }
        return snapshot.data == null ? const LoginScreen() : const MainShell();
      },
    );
  }
}
