import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../config/theme.dart';

class MessageBubble extends StatelessWidget {
  final bool fromUser;
  final String text;
  final Color accent;
  final bool showHatLoader; // cuando es loader

  const MessageBubble({
    super.key,
    required this.fromUser,
    required this.text,
    required this.accent,
    this.showHatLoader = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = fromUser
        ? (isDark ? const Color(0x14FFFFFF) : Colors.white)
        : accent.withOpacity(isDark ? 0.18 : 0.10);

    final border = fromUser
        ? (isDark ? AppColors.outline : AppColors.outlineDark)
        : accent.withOpacity(0.50);

    // Ajuste de paddings: compactos verticales para evitar “aire” extra
    final bubblePadding = const EdgeInsets.fromLTRB(14, 12, 14, 12);

    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.96, end: 1),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        builder: (_, value, child) => Transform.scale(scale: value, child: child),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: bubblePadding,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(fromUser ? 18 : 6),
                bottomRight: Radius.circular(fromUser ? 6 : 18),
              ),
              border: Border.all(color: border),
              boxShadow: [
                BoxShadow(
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                  color: fromUser ? Colors.transparent : accent.withOpacity(0.12),
                ),
              ],
            ),
            child: showHatLoader
                ? const _HatLoader()
                : fromUser
                    ? _UserText(text: text)
                    : _MarkdownPretty(
                        data: _stripMarkdownMarkers(text),
                        accent: accent,
                      ),
          ),
        ),
      ),
    );
  }
}

class _UserText extends StatelessWidget {
  final String text;
  const _UserText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 15, height: 1.38));
  }
}

/// Loader con “sombrero” (mortarboard) animado inspirado en el splash.
class _HatLoader extends StatefulWidget {
  const _HatLoader();

  @override
  State<_HatLoader> createState() => _HatLoaderState();
}

class _HatLoaderState extends State<_HatLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: 120,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final t = _ctrl.value * 2 * math.pi;
          final r = 18.0;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 42, width: 42,
                decoration: BoxDecoration(
                  color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: const Icon(Icons.school, size: 26),
              ),
              for (int i = 0; i < 3; i++)
                Positioned(
                  left: 60 + r * math.cos(t + (i * 2 * math.pi / 3)) - 4,
                  top: 24 + r * math.sin(t + (i * 2 * math.pi / 3)) - 4,
                  child: Container(
                    height: 8, width: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [BoxShadow(blurRadius: 12, color: Colors.white)],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Render bonito para el contenido del asistente
class _MarkdownPretty extends StatelessWidget {
  final String data;
  final Color accent;
  const _MarkdownPretty({required this.data, required this.accent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final sheet = MarkdownStyleSheet.fromTheme(theme).copyWith(
      h3: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 0.2),
      h4: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 15),
      p: const TextStyle(fontSize: 14.5, height: 1.5),
      blockquoteDecoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        border: Border(left: BorderSide(color: accent.withOpacity(0.6), width: 3)),
      ),
      blockquotePadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      code: TextStyle(
        fontFamily: 'monospace',
        fontSize: 13,
        backgroundColor: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: isDark ? AppColors.outline : AppColors.outlineDark)),
      ),
      listIndent: 0,
    );

    return MarkdownBody(
      data: data,
      styleSheet: sheet,
      softLineBreak: true,
      selectable: false,
      onTapLink: (text, href, title) {},
    );
  }
}

String _stripMarkdownMarkers(String src) {
  final lines = src.split('\n');
  final out = <String>[];
  for (var l in lines) {
    var s = l.trimRight();
    s = s.replaceFirst(RegExp(r'^#{1,6}\s*'), '');  // encabezados
    s = s.replaceFirst(RegExp(r'^\s*[-*+]\s+'), ''); // bullets
    s = s.replaceFirst(RegExp(r'^\s*\d+\.\s+'), ''); // números
    out.add(s);
  }
  return out.join('\n');
}
