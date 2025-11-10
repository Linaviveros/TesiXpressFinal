import 'dart:convert';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatMeta {
  final String id;
  final String title;
  final String? style; // "APA" | "IEEE" | null
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool firstUploadDone;       // ✅ ocultar aviso tras primera carga
  final bool pendingStyleNotice;    // ✅ mostrar/ocultar aviso de regla

  ChatMeta({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.style,
    this.firstUploadDone = false,
    this.pendingStyleNotice = false,
  });

  ChatMeta copyWith({
    String? title,
    String? style,
    DateTime? updatedAt,
    bool? firstUploadDone,
    bool? pendingStyleNotice,
  }) => ChatMeta(
    id: id,
    title: title ?? this.title,
    style: style ?? this.style,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    firstUploadDone: firstUploadDone ?? this.firstUploadDone,
    pendingStyleNotice: pendingStyleNotice ?? this.pendingStyleNotice,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'style': style,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'first_upload_done': firstUploadDone,
    'pending_style_notice': pendingStyleNotice,
  };

  static ChatMeta fromJson(Map<String, dynamic> m) => ChatMeta(
    id: (m['id'] ?? '').toString(),
    title: (m['title'] ?? '').toString(),
    style: m['style'] == null ? null : m['style'].toString(),
    createdAt: DateTime.tryParse((m['created_at'] ?? '').toString()) ?? DateTime.now(),
    updatedAt: DateTime.tryParse((m['updated_at'] ?? '').toString()) ?? DateTime.now(),
    firstUploadDone: (m['first_upload_done'] ?? false) == true,
    pendingStyleNotice: (m['pending_style_notice'] ?? false) == true,
  );
}

class PersistentMemoryService {
  static const bucket = 'session_memory';
  final SupabaseClient _client;
  final String _userId;

  PersistentMemoryService(this._client, this._userId);

  String get _userRoot => 'users/$_userId';
  String get _indexPath => '$_userRoot/index.json';
  String chatPath(String chatId) => '$_userRoot/chats/$chatId.jsonl';

  // ---------- Index helpers ----------
  Future<List<ChatMeta>> listChats() async {
    final idx = await _downloadText(_indexPath);
    if (idx.isEmpty) return [];
    try {
      final data = jsonDecode(idx) as Map<String, dynamic>;
      final arr = (data['chats'] as List? ?? []);
      return arr.map((e) => ChatMeta.fromJson(e as Map<String, dynamic>)).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (_) {
      return [];
    }
  }

  Future<ChatMeta?> getMeta(String chatId) async {
    final items = await listChats();
    return items.where((c) => c.id == chatId).cast<ChatMeta?>().fold<ChatMeta?>(null, (p, c) => c ?? p);
  }

  Future<void> _saveIndex(List<ChatMeta> items) async {
    final text = jsonEncode({'chats': items.map((e) => e.toJson()).toList()});
    await _uploadText(_indexPath, text);
  }

  Future<String> createChat({required String chatId, required String title, String? style}) async {
    final now = DateTime.now().toUtc();
    final meta = ChatMeta(
      id: chatId,
      title: title,
      style: style,
      createdAt: now,
      updatedAt: now,
      firstUploadDone: false,
      pendingStyleNotice: false,
    );

    final current = await listChats();
    current.removeWhere((c) => c.id == chatId);
    current.insert(0, meta);
    await _saveIndex(current);

    await _uploadText(chatPath(chatId), ''); // crear .jsonl vacío
    return chatId;
  }

  Future<void> deleteChat(String chatId) async {
    final current = await listChats();
    current.removeWhere((c) => c.id == chatId);
    await _saveIndex(current);
    try {
      await _client.storage.from(bucket).remove([chatPath(chatId)]);
    } catch (_) {
      // ignorar errores de borrado físico para no bloquear la UI
    }
  }

  Future<void> renameChat(String chatId, String newTitle) async {
    final current = await listChats();
    final i = current.indexWhere((c) => c.id == chatId);
    if (i == -1) return;
    current[i] = current[i].copyWith(title: newTitle, updatedAt: DateTime.now().toUtc());
    await _saveIndex(current);
  }

  Future<void> setStyle(String chatId, String? style) async {
    final current = await listChats();
    final i = current.indexWhere((c) => c.id == chatId);
    if (i == -1) return;
    // Cuando se elige estilo: activar aviso pendiente y marcar que aún no hay primera carga
    current[i] = current[i].copyWith(
      style: style,
      pendingStyleNotice: style != null,
      firstUploadDone: false,
      updatedAt: DateTime.now().toUtc(),
    );
    await _saveIndex(current);
  }

  Future<void> setFirstUploadDone(String chatId) async {
    final current = await listChats();
    final i = current.indexWhere((c) => c.id == chatId);
    if (i == -1) return;
    current[i] = current[i].copyWith(
      firstUploadDone: true,
      pendingStyleNotice: false,
      updatedAt: DateTime.now().toUtc(),
    );
    await _saveIndex(current);
  }

  // ---------- History helpers ----------
  Future<void> append(String chatId, String role, String content) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final line = jsonEncode({'role': role, 'content': content, 'ts': now}) + '\n';

    final current = await _downloadText(chatPath(chatId));
    final updated = current + line;
    await _uploadText(chatPath(chatId), updated);

    // touch index updatedAt
    final idx = await listChats();
    final i = idx.indexWhere((c) => c.id == chatId);
    if (i != -1) {
      idx[i] = idx[i].copyWith(updatedAt: DateTime.now().toUtc());
      await _saveIndex(idx);
    }
  }

  Future<List<Map<String, String>>> readHistory(String chatId, {int maxItems = 60}) async {
    final text = await _downloadText(chatPath(chatId));
    if (text.isEmpty) return [];
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final tail = lines.length > maxItems ? lines.sublist(lines.length - maxItems) : lines;
    final out = <Map<String, String>>[];
    for (final l in tail) {
      try {
        final m = jsonDecode(l) as Map<String, dynamic>;
        final role = (m['role'] ?? '').toString();
        final content = (m['content'] ?? '').toString();
        if (role.isNotEmpty && content.isNotEmpty) {
          out.add({'role': role, 'content': content});
        }
      } catch (_) {}
    }
    return out;
  }

  // ---------- Low-level ----------
  Future<String> _downloadText(String path) async {
    try {
      final bytes = await _client.storage.from(bucket).download(path);
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return '';
    }
  }

  Future<void> _uploadText(String path, String text) async {
    await _client.storage.from(bucket).uploadBinary(
      path,
      Uint8List.fromList(utf8.encode(text)),
      fileOptions: const FileOptions(
        upsert: true,
        cacheControl: 'no-store',
        contentType: 'text/plain; charset=utf-8',
      ),
    );
  }
}
