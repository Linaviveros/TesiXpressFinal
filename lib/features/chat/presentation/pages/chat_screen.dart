import 'dart:math' as math;
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../config/env.dart';
import '../../../../config/theme.dart';
import '../../../../shared/services/supabase_client.dart';
import '../../../../shared/widgets/banner_info.dart';
import '../../data/services/document_parser.dart';
import '../../data/services/openai_service.dart';
import '../../data/services/prompt_loader.dart';
import '../../data/services/memory_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/style_sheet.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

// ==== Modelo mínimo para renderizar mensajes en el ChatScreen ====
class _Bubble {
  final bool fromUser;
  final String text;
  final bool isLoader;
  final Key? key;

  const _Bubble(this.fromUser, this.text, {this.isLoader = false, this.key});

  factory _Bubble.user(String t) => _Bubble(true, t);
  factory _Bubble.assistant(String t) => _Bubble(false, t);
  factory _Bubble.loader({Key? key}) => _Bubble(false, '…', isLoader: true, key: key);
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  // ✅ llave para abrir Drawer desde AppBar en móvil
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Estado de UI / tema
  bool _isDark = true;
  Color _accent = kBeige;

  // Modelo IA
  late final OpenAIService _openai;
  String _systemPrompt = '';
  String _rubric = '';
  CitationStyle? _style;

  // Persistencia
  late final PersistentMemoryService _store;
  List<ChatMeta> _chats = [];
  String? _currentChatId;

  // Flags por chat
  bool _firstUploadDone = false;        // para ocultar aviso post-carga
  bool _pendingStyleNotice = false;     // mostrar aviso de regla hasta primera carga

  // Mensajes UI
  final List<_Bubble> _messages = [];
  bool _allowQuestions = false;
  bool _busy = false;

  // Input / scroll
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _showScrollDown = false;

  // Loader “sombrero”
  late final AnimationController _hatCtrl;

  // ✅ loader central SOLO para primera carga
  bool _showCenterLoader = false;

  @override
  void initState() {
    super.initState();

    _openai = OpenAIService(apiKey: Env.openaiApiKey, model: Env.openaiModel);
    _loadPrompt();

    final uid = Supa.client.auth.currentUser?.id;
    if (uid == null) return;
    _store = PersistentMemoryService(Supa.client, uid);

    // ✅ Al iniciar SIEMPRE un chat nuevo (sesión fresca)
    _bootFreshChat();

    _scroll.addListener(_onScroll);
    _hatCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  }

  Future<void> _bootFreshChat() async {
    // Cargar catálogo (para el panel), pero abrir un chat nuevo
    await _loadChats(initialOpen: false);
    await _newChat(); // abre el nuevo por defecto
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    final atBottom = pos.pixels >= pos.maxScrollExtent - 12;
    if (_showScrollDown == atBottom) return;
    setState(() => _showScrollDown = !atBottom);
  }

  Future<void> _loadPrompt() async {
    final p = await PromptLoader.load();
    setState(() {
      _systemPrompt = p['system'] ?? '';
      _rubric = p['rubric'] ?? '';
    });
  }

  Future<void> _loadChats({bool initialOpen = false}) async {
    final items = await _store.listChats();
    setState(() => _chats = items);
    if (initialOpen && items.isNotEmpty) {
      await _openChat(items.first.id);
    }
  }

  // ========== Chat management ==========
  Future<void> _newChat() async {
    await _finalizeCurrentChatTitle(); // ✅ guardar título antes de cambiar
    final id = const Uuid().v4();
    await _store.createChat(chatId: id, title: 'Nuevo chat');
    await _loadChats();
    await _openChat(id, fresh: true);
  }

