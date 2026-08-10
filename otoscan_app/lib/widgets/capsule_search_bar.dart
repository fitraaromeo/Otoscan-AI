import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CapsuleSearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onActionTap;
  final IconData actionIcon;
  final TextEditingController? controller;

  const CapsuleSearchBar({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.onActionTap,
    this.actionIcon = Icons.mic_rounded,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 50 : 12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          filled: false, // Prevent global ThemeData filled rect background from overlaying capsule shape
          fillColor: Colors.transparent,
          hintText: hintText,
          hintStyle: TextStyle(
            color: isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Icon(
              Icons.search_rounded,
              size: 22,
              color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 46, minHeight: 46),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 6, top: 4, bottom: 4),
            child: GestureDetector(
              onTap: onActionTap,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFFFF0ED), // Soft tinted capsule icon background as in screenshot
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  actionIcon,
                  size: 20,
                  color: isDark
                      ? const Color(0xFF38BDF8)
                      : const Color(0xFFEA580C), // Accent orange microphone icon
                ),
              ),
            ),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
