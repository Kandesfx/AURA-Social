import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

/// AURA Social – Entry Point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xFF14141F),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // TODO: Firebase.initializeApp() – uncomment khi thêm Firebase
  // await Firebase.initializeApp();

  runApp(
    const ProviderScope(
      child: AuraApp(),
    ),
  );
}
