class TextChunker {
  static List<String> splitByHeadingsAndSize(
    String input, {
    int maxChars = 60000,
    int overlap = 600,
  }) {
    final normalized = _normalize(input);
    final sections = _splitByHeadings(normalized);
    if (sections.isEmpty) {
      return _chunkWithOverlap(normalized, maxChars: maxChars, overlap: overlap);
    }
    final chunks = <String>[];
    for (final s in sections) {
      if (s.length <= maxChars) {
        chunks.add(s);
      } else {
        chunks.addAll(_chunkWithOverlap(s, maxChars: maxChars, overlap: overlap));
      }
    }
    return chunks;
  }

  static String _normalize(String s) => s
      .replaceAll('\r', ' ')
      .replaceAll('\t', ' ')
      .replaceAll(RegExp(' {2,}'), ' ')
      .replaceAll('\u00A0', ' ')
      .trim();

  static List<String> _splitByHeadings(String s) {
    final pattern = RegExp(
      r'(?=^\s*(CAP[IÍ]TULO\s+\w+|Cap[ií]tulo\s+\w+|I+\.\s|II+\.\s|III+\.\s|Introducci[oó]n|Marco\s+te[oó]rico|Metodolog[ií]a|Resultados|Discusi[oó]n|Conclusiones|Recomendaciones|Referencias|Anexos)\b)',
      multiLine: true,
    );
    final matches = pattern.allMatches(s).toList();
    if (matches.isEmpty) return [];
    final parts = <String>[];
    for (int i = 0; i < matches.length; i++) {
      final start = matches[i].start;
      final end = (i + 1 < matches.length) ? matches[i + 1].start : s.length;
      parts.add(s.substring(start, end).trim());
    }
    return parts;
  }

  static List<String> _chunkWithOverlap(String s, {required int maxChars, required int overlap}) {
    final result = <String>[];
    int start = 0;
    if (maxChars <= 0) return [s];
    while (start < s.length) {
      final end = (start + maxChars > s.length) ? s.length : start + maxChars;
      result.add(s.substring(start, end));
      if (end == s.length) break;
      start = end - overlap;
      if (start < 0) start = 0;
    }
    return result;
  }
}
