import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_demo/chat/chat_constants.dart';
import 'package:flutter_gemma_demo/chat/chat_models.dart';
import 'package:flutter_gemma_demo/chat/tool_handler.dart';
import 'package:flutter_gemma_demo/chat/widgets/agent_steps_panel.dart';
import 'package:flutter_gemma_demo/chat/widgets/chat_bubble.dart';
import 'package:flutter_gemma_demo/chat/widgets/welcome_state.dart';
import 'package:flutter_gemma_demo/core/services/contact_service.dart';
import 'package:flutter_gemma_demo/core/services/device_info_service.dart';
import 'package:flutter_gemma_demo/core/services/play_store_search_service.dart';
import 'package:flutter_gemma_demo/core/services/sms_service.dart';
import 'package:flutter_gemma_demo/core/services/uninstall_app_service.dart';
import 'package:flutter_gemma_demo/core/services/whatsapp_service.dart';
import 'package:flutter_gemma_demo/ui/app_background.dart';
import 'package:flutter_gemma_demo/ui/app_theme.dart';
import 'package:flutter_gemma_demo/ui/app_widgets.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  InferenceChat? _chat;
  InferenceModel? _model;
  late final ToolHandler _toolHandler;

  final List<ChatMessage> _messages = [];
  final List<AgentStep> _steps = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isInitializing = true;
  bool _isGenerating = false;
  int _generationId = 0;
  String? _initError;
  String _streamingText = '';
  Future<void>? _pendingReset;

  @override
  void initState() {
    super.initState();
    final contactService = ContactService();
    _toolHandler = ToolHandler(
      smsService: SmsService(contactService: contactService),
      whatsappService: WhatsAppService(contactService: contactService),
      playStoreService: PlayStoreSearchService(),
      uninstallAppService: UninstallAppService(),
      deviceInfoService: const DeviceInfoService(),
    );
    _initChat();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _chat?.close();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  Future<void> _initChat() async {
    try {
      await _requestContactPermission();

      _model = await FlutterGemma.getActiveModel(
        maxTokens: 8000,
        preferredBackend: PreferredBackend.gpu,
      );

      _chat = await _model!.createChat(
        tools: chatTools,
        supportsFunctionCalls: true,
        toolChoice: ToolChoice.auto,
        modelType: ModelType.gemma4,
        systemInstruction: chatSystemInstruction,
      );

      if (!mounted) return;
      setState(() => _isInitializing = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initError = e.toString();
        _isInitializing = false;
      });
    }
  }

  Future<void> _requestContactPermission() async {
    final status = await Permission.contacts.status;
    if (status.isGranted) return;
    await Permission.contacts.request();
  }

  // ---------------------------------------------------------------------------
  // Generation control
  // ---------------------------------------------------------------------------

  Future<void> _stopGeneration() async {
    if (!_isGenerating) return;
    _generationId++;

    if (mounted) {
      setState(() {
        if (_streamingText.isNotEmpty) {
          _messages.add(ChatMessage(text: _streamingText, isUser: false));
        }
        _streamingText = '';
        _isGenerating = false;
      });
    }

    _pendingReset = _resetSession();
  }

  Future<void> _resetSession() async {
    try { await _chat?.session.stopGeneration(); } catch (_) {}
    try { await _chat?.clearHistory(); } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isGenerating || _chat == null) return;

    if (_pendingReset != null) {
      await _pendingReset;
      _pendingReset = null;
    }

    _inputController.clear();
    final myGen = ++_generationId;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isGenerating = true;
      _streamingText = '';
      _steps.clear();
    });
    _scrollToBottom();

    try {
      await _chat!.addQueryChunk(Message(text: text, isUser: true));

      final stream = _chat!.generateChatResponseWithTools(
        onToolCall: (call) async {
          if (_generationId != myGen) return {'status': 'cancelled'};
          return _toolHandler.handle(
            call,
            onStep: (step) {
              if (mounted) setState(() => _steps.add(step));
            },
          );
        },
        maxToolTurns: 8,
        isCancelled: () => _generationId != myGen,
      );

      await for (final response in stream) {
        if (!mounted) break;
        if (_generationId != myGen) break;
        if (response is TextResponse && response.token.isNotEmpty) {
          setState(() => _streamingText += response.token);
        }
      }

      if (mounted && _isGenerating && _generationId == myGen) {
        setState(() {
          if (_streamingText.isNotEmpty) {
            _messages.add(ChatMessage(text: _streamingText, isUser: false));
          }
          _streamingText = '';
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (!mounted || _generationId != myGen) return;
      setState(() {
        if (_streamingText.isNotEmpty) {
          _messages.add(ChatMessage(text: _streamingText, isUser: false));
        }
        _messages.add(ChatMessage(
          text: 'Error: $e',
          isUser: false,
          isError: true,
        ));
        _streamingText = '';
        _isGenerating = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) return _InitializingView();
    if (_initError != null) return _ErrorView(error: _initError!);

    return Scaffold(
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(child: _buildMessageList()),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.borderLight, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            const Text(
              'Gemma AI',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty && !_isGenerating) return const WelcomeState();

    final stepsVisible = _steps.isNotEmpty;
    final itemCount =
        _messages.length + (stepsVisible ? 1 : 0) + (_isGenerating ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        final stepIdx = _messages.length;
        final streamIdx = stepIdx + (stepsVisible ? 1 : 0);

        if (index == stepIdx && stepsVisible) {
          return AgentStepsPanel(steps: _steps);
        }
        if (index == streamIdx && _isGenerating) {
          return ChatBubble(
            text: _streamingText,
            isUser: false,
            isStreaming: true,
          );
        }
        final m = _messages[index];
        return ChatBubble(text: m.text, isUser: m.isUser, isError: m.isError);
      },
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.borderLight, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                minLines: 1,
                maxLines: 5,
                style: AppText.body
                    .copyWith(color: AppColors.textPrimary, fontSize: 16),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Message Gemma AI...',
                  hintStyle: AppText.body
                      .copyWith(color: AppColors.textHint, fontSize: 16),
                  filled: true,
                  fillColor: AppColors.bgSoft,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _isGenerating ? _stopGeneration : _sendMessage,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isGenerating ? AppColors.red : AppColors.primary,
                ),
                child: Icon(
                  _isGenerating ? Icons.stop : Icons.arrow_upward,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Full-screen helper views (private to this file)
// ---------------------------------------------------------------------------

class _InitializingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const LoadingIndicator(size: 200),
                  const SizedBox(height: 24),
                  Text(
                    'Initializing AI...',
                    style: AppText.heading.copyWith(
                      fontSize: 24,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: GlassCard(
                  accentColor: AppColors.red,
                  borderRadius: 20,
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.red.withValues(alpha: 0.08),
                            border: Border.all(
                              color: AppColors.red.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.error_outline,
                            size: 32,
                            color: AppColors.red,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to initialize',
                          style: AppText.heading
                              .copyWith(fontSize: 18, color: AppColors.red),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error,
                          textAlign: TextAlign.center,
                          style: AppText.body.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
