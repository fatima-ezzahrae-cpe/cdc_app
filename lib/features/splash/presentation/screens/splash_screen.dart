import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cdc_app/core/theme/app_colors.dart';
import 'package:cdc_app/data/services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade, _scale;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.light));
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(seconds: 2));
    // Try auto login from saved session
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      if (userData != null) {
        final map = jsonDecode(userData);
        final svc = SupabaseService();
        final user = await svc.login(map['email'], map['password']);
        if (user != null && mounted) {
          Navigator.pushReplacementNamed(context, '/home');
          return;
        }
      }
    } catch (_) {}
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.maroon,
    body: Stack(children: [
      Positioned(top: -80, right: -80, child: Container(
        width: 240, height: 240,
        decoration: BoxDecoration(shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.04)))),
      Positioned(bottom: -60, left: -60, child: Container(
        width: 180, height: 180,
        decoration: BoxDecoration(shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.04)))),
      Positioned(top: 0, left: 0, right: 0,
        child: Container(height: 3, color: AppColors.gold.withOpacity(0.5))),
      Center(child: FadeTransition(opacity: _fade,
        child: ScaleTransition(scale: _scale,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 100, height: 100,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
                border: Border.all(color: AppColors.gold, width: 2)),
              child: const Center(child: Icon(Icons.balance, color: Colors.white, size: 46))),
            const SizedBox(height: 24),
            Text('ROYAUME DU MAROC',
              style: TextStyle(color: AppColors.gold.withOpacity(0.85),
                fontSize: 10, letterSpacing: 3, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text('COUR DES COMPTES',
              style: TextStyle(color: Colors.white, fontSize: 20,
                fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            const SizedBox(height: 44),
            SizedBox(width: 26, height: 26,
              child: CircularProgressIndicator(
                color: AppColors.gold.withOpacity(0.8), strokeWidth: 1.5)),
          ])))),
    ]),
  );
}