  Future<void> _openChat(String chatId, {bool fresh = false}) async {
    await _finalizeCurrentChatTitle(); // ✅ guardar título del chat saliente

    setState(() {
      _currentChatId = chatId;
      _messages.clear();
      _allowQuestions = false;
      _firstUploadDone = false;
      _pendingStyleNotice = false;
      _showCenterLoader = false;
    });

    // Meta de chat (estilo y flags)
    final meta = await _store.getMeta(chatId);
    _style = switch (meta?.style) { 'APA' => CitationStyle.apa, 'IEEE' => CitationStyle.ieee, _ => null };
    _accent = _style == CitationStyle.apa ? kAPA : _style == CitationStyle.ieee ? kIEEE : kBeige;
    _firstUploadDone = meta?.firstUploadDone ?? false;
    _pendingStyleNotice = meta?.pendingStyleNotice ?? false;

    // Historial
    final history = await _store.readHistory(chatId);

    // Render histórico, pero si ya hubo primera carga, ocultar aviso de estilo
    for (final m in history) {
      final role = m['role'];
      final content = m['content'] ?? '';
      final isStyleNotice = content.startsWith('AVISO: Regla seleccionada');
      if (_firstUploadDone && isStyleNotice) continue; // 🔕 ocultar aviso
      if (role == 'user') {
        _messages.add(_Bubble.user(content));
      } else if (role == 'assistant') {
        _messages.add(_Bubble.assistant(content));
      }
    }

    // Mensaje de bienvenida si chat vacío
    if (history.isEmpty) {
      _messages.add(_Bubble.assistant('Hola 👋. Elige APA/IEEE y sube tu documento (PDF o DOCX).'));
    }

    // Si hay aviso pendiente (regla ya elegida), muéstralo como mensaje (persistente)
    if (_pendingStyleNotice && !_firstUploadDone && _style != null) {
      final styleStr = _style == CitationStyle.apa ? 'APA' : 'IEEE';
      // Solo dibujar si aún no existe en historial
      final already = history.any((m) => (m['content'] ?? '').startsWith('AVISO: Regla seleccionada'));
      if (!already) {
        _messages.add(_Bubble.assistant('AVISO: Regla seleccionada → $styleStr.\nSube tu documento para iniciar el análisis.'));
        await _store.append(chatId, 'assistant', 'AVISO: Regla seleccionada → $styleStr.\nSube tu documento para iniciar el análisis.');
      }
    }

    _allowQuestions = _firstUploadDone; // solo preguntas luego de primera carga
    _jumpToBottom(immediate: true);
    if (mounted) setState(() {});
  }

