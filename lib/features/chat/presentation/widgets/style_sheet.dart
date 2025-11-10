import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

enum CitationStyle { apa, ieee }

class StyleSheetChooser extends StatelessWidget {
  final CitationStyle? current;
  const StyleSheetChooser({super.key, this.current});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xCC151820) : Colors.white.withOpacity(0.92)),
            border: Border(top: BorderSide(color: isDark ? AppColors.outline : AppColors.outlineDark)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(height: 4, width: 44, decoration: BoxDecoration(color: (isDark?AppColors.outline:AppColors.outlineDark), borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 12),
              const Text('Selecciona la norma de evaluación', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _Item(
                color: kAPA,
                title: 'APA (azul)',
                selected: current == CitationStyle.apa,
                onTap: () => Navigator.pop(context, CitationStyle.apa),
              ),
              _Item(
                color: kIEEE,
                title: 'IEEE (rojo)',
                selected: current == CitationStyle.ieee,
                onTap: () => Navigator.pop(context, CitationStyle.ieee),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final Color color;
  final String title;
  final bool selected;
  final VoidCallback onTap;
  const _Item({required this.color, required this.title, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: selected ? color : Theme.of(context).dividerColor),
        color: selected ? color.withOpacity(0.10) : Colors.transparent,
      ),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color, radius: 16, child: const Icon(Icons.rule, size: 16, color: Colors.white)),
        title: Text(title),
        trailing: AnimatedOpacity(
          opacity: selected ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: Icon(Icons.check_circle, color: color),
        ),
        onTap: onTap,
      ),
    );
  }
}
