import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'view/theme/app_theme.dart';
import 'view/theme/theme_controller.dart';
import 'repo/services.dart';
import 'view/screens/misc/splash_screen.dart';
import 'package:provider/provider.dart';
import 'viewmodel/auth_vm.dart';
import 'viewmodel/home_vm.dart';
import 'viewmodel/pantry_vm.dart';
import 'viewmodel/shopping_vm.dart';
import 'viewmodel/recipe_vm.dart';
import 'viewmodel/profile_vm.dart';
import 'viewmodel/add_item_vm.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  await Services.init();
  // Restore saved dark-mode preference
  themeController.value =
  Services.settings.darkMode ? ThemeMode.dark : ThemeMode.light;
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authVM),
        ChangeNotifierProvider.value(value: homeVM),
        ChangeNotifierProvider.value(value: pantryVM),
        ChangeNotifierProvider.value(value: shoppingVM),
        ChangeNotifierProvider.value(value: recipeVM),
        ChangeNotifierProvider.value(value: profileVM),
        ChangeNotifierProvider.value(value: addItemVM),
      ],
      child: const ShelfLifeApp(),
    ),
  );
}

class ShelfLifeApp extends StatelessWidget {
  const ShelfLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController,
      builder: (_, mode, __) {
        return MaterialApp(
          title: 'ShelfLife',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
