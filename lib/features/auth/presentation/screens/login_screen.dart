import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cdc_app/core/theme/app_colors.dart';
import 'package:cdc_app/core/theme/app_text_styles.dart';
import 'package:cdc_app/core/widgets/shared_widgets.dart';
import 'package:cdc_app/data/services/supabase_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _fk      = GlobalKey<FormState>();
  final _emailC  = TextEditingController();
  final _passC   = TextEditingController();
  bool _obscure  = true;
  bool _loading  = false;
  String? _error;

  late AnimationController _ctrl;
  late Animation<double>   _fade;
  late Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.light));
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() { _emailC.dispose(); _passC.dispose(); _ctrl.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (!_fk.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() { _loading = true; _error = null; });
    try {
      final user = await SupabaseService().login(_emailC.text.trim(), _passC.text);
      if (!mounted) return;
      if (user == null) { setState(() => _error = 'Email ou mot de passe incorrect.'); return; }
      if (user.mustChangePassword) { Navigator.pushReplacementNamed(context, '/change-password'); return; }
      Navigator.pushReplacementNamed(context, '/home');
    } catch (_) {
      setState(() => _error = 'Erreur de connexion. Vérifiez votre réseau.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.offWhite,
    body: Column(children: [
      _header(),
      Expanded(child: FadeTransition(opacity: _fade,
        child: SlideTransition(position: _slide,
          child: Container(
            transform: Matrix4.translationValues(0, -20, 0),
            decoration: const BoxDecoration(
              color: AppColors.offWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              child: Form(key: _fk, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Connexion', style: T.h2(AppColors.textPrimary).copyWith(fontSize: 24)),
                  const SizedBox(height: 24),
                  
                  Text('ADRESSE EMAIL', style: T.label(AppColors.textPrimary).copyWith(fontSize: 10, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailC,
                    style: T.body(AppColors.textPrimary),
                    decoration: _inputDecoration('votre.nom@courdescomptes.ma', Icons.email_outlined),
                    validator: (v) => v!.isEmpty ? 'Email requis' : null,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  Text('MOT DE PASSE', style: T.label(AppColors.textPrimary).copyWith(fontSize: 10, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passC,
                    obscureText: _obscure,
                    style: T.body(AppColors.textPrimary),
                    decoration: _inputDecoration('••••••••', Icons.lock_outline).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, 
                          color: AppColors.textMuted, size: 20),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? 'Mot de passe requis' : null,
                  ),
                  
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: T.small(AppColors.danger)),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.maroon,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _loading 
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : const Text('SE CONNECTER', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                    ),
                  ),
                ],
              )),
            ),
          )))),
    ]),
  );

  InputDecoration _inputDecoration(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: T.body(AppColors.textMuted).copyWith(fontSize: 14),
    prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.maroon, width: 1.5),
    ),
  );

  Widget _header() => Container(
    width: double.infinity,
    color: AppColors.maroon,
    padding: const EdgeInsets.fromLTRB(24, 60, 24, 60),
    child: Column(children: [
      // Double cercle avec bouclier au centre
      Container(
        width: 100, height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.gold.withOpacity(0.4), width: 1),
        ),
        child: Center(
          child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold.withOpacity(0.7), width: 1.5),
            ),
            child: const Center(
              child: Icon(Icons.verified_user_outlined, color: Colors.white, size: 38),
            ),
          ),
        ),
      ),
      const SizedBox(height: 24),
      Text('ROYAUME DU MAROC',
        style: TextStyle(color: AppColors.gold.withOpacity(0.8),
          fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      const Text('Cour des Comptes',
        style: TextStyle(color: Colors.white, fontSize: 28,
          fontWeight: FontWeight.w700, letterSpacing: -0.5)),
      const SizedBox(height: 4),
      Text('ESPACE INSTITUTIONNEL SÉCURISÉ',
        style: TextStyle(color: Colors.white.withOpacity(0.6),
          fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w500)),
    ]),
  );
}
