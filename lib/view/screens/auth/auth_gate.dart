import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../repo/auth_repo.dart';
import '../../../repo/services.dart';
import '../../../viewmodel/auth_vm.dart';
import 'login_screen.dart';
import '../main/main_shell.dart';

/// Watches auth state via a StreamBuilder so it reliably rebuilds on both
/// login and logout. When a user is present, it binds that user's Firestore
/// repos (showing a loader) before revealing the main app.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _uid;
  Future<void>? _bind;

  Future<void> _ensureBound(String uid) {
    if (_uid != uid) {
      _uid = uid;
      _bind = Services.bindUser(uid);
    }
    return _bind!;
  }

  Widget _loader() => Scaffold(
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthUser?>(
      stream: authVM.authState,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return _loader();

        final user = snap.data;
        if (user == null) {
          _uid = null;
          _bind = null;
          Services.unbindUser();
          return const LoginScreen();
        }

        return FutureBuilder<void>(
          future: _ensureBound(user.uid),
          builder: (context, bindSnap) {
            if (bindSnap.connectionState != ConnectionState.done) {
              return _loader();
            }
            if (bindSnap.hasError) {
              return Scaffold(
                backgroundColor: AppColors.bg(context),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Couldn't load your data.\nCheck your connection and retry.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textPri(context)),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {
                            _uid = null;
                            _bind = null;
                          }),
                          child: const Text('Retry'),
                        ),
                        TextButton(
                          onPressed: () => authVM.signOut(),
                          child: const Text('Log out'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return const MainShell();
          },
        );
      },
    );
  }
}
