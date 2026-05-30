import 'package:flutter/material.dart';
import 'app_logo.dart';

class OnboardingHeader extends StatelessWidget {
  const OnboardingHeader({super.key});
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          AppLogoIcon(size: 36),
          SizedBox(width: 8),
          AppLogoText(height: 30),
        ],
      ),
    );
  }
}
