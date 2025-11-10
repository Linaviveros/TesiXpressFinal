import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class BannerInfo extends StatelessWidget {
  final String text;
  const BannerInfo({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.panel : AppColors.panelDark),
            border: Border.all(color: isDark ? AppColors.outline : AppColors.outlineDark),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, height: 1.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
