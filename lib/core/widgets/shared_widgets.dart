import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class UserAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final Color? bg;
  const UserAvatar({super.key, required this.initials, this.size = 40, this.bg});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: bg ?? AppColors.maroon),
    child: Center(child: Text(initials,
      style: TextStyle(color: Colors.white, fontSize: size * 0.35, fontWeight: FontWeight.w800))),
  );
}

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Color? color;
  const AppButton({super.key, required this.label, this.onPressed, this.loading = false, this.color});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? AppColors.maroon,
        foregroundColor: Colors.white, elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        padding: const EdgeInsets.symmetric(vertical: 14)),
      child: loading
        ? const SizedBox(width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        : Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
    ),
  );
}

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? prefixIcon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  const AppTextField({
    super.key, required this.controller, required this.label, required this.hint,
    this.prefixIcon, this.obscure = false, this.suffix,
    this.keyboardType = TextInputType.text, this.validator,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: T.label(AppColors.textSecond)),
      const SizedBox(height: 5),
      TextFormField(
        controller: controller, obscureText: obscure,
        keyboardType: keyboardType, validator: validator,
        style: T.body(AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint, hintStyle: T.body(AppColors.textMuted),
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.textMuted, size: 20) : null,
          suffixIcon: suffix,
          filled: true, fillColor: AppColors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: AppColors.maroon, width: 1.5)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: AppColors.danger)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13)),
      ),
    ],
  );
}