  Future<void> _renameChat(ChatMeta meta) async {
    final ctrl = TextEditingController(text: meta.title);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renombrar chat'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Título')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
        ],
      ),
    );
    if (ok == true) {
      await _store.renameChat(meta.id, ctrl.text.trim().isEmpty ? 'Chat' : ctrl.text.trim());
      await _loadChats();
    }
  }

  Future<void> _deleteChat(ChatMeta meta) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar chat'),
        content: Text('Se eliminará “${meta.title}”. Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok == true) {
      await _store.deleteChat(meta.id);
      if (_currentChatId == meta.id) {
        setState(() {
          _currentChatId = null;
          _messages.clear();
          _allowQuestions = false;
          _firstUploadDone = false;
          _pendingStyleNotice = false;
        });
      }
      await _loadChats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat eliminado.')));
      }
    }
  }

  Future<void> _chooseStyle() async {
    final sel = await showModalBottomSheet<CitationStyle>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StyleSheetChooser(current: _style),
    );
    if (sel != null) {
      setState(() {
        _style = sel;
        _accent = sel == CitationStyle.apa ? kAPA : kIEEE;
      });
      if (_currentChatId != null) {
        final styleStr = sel == CitationStyle.apa ? 'APA' : 'IEEE';
        await _store.setStyle(_currentChatId!, styleStr);
        // ✅ mostrar/registrar aviso persistente hasta 1a carga
        _pendingStyleNotice = true;
        _firstUploadDone = false;
        _messages.add(_Bubble.assistant('AVISO: Regla seleccionada → $styleStr.\nSube tu documento para iniciar el análisis.'));
        await _store.append(_currentChatId!, 'assistant', 'AVISO: Regla seleccionada → $styleStr.\nSube tu documento para iniciar el análisis.');
      }
      setState(() {});
    }
  }

  // ========== Documento y preguntas ==========
  Future<void> _pickAndAnalyze() async {
    if (_currentChatId == null) {
      await _newChat();
    }
    if (Env.openaiApiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falta la API key.')));
      return;
    }
    if (_style == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Primero elige APA o IEEE.')));
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'],
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;

    final isInitialLoad = !_firstUploadDone; // ✅ decidir tipo de loader
    if (isInitialLoad) setState(() => _showCenterLoader = true);
    setState(() => _busy = true);

    try {
      String extracted = '';
      final ext = (file.extension ?? '').toLowerCase();
      if (ext == 'pdf') {
        extracted = await DocumentParser.extractPdfText(bytes);
      } else if (ext == 'docx') {
        extracted = await DocumentParser.extractDocxText(bytes);
      }

      if (extracted.isEmpty) {
        setState(() {
          _showCenterLoader = false;
          _messages.add(_Bubble.assistant('No pude leer el archivo. Intenta con otro PDF o DOCX editable.'));
        });
        return;
      }

      final styleStr = _style == CitationStyle.apa ? 'APA' : 'IEEE';
      final sys = _systemPrompt.replaceAll('{{STYLE}}', styleStr);
      final rubric = _rubric.replaceAll('{{STYLE}}', styleStr);

      await _store.append(_currentChatId!, 'system', sys);
      await _store.append(_currentChatId!, 'user', 'INICIO ANÁLISIS — Documento completo.');
      await _store.append(_currentChatId!, 'user', 'Rúbrica:\n$rubric');

      if (!isInitialLoad) {
        // preguntas posteriores: loader en burbuja
        setState(() => _messages.add(_Bubble.loader()));
        _jumpToBottom();
      }

      final history = await _store.readHistory(_currentChatId!, maxItems: 60);

      final response = await _openai.chatComplete(
        systemPrompt: sys,
        userContent: 'ANALIZA TODO EL DOCUMENTO (texto literal a continuación) y devuelve feedback según la rúbrica.\n\n=== TEXTO COMPLETO ===\n$extracted',
        history: history,
        temperature: 0.2,
      );

      // ✅ título automático con snippet de respuesta
      if (response.isNotEmpty) {
        final title = _deriveTitleFrom(response);
        await _store.renameChat(_currentChatId!, title);
        await _loadChats(); // refrescar listado/títulos
      }

      setState(() {
        if (isInitialLoad) {
          _showCenterLoader = false;
          // ocultar aviso de regla en adelante
          _firstUploadDone = true;
          _pendingStyleNotice = false;
        } else {
          _replaceLoaderWith(_Bubble.assistant(response.isEmpty ? 'No recibí análisis.' : response));
        }
        if (isInitialLoad) {
          _messages.add(_Bubble.assistant(
            response.isEmpty
                ? 'No recibí análisis. Verifica el tamaño del documento o prueba otra versión.'
                : response,
          ));
        }
        _allowQuestions = true;
      });

      await _store.setFirstUploadDone(_currentChatId!);
      await _store.append(_currentChatId!, 'assistant', response);
      _jumpToBottom();
    } catch (e) {
      setState(() {
        _showCenterLoader = false;
        if (!mounted) return;
        _replaceLoaderWith(_Bubble.assistant('Ocurrió un error al analizar tu documento con OpenAI.'));
      });
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _sendQuestion() async {
    final text = _input.text.trim();
    if (text.isEmpty || !_allowQuestions) return;
    if (_currentChatId == null) await _newChat();

    setState(() {
      _messages.add(_Bubble.user(text));
      _input.clear();
      _busy = true;
    });
    await _store.append(_currentChatId!, 'user', text);

    _jumpToBottom();

    try {
      final styleStr = _style == CitationStyle.apa ? 'APA' : _style == CitationStyle.ieee ? 'IEEE' : 'APA';
      final sys = _systemPrompt.replaceAll('{{STYLE}}', styleStr);

      setState(() => _messages.add(_Bubble.loader()));
      _jumpToBottom();

      final history = await _store.readHistory(_currentChatId!, maxItems: 60);
      final response = await _openai.chatComplete(
        systemPrompt: sys,
        userContent: 'Responde breve y preciso sobre el documento previamente analizado: $text',
        history: history,
        temperature: 0.2,
      );

      setState(() => _replaceLoaderWith(_Bubble.assistant(response.isEmpty ? 'No pude responder.' : response)));
      await _store.append(_currentChatId!, 'assistant', response);
      _jumpToBottom();

      // si aún se llamaba "Nuevo chat" y nunca se tituló, titulamos con primer snippet de respuesta
      await _finalizeCurrentChatTitle(force: false, prefer: response);
    } finally {
      setState(() => _busy = false);
    }
  }

  // ========== Helpers de guardado/título ==========
  Future<void> _finalizeCurrentChatTitle({bool force = false, String? prefer}) async {
    if (_currentChatId == null) return;
    final meta = await _store.getMeta(_currentChatId!);
    if (meta == null) return;

    final currentTitle = meta.title.trim();
    if (!force && currentTitle.isNotEmpty && currentTitle != 'Nuevo chat') return;

    String? candidate = prefer;
    if ((candidate == null || candidate.trim().isEmpty)) {
      // buscar último mensaje del asistente en RAM
      for (int i = _messages.length - 1; i >= 0; i--) {
        final b = _messages[i];
        if (!b.fromUser && !b.isLoader && b.text.trim().isNotEmpty) {
          candidate = b.text;
          break;
        }
      }
    }
    if (candidate == null || candidate.trim().isEmpty) return;

    await _store.renameChat(_currentChatId!, _deriveTitleFrom(candidate));
    await _loadChats();
  }

  String _deriveTitleFrom(String text) {
    // primera línea, sin markdown, máx 48 chars
    String t = text.split('\n').first.trim();
    t = t.replaceAll(RegExp(r'[#*_`>\-\•]+'), '').trim();
    if (t.length > 48) t = '${t.substring(0, 48)}…';
    if (t.isEmpty) t = 'Chat';
    return t;
  }

  void _replaceLoaderWith(_Bubble replacement) {
    final i = _messages.lastIndexWhere((b) => b.isLoader);
    if (i != -1) {
      _messages[i] = replacement;
    } else {
      _messages.add(replacement);
    }
  }

  // ========== Scroll helpers ==========
  void _jumpToBottom({bool immediate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final pos = _scroll.position.maxScrollExtent;
      if (immediate) {
        _scroll.jumpTo(pos);
      } else {
        _scroll.animateTo(pos, duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _input.dispose();
    _hatCtrl.dispose();
    super.dispose();
  }

  // ========== UI ==========
  @override
  Widget build(BuildContext context) {
    final theme = _isDark ? buildDarkTheme() : buildLightTheme();
    final onBar = _isDark ? Colors.white : Colors.black;
    final barGlass = _isDark ? const Color(0x1AFFFFFF) : const Color(0xCCFFFFFF);
    final barBorder = _isDark ? AppColors.outline : AppColors.outlineDark;
    final isWide = MediaQuery.of(context).size.width >= 980;

    return Theme(
      data: theme,
      child: Scaffold(
        key: _scaffoldKey, // ✅ para abrir Drawer
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          flexibleSpace: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: barGlass,
                  border: Border(bottom: BorderSide(color: barBorder)),
                ),
              ),
            ),
          ),
          iconTheme: IconThemeData(color: onBar, size: 22),
          actionsIconTheme: IconThemeData(color: onBar, size: 22),
          foregroundColor: onBar,
          titleTextStyle: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700, color: onBar, fontSize: 18,
          ),
          leading: IconButton(
            tooltip: _isDark ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
            onPressed: _busy ? null : () => setState(() => _isDark = !_isDark),
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (c, a) => RotationTransition(turns: a, child: c),
              child: Icon(_isDark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined, key: ValueKey(_isDark)),
            ),
          ),
          title: const Text('TesiXpress — Evaluador de Tesis'),
          actions: [
            // 🔁 HAMBURGUESA en móvil para abrir drawer de chats
            if (!isWide)
              IconButton(
                tooltip: 'Tus chats',
                onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                icon: const Icon(Icons.menu), // 🍔
              ),
            IconButton(
              tooltip: 'Elegir norma (APA/IEEE)',
              onPressed: _busy ? null : _chooseStyle,
              icon: const Icon(Icons.rule),
            ),
            IconButton(
              tooltip: 'Subir documento',
              onPressed: _busy ? null : _pickAndAnalyze,
              icon: const Icon(Icons.upload_file),
            ),
            IconButton(
              tooltip: 'Nuevo chat',
              onPressed: _busy ? null : _newChat,
              icon: const Icon(Icons.add_comment_outlined),
            ),
            IconButton(
              tooltip: 'Cerrar sesión',
              onPressed: _busy ? null : () async {
                await _finalizeCurrentChatTitle();
                await Supa.client.auth.signOut();
              },
              icon: const Icon(Icons.logout),
            ),
            const SizedBox(width: 6),
          ],
        ),

        endDrawer: _ChatListDrawer(
          chats: _chats,
          currentId: _currentChatId,
          onOpen: (id) async {
            Navigator.of(context).maybePop(); // cerrar drawer en móvil
            await _openChat(id);
          },
          onNew: () async {
            Navigator.of(context).maybePop();
            await _newChat();
          },
          onRename: _renameChat,
          onDelete: _deleteChat,
        ),

        body: Row(
          children: [
            if (isWide)
              SizedBox(
                width: 300,
                child: _ChatSidebar(
                  chats: _chats,
                  currentId: _currentChatId,
                  onOpen: _openChat,
                  onNew: _newChat,
                  onRename: _renameChat,
                  onDelete: _deleteChat,
                ),
              ),
            if (isWide) const VerticalDivider(width: 1),
            Expanded(child: _buildChatArea(theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildChatArea(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: _isDark
            ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0C0F14), Color(0xFF141925)])
            : const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.beige, AppColors.white]),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: kToolbarHeight + MediaQuery.of(context).padding.top + 8),
              if (_style == null)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: BannerInfo(text: 'Elige APA (azul) o IEEE (rojo).'),
                ),
              Expanded(
                child: Stack(
                  children: [
                    ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) => MessageBubble(
                        fromUser: _messages[i].fromUser,
                        text: _messages[i].text,
                        accent: _accent,
                        showHatLoader: _messages[i].isLoader,
                      ),
                    ),
                    // Flecha “hay más por leer”
                    Positioned(
                      right: 16,
                      bottom: 92,
                      child: IgnorePointer(
                        ignoring: !_showScrollDown,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 220),
                          opacity: _showScrollDown ? 1 : 0,
                          child: _ScrollDownHint(onTap: _jumpToBottom),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_allowQuestions)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _input,
                            decoration: const InputDecoration(
                              hintText: 'Escribe una pregunta corta y precisa…',
                              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            onSubmitted: (_) => _sendQuestion(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _busy ? null : _sendQuestion,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: _accent.withOpacity(_isDark ? 0.22 : 0.14),
                              border: Border.all(color: _accent.withOpacity(0.55)),
                              boxShadow: [BoxShadow(blurRadius: 18, color: _accent.withOpacity(_isDark ? 0.25 : 0.18))],
                            ),
                            child: const Icon(Icons.send, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const SizedBox(height: 10),
            ],
          ),
          // ✅ Loader centrado SOLO para primera carga
          if (_showCenterLoader)
            IgnorePointer(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: (_isDark ? Colors.black : Colors.white).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _accent.withOpacity(0.55)),
                    boxShadow: [BoxShadow(blurRadius: 20, color: _accent.withOpacity(0.25))],
                  ),
                  child: const _CenteredHatLoader(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ======== Loader centrado ========
class _CenteredHatLoader extends StatefulWidget {
  const _CenteredHatLoader();
  @override
  State<_CenteredHatLoader> createState() => _CenteredHatLoaderState();
}
class _CenteredHatLoaderState extends State<_CenteredHatLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72, width: 180,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final t = _ctrl.value * 2 * math.pi;
          final r = 24.0;
          final color = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 58, width: 58,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: const Icon(Icons.school, size: 32),
              ),
              for (int i = 0; i < 4; i++)
                Positioned(
                  left: 90 + r * math.cos(t + (i * 2 * math.pi / 4)) - 5,
                  top: 36 + r * math.sin(t + (i * 2 * math.pi / 4)) - 5,
                  child: Container(
                    height: 10, width: 10,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [BoxShadow(blurRadius: 14, color: Colors.white)],
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

// ======== Hint "bajar al final" ========
class _ScrollDownHint extends StatefulWidget {
  final VoidCallback onTap;
  const _ScrollDownHint({required this.onTap});

  @override
  State<_ScrollDownHint> createState() => _ScrollDownHintState();
}

class _ScrollDownHintState extends State<_ScrollDownHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
        ..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final t = _ctrl.value;
          final dy = (math.sin(t * math.pi * 2) * 6); // “flotando”
          return Transform.translate(
            offset: Offset(0, dy),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.white, size: 24),
            ),
          );
        },
      ),
    );
  }
}

