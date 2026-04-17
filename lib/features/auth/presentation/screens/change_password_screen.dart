import 'package:flutter/material.dart';
import 'package:cdc_app/core/theme/app_colors.dart';
import 'package:cdc_app/core/theme/app_text_styles.dart';
import 'package:cdc_app/core/widgets/shared_widgets.dart';
import 'package:cdc_app/data/services/supabase_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _fk    = GlobalKey<FormState>();
  final _passC = TextEditingController();
  final _confC = TextEditingController();
  bool _obs1 = true, _obs2 = true, _saving = false;
  String? _error;

  @override
  void dispose() { _passC.dispose(); _confC.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_fk.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    final ok = await SupabaseService().changePassword(_passC.text.trim());
    if (!mounted) return;
    if (!ok) { setState(() { _error = 'Erreur. Réessayez.'; _saving = false; }); return; }
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService().currentUser;
    final canGoBack = !(user?.mustChangePassword ?? false);
    
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(children: [
        Container(color: AppColors.maroon,
          child: SafeArea(bottom: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            child: Row(children: [
              if (canGoBack) ...[
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32, height: 32,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(9)),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 19))),
              ] else ...[
                Container(width: 32, height: 32,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                    border: Border.all(color: AppColors.gold.withOpacity(0.5))),
                  child: const Icon(Icons.balance, color: Colors.white, size: 16)),
                const SizedBox(width: 10),
              ],
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('COUR DES COMPTES',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                Text('ROYAUME DU MAROC',
                  style: TextStyle(color: AppColors.gold, fontSize: 8, letterSpacing: 1.5)),
              ]),
            ])))),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Form(key: _fk, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Container(padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: AppColors.border)),
                child: Row(children: [
                  UserAvatar(initials: user?.initials ?? '?', size: 46, bg: AppColors.gold),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(user?.fullName ?? '', style: T.bold(AppColors.textPrimary)),
                    Text(user?.email ?? '', style: T.small(AppColors.textMuted),
                      overflow: TextOverflow.ellipsis),
                  ])),
                ])),
              const SizedBox(height: 14),
              Container(padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.goldPale,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: AppColors.gold.withOpacity(0.4))),
                child: Row(children: [
                  const Icon(Icons.lock_outline, size: 16, color: Color(0xFF7A5A10)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    canGoBack ? 'Vous pouvez changer votre mot de passe actuel ici.' : 'Créez votre mot de passe personnel avant de continuer.',
                    style: T.small(const Color(0xFF7A5A10)))),
                ])),
              const SizedBox(height: 24),
              Text('Changement de mot de passe', style: T.h3(AppColors.textPrimary)),
              const SizedBox(height: 18),
              _passField(_passC, 'NOUVEAU MOT DE PASSE *', 'Minimum 6 caractères',
                _obs1, () => setState(() => _obs1 = !_obs1),
                (v) { if (v!.isEmpty) return 'Requis';
                      if (v.length < 6) return 'Minimum 6 caractères'; return null; }),
              const SizedBox(height: 14),
              _passField(_confC, 'CONFIRMER *', 'Répétez le mot de passe',
                _obs2, () => setState(() => _obs2 = !_obs2),
                (v) { if (v!.isEmpty) return 'Requis';
                      if (v != _passC.text) return 'Mots de passe différents'; return null; }),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: T.small(AppColors.danger)),
              ],
              const SizedBox(height: 24),
              AppButton(label: 'ENREGISTRER', loading: _saving, onPressed: _submit),
            ],
          )),
        )),
      ]),
    );
  }

  Widget _passField(TextEditingController c, String label, String hint,
      bool obscure, VoidCallback onToggle, String? Function(String?) validator) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: T.label(AppColors.textSecond)),
      const SizedBox(height: 5),
      TextFormField(
        controller: c, obscureText: obscure, validator: validator,
        style: T.body(AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint, hintStyle: T.body(AppColors.textMuted),
          filled: true, fillColor: AppColors.white,
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppColors.textMuted, size: 20), onPressed: onToggle),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: AppColors.maroon, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13)),
      ),
    ]);
}
