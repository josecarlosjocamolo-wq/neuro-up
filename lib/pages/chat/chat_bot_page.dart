import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/ai_service.dart';
import '../../services/stats_service.dart';
import 'models/chat_service.dart';

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ChatService _chatService = ChatService();
  bool _isLoading = false;
  bool _aiEnabled = false;
  final ScrollController _scrollController = ScrollController();

  final List<String> _quickReplies = [
    "Necesito organizarme",
    "Ayúdame a enfocarme",
    "Estoy frustrado",
    "Ver mis resultados",
  ];

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    setState(() => _isLoading = true);
    try {
      _aiEnabled = await AiService.isConfigured();
      final history = await _chatService.getMessages();
      if (history.isEmpty) {
        await _checkProactiveGreeting();
      } else {
        if (!mounted) return;
        setState(() {
          _messages.addAll(history.map((m) => ChatMessage(
                text: m.text,
                isUser: m.isUser,
                timestamp: m.timestamp,
              )));
        });
        _scrollToBottom();
      }
    } catch (_) {
      await _checkProactiveGreeting();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkProactiveGreeting() async {
    String greeting;
    try {
      final stats = await StatsService.getQuickStats();
      final xpData = await StatsService.getXPAndLevel();

      final int tasks = stats['tasksCompleted'] ?? 0;
      final int tests = stats['testsCompleted'] ?? 0;
      final int level = xpData['level'] ?? 1;

      greeting = "¡Hola! Soy UPI, tu asistente personal 🎓\n\n";
      if (tasks > 0 || tests > 0) {
        greeting += "📊 He revisado tu progreso:\n";
        if (tasks > 0) greeting += "• Has completado $tasks tareas. ¡Vas excelente! 💪\n";
        if (tests > 0) greeting += "• Llevas $tests tests realizados.\n";
        greeting += "\nActualmente eres **Nivel $level**.\n\n";
      } else {
        greeting += "¡Hoy es un gran día para empezar! ✨\n\n"
            "Veo que aún no has realizado actividades. ¿Te gustaría intentar un Pomodoro o un Test corto para calentar motores? 🧠\n\n";
      }
      greeting += "¿En qué puedo ayudarte ahora? 😊";
    } catch (_) {
      greeting = "¡Hola! Soy UPI, tu asistente. ¿En qué puedo ayudarte hoy? 😊";
    }
    await _chatService.saveBotMessage(greeting);
    if (!mounted) return;
    _addMessage(greeting, isUser: false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _addMessage(String text, {bool isUser = false}) {
    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: isUser,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _handleSubmitted(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return;
    _textController.clear();
    _addMessage(clean, isUser: true);
    _chatService.saveUserMessage(clean);
    setState(() => _isLoading = true);
    _processUserMessage(clean);
  }

  Future<void> _processUserMessage(String prompt) async {
    String response;
    try {
      response = await _chatService.getBotResponse(prompt);
    } catch (_) {
      response = 'Lo siento, tuve un problema para responder. ¿Puedes repetirlo?';
    }
    await _chatService.saveBotMessage(response);
    if (!mounted) return;
    _addMessage(response, isUser: false);
    setState(() => _isLoading = false);
  }

  Future<void> _openAiSettings() async {
    final configured = await AiService.isConfigured();
    final savedUrl = await AiService.currentBaseUrl();
    final savedModel = await AiService.currentModel();
    if (!mounted) return;

    final keyCtrl = TextEditingController();
    final urlCtrl = TextEditingController(text: savedUrl);
    final modelCtrl = TextEditingController(text: savedModel);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6)),
          SizedBox(width: 8),
          Text('Asistente con IA'),
        ]),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: (configured ? const Color(0xFF10B981) : const Color(0xFF64748B))
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      configured ? Icons.check_circle_rounded : Icons.public_off_rounded,
                      size: 16,
                      color: configured ? const Color(0xFF10B981) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      configured ? 'IA activa' : 'Modo local (sin conexión)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: configured ? const Color(0xFF10B981) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                configured
                    ? 'La IA está activada. Puedes actualizar la clave o el modelo.'
                    : 'Conecta un modelo de IA (compatible con OpenAI) para respuestas '
                        'inteligentes. La clave se guarda solo en tu dispositivo.',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: keyCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  hintText: 'sk-...',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'Base URL',
                  hintText: AiService.defaultBaseUrl,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: modelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Modelo',
                  hintText: AiService.defaultModel,
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (configured)
            TextButton(
              onPressed: () async {
                await AiService.clear();
                if (ctx.mounted) Navigator.pop(ctx);
                if (!mounted) return;
                setState(() => _aiEnabled = false);
                _snack('IA desactivada. UPI usará el modo local.');
              },
              child: const Text('Desactivar', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final key = keyCtrl.text.trim();
              if (key.isEmpty) {
                _snack('Ingresa una API Key válida.');
                return;
              }
              await AiService.configure(
                apiKey: key,
                baseUrl: urlCtrl.text,
                model: modelCtrl.text,
              );
              if (ctx.mounted) Navigator.pop(ctx);
              if (!mounted) return;
              setState(() => _aiEnabled = true);
              _snack('¡IA activada! UPI ahora es más inteligente ✨');
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFF8B5CF6)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final bg       = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg   = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBdr  = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMain = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSub  = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    const primary  = Color(0xFF8B5CF6);
    
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: 'Configurar IA',
            icon: const Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6)),
            onPressed: _openAiSettings,
          ),
        ],
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cardBdr),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/gifs/upichat.gif',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: primary.withValues(alpha: 0.2),
                    child: Icon(Icons.smart_toy_rounded, color: primary, size: 20),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Habla con UPI', style: TextStyle(color: textMain, fontSize: 16, fontWeight: FontWeight.w800)),
                Text(
                  _isLoading
                      ? 'Escribiendo...'
                      : (_aiEnabled ? 'IA activa' : 'Modo local'),
                  style: TextStyle(
                    color: _isLoading
                        ? primary
                        : (_aiEnabled ? const Color(0xFF10B981) : textSub),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat area
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg.isUser;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!isUser) ...[
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primary.withValues(alpha: 0.1),
                              border: Border.all(color: primary.withValues(alpha: 0.3)),
                            ),
                            child: Icon(Icons.smart_toy_rounded, size: 16, color: primary),
                          ),
                          const SizedBox(width: 8),
                        ],
                        
                        Flexible(
                          child: Container(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            decoration: BoxDecoration(
                              color: isUser ? primary : cardBg,
                              border: isUser ? null : Border.all(color: cardBdr),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(20),
                                topRight: const Radius.circular(20),
                                bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
                                bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                              ),
                              boxShadow: isUser ? [
                                BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))
                              ] : [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))
                              ],
                            ),
                            child: Text(
                              msg.text,
                              style: TextStyle(
                                color: isUser ? Colors.white : textMain,
                                fontSize: 15,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ).animate().scale(begin: const Offset(0.95, 0.95), duration: 200.ms, curve: Curves.easeOutBack),
                        ),
                        
                        if (isUser) const SizedBox(width: 8),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Quick Replies
            if (!_isLoading)
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _quickReplies.length,
                  itemBuilder: (context, i) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _handleSubmitted(_quickReplies[i]),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: cardBg,
                            border: Border.all(color: primary.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _quickReplies[i],
                            style: TextStyle(color: primary, fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: Duration(milliseconds: 100 * i)).slideX(begin: 0.1);
                  },
                ),
              ),
            
            const SizedBox(height: 12),
            
            // Input field
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: BoxDecoration(
                color: bg,
                border: Border(top: BorderSide(color: cardBdr)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: cardBdr),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              style: TextStyle(color: textMain, fontSize: 15),
                              decoration: InputDecoration(
                                hintText: 'Escribe a UPI...',
                                hintStyle: TextStyle(color: textSub),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onSubmitted: _handleSubmitted,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _handleSubmitted(_textController.text),
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}