// ======== Paneles de Chats (sidebar y drawer móvil) ========
class _ChatSidebar extends StatelessWidget {
  final List<ChatMeta> chats;
  final String? currentId;
  final Future<void> Function(String) onOpen;
  final Future<void> Function() onNew;
  final Future<void> Function(ChatMeta) onRename;
  final Future<void> Function(ChatMeta) onDelete;

  const _ChatSidebar({
    required this.chats,
    required this.currentId,
    required this.onOpen,
    required this.onNew,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0x11111111) : const Color(0x0F000000),
      child: Column(
        children: [
          const SizedBox(height: 86),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Nuevo chat'),
            onTap: onNew,
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: chats.length,
              itemBuilder: (_, i) {
                final c = chats[i];
                final selected = c.id == currentId;
                return _ChatTile(
                  meta: c,
                  selected: selected,
                  onOpen: () => onOpen(c.id),
                  onRename: () => onRename(c),
                  onDelete: () => onDelete(c),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatListDrawer extends StatelessWidget {
  final List<ChatMeta> chats;
  final String? currentId;
  final Future<void> Function(String) onOpen;
  final Future<void> Function() onNew;
  final Future<void> Function(ChatMeta) onRename;
  final Future<void> Function(ChatMeta) onDelete;

  const _ChatListDrawer({
    required this.chats,
    required this.currentId,
    required this.onOpen,
    required this.onNew,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Nuevo chat'),
              onTap: onNew,
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: chats.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final c = chats[i];
                  return _ChatTile(
                    meta: c,
                    selected: c.id == currentId,
                    onOpen: () => onOpen(c.id),
                    onRename: () => onRename(c),
                    onDelete: () => onDelete(c),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final ChatMeta meta;
  final bool selected;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _ChatTile({
    required this.meta,
    required this.selected,
    required this.onOpen,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final styleBadge = meta.style == 'APA'
        ? Container(height: 8, width: 8, decoration: const BoxDecoration(color: kAPA, shape: BoxShape.circle))
        : meta.style == 'IEEE'
            ? Container(height: 8, width: 8, decoration: const BoxDecoration(color: kIEEE, shape: BoxShape.circle))
            : const SizedBox(height: 8, width: 8);

    return ListTile(
      selected: selected,
      selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.08),
      leading: styleBadge,
      title: Text(meta.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('Actualizado: ${meta.updatedAt.toLocal()}', style: const TextStyle(fontSize: 11)),
      onTap: onOpen,
      trailing: PopupMenuButton<String>(
        itemBuilder: (ctx) => const [
          PopupMenuItem(value: 'rename', child: Text('Renombrar')),
          PopupMenuItem(value: 'delete', child: Text('Eliminar')),
        ],
        onSelected: (v) {
          if (v == 'rename') onRename();
          if (v == 'delete') onDelete();
        },
      ),
    );
  }
}
