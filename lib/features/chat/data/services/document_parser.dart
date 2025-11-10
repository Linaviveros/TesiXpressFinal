// lib/features/chat/data/services/document_parser.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart' as xml;
import 'package:syncfusion_flutter_pdf/pdf.dart';

class DocumentParser {
  /// Extrae texto página por página, preserva orden, limpia ligaduras y guiones.
  static Future<String> extractPdfText(Uint8List bytes) async {
    try {
      final PdfDocument doc = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(doc);
      final buffer = StringBuffer();

      for (int i = 0; i < doc.pages.count; i++) {
        final pageText = extractor.extractText(startPageIndex: i, endPageIndex: i);
        final cleaned = _cleanPdfText(pageText);
        if (cleaned.trim().isNotEmpty) {
          if (buffer.isNotEmpty) buffer.writeln('\n\n');
          buffer.writeln('[[PÁGINA ${i + 1}]]');
          buffer.writeln(cleaned);
        }
      }

      doc.dispose();
      return _postNormalize(buffer.toString()).trim();
    } catch (_) {
      return '';
    }
  }

  static String _cleanPdfText(String s) {
    var out = s;

    // Une palabras cortadas por salto de línea
    out = out.replaceAllMapped(RegExp(r'-\s*\n\s*'), (m) => '');

    // Normaliza saltos
    out = out.replaceAll(RegExp(r'\r'), '\n');
    out = out.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // Ligaduras
    const ligs = {'ﬀ':'ff','ﬁ':'fi','ﬂ':'fl','ﬃ':'ffi','ﬄ':'ffl'};
    ligs.forEach((k, v) => out = out.replaceAll(k, v));

    // Espacios múltiples
    out = out.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
    return out;
  }

  static String _postNormalize(String s) {
    return s
        .replaceAll('\u00A0', ' ')
        .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
        .replaceAll(RegExp(r'\n {1,}'), '\n')
        .trim();
  }

  static Future<String> extractDocxText(Uint8List bytes) async {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final entry = archive.files.firstWhere(
        (f) => f.name.toLowerCase() == 'word/document.xml',
        orElse: () => ArchiveFile('none', 0, Uint8List(0)),
      );
      if (entry.size == 0) return '';
      final xmlStr = utf8.decode(entry.content as List<int>);
      final doc = xml.XmlDocument.parse(xmlStr);
      final buffer = StringBuffer();

      for (final p in doc.findAllElements('w:p')) {
        final texts = p.findAllElements('w:t').map((t) => t.innerText).join();
        if (texts.trim().isNotEmpty) buffer.writeln(texts);
      }

      final raw = buffer.toString();
      return raw
          .replaceAll('\r', '\n')
          .replaceAll('\t', ' ')
          .replaceAll(RegExp(' {2,}'), ' ')
          .replaceAll(RegExp(r'\n{3,}'), '\n\n')
          .trim();
    } catch (_) {
      return '';
    }
  }
}
