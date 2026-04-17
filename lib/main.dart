import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cdc_app/core/theme/app_colors.dart';
import 'package:cdc_app/data/models/models.dart';
import 'package:cdc_app/data/services/supabase_service.dart';
import 'package:cdc_app/features/splash/presentation/screens/splash_screen.dart';
import 'package:cdc_app/features/auth/presentation/screens/login_screen.dart';
import 'package:cdc_app/features/auth/presentation/screens/change_password_screen.dart';
import 'package:cdc_app/features/home/presentation/screens/home_screen.dart';
import 'package:cdc_app/features/missions/presentation/screens/mission_detail_screen.dart';
import 'package:cdc_app/features/events/presentation/screens/event_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr', null);
  await SupabaseService.initialize();
  runApp(const CdcApp());
}

class CdcApp extends StatelessWidget {
  const CdcApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Cour des Comptes',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.maroon, primary: AppColors.maroon),
      scaffoldBackgroundColor: AppColors.offWhite,
    ),
    initialRoute: '/splash',
    onGenerateRoute: (s) {
      switch (s.name) {
        case '/splash':          return _fade(const SplashScreen());
        case '/login':           return _slide(const LoginScreen());
        case '/change-password': return _slide(const ChangePasswordScreen());
        case '/home':            return _fade(const HomeScreen());
        case '/mission-detail':
          return _slide(MissionDetailScreen(mission: s.arguments as Mission));
        case '/event-detail':
          return _slide(EventDetailScreen(event: s.arguments as AppEvent));
        default: return _fade(const HomeScreen());
      }
    },
  );

  static PageRoute _fade(Widget p) => PageRouteBuilder(
    pageBuilder: (_, __, ___) => p,
    transitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
  );

  static PageRoute _slide(Widget p) => PageRouteBuilder(
    pageBuilder: (_, __, ___) => p,
    transitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (_, a, __, c) => SlideTransition(
      position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: a, curve: Curves.easeOut)),
      child: c),
  );
}
