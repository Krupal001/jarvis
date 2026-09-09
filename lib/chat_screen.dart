import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_agent/flutter_gemma_agent.dart';
import 'package:flutter_gemma_demo/agent/agent_service.dart';
import 'package:flutter_gemma_demo/core/services/contact_service.dart';
import 'package:flutter_gemma_demo/core/services/sms_service.dart';
import 'package:flutter_gemma_demo/core/services/whatsapp_service.dart';
import 'package:flutter_gemma_demo/ui/neon_background.dart';
import 'package:flutter_gemma_demo/ui/neon_theme.dart';
import 'package:flutter_gemma_demo/ui/neon_widgets.dart';
import 'package:permission_handler/permission_handler.dart';

/// A chat screen backed by the flutter_gemma_agent [AgentSession].
///
/// The model discovers the `send-sms` skill from the system prompt, calls
/// `loadSkill` to read its instructions, then calls `runIntent` with the
/// extracted contact name + message. The [SmsSkillExecutor] resolves the
/// contact's phone number via [ContactService] and opens the OS SMS composer.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  AgentService? _agentService;
  AgentSession? _session;

  final List<_ChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isInitializing = true;
  bool _isGenerating = false;
  bool _isCancelled = false;
  String? _initError;

  // The streaming response being built up token-by-token.
  String _streamingText = '';

  // Agent step log (skill loads, tool calls, results) shown in a collapsible
  // panel above the streaming reply.
  final List<_AgentStep> _steps = [];

  late final ContactService _contactService;
  late final SmsService _smsService;
  late final WhatsAppService _whatsappService;

  @override
  void initState() {
    super.initState();
    _contactService = ContactService();
    _smsService = SmsService(contactService: _contactService);
    _whatsappService = WhatsAppService(contactService: _contactService);
    _agentService = AgentService(
      smsService: _smsService,
      whatsappService: _whatsappService,
    );
    _initSession();
    
  }

 

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _session?.close();
    super.dispose();
  }

  Future<void> _initSession() async {
    try {
      // Request contact permission up-front so ContactService can resolve
      // names when the model triggers send-sms.
      await _requestContactPermission();

      final model = await FlutterGemma.getActiveModel(
        maxTokens: 4096,
        preferredBackend: PreferredBackend.gpu,
      );

      final session = await _agentService!.createSession(model);

      if (!mounted) return;
      setState(() {
        _session = session;
        _isInitializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _initError = e.toString();
        _isInitializing = false;
      });
    }
  }

  Future<void> _stopGeneration() async {
  if (!_isGenerating) return;

  _isCancelled = true;

  try {
    await _session?.chat.session?.stopGeneration();
  } catch (_) {
    // Generation may already have finished.
  }

  if (!mounted) return;

  setState(() {
    _isGenerating = false;

    if (_streamingText.isNotEmpty) {
      _messages.add(
        _ChatMessage(
          text: _streamingText,
          isUser: false,
        ),
      );
    }

    _streamingText = '';
  });
}

  Future<void> _requestContactPermission() async {
    final status = await Permission.contacts.status;
    if (status.isGranted) return;
    await Permission.contacts.request();
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isGenerating || _session == null) return;

    _inputController.clear();

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isGenerating = true;
      _isCancelled = false;
      _streamingText = '';
      _steps.clear();
    });
    _scrollToBottom();

    try {
      final eventStream = _session!.ask(text,
        isCancelled: () => _isCancelled,
      );
      await for (final event in eventStream) {
        if (!mounted) return;
        switch (event) {
          case SkillLoadEvent(:final skillName, :final found):
            setState(() {
              _steps.add(_AgentStep(
                'Loading skill "$skillName"...',
                isError: !found,
              ));
            });
          case ToolCallEvent(:final toolName, :final args):
            setState(() {
              _steps.add(_AgentStep(
                'Calling $toolName(${_formatArgs(args)})',
              ));
            });
          case ToolResultEvent(:final result):
            final summary = switch (result) {
              TextResult(:final text) => text,
              ErrorResult(:final message) => 'Error: $message',
              _ => result.toString(),
            };
            setState(() {
              _steps.add(_AgentStep('Result: $summary'));
            });
          case TextChunkEvent(:final text):
            setState(() => _streamingText += text);
            _scrollToBottom();
          case DoneEvent(:final text):
            setState(() {
              if (text.isNotEmpty) {
                _messages.add(_ChatMessage(text: text, isUser: false));
              } else if (_streamingText.isNotEmpty) {
                _messages.add(_ChatMessage(text: _streamingText, isUser: false));
              }
              _streamingText = '';
              _isGenerating = false;
            });
          case MaxIterationsEvent(:final iterations):
            setState(() {
              _messages.add(_ChatMessage(
                text: 'Reached the maximum number of steps ($iterations).',
                isUser: false,
                isError: true,
              ));
              _isGenerating = false;
            });
          case AgentErrorEvent(:final message):
            setState(() {
              _steps.add(_AgentStep('Error: $message', isError: true));
            });
      }
      }

      // If the stream ended without a DoneEvent (e.g. cancelled), flush.
      if (mounted && _isGenerating) {
        setState(() {
          if (_streamingText.isNotEmpty) {
            _messages.add(_ChatMessage(text: _streamingText, isUser: false));
          }
          _streamingText = '';
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_streamingText.isNotEmpty) {
          _messages.add(_ChatMessage(text: _streamingText, isUser: false));
        }
        _messages.add(_ChatMessage(
          text: 'Error: $e',
          isUser: false,
          isError: true,
        ));
        _streamingText = '';
        _isGenerating = false;
      });
    }
  }

  String _formatArgs(Map<String, dynamic> args) {
    return args.entries.map((e) => '${e.key}: ${e.value}').join(', ');
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

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        body: Stack(
          children: [
            const NeonBackground(),
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const NeonPulseRing(size: 80),
                    const SizedBox(height: 24),
                    NeonShimmerText(
                      'Initializing AI...',
                      style: NeonText.heading.copyWith(fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_initError != null) {
      return Scaffold(
        body: Stack(
          children: [
            const NeonBackground(),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: NeonGlassCard(
                    glowColor: Colors.red,
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
                              color: Colors.red.withValues(alpha: 0.1),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(Icons.error_outline,
                                size: 32, color: Colors.redAccent),
                          ),
                          const SizedBox(height: 16),
                          NeonGlowText(
                            'Failed to initialize',
                            style: NeonText.heading.copyWith(
                              fontSize: 18,
                              color: Colors.redAccent,
                            ),
                            glowColor: Colors.red,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _initError!,
                            textAlign: TextAlign.center,
                            style: NeonText.body
                                .copyWith(color: Colors.white54, fontSize: 14),
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

    return Scaffold(
      body: Stack(
        children: [
          const NeonBackground(),
          Column(
            children: [
              _buildNeonAppBar(),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  itemCount: _messages.length +
                      (_isGenerating ? 1 : 0) +
                      (_steps.isNotEmpty && _isGenerating ? 1 : 0),
                  itemBuilder: (context, index) {
                    final stepPanelIndex = _messages.length;
                    final streamingIndex = stepPanelIndex +
                        (_steps.isNotEmpty && _isGenerating ? 1 : 0);

                    if (index == stepPanelIndex &&
                        _steps.isNotEmpty &&
                        _isGenerating) {
                      return _AgentStepsPanel(steps: _steps);
                    }
                    if (index == streamingIndex && _isGenerating) {
                      return _ChatBubble(
                        text: _streamingText,
                        isUser: false,
                        isStreaming: true,
                      );
                    }
                    final m = _messages[index];
                    return _ChatBubble(
                      text: m.text,
                      isUser: m.isUser,
                      isError: m.isError,
                    );
                  },
                ),
              ),
              _buildInputBar(),
            ],
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildNeonAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 10),
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: NeonColors.cyan.withValues(alpha: 0.2),
                width: 0.8,
              ),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                NeonColors.bgDark.withValues(alpha: 0.8),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: NeonColors.primaryGradient,
                  boxShadow: NeonGlow.multi(blur: 8),
                ),
                child: const Icon(Icons.auto_awesome,
                    size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NeonGlowText(
                      'Gemma AI',
                      style: NeonText.headingBold.copyWith(
                        fontSize: 18,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                      glowColor: NeonColors.cyan,
                      glowRadius: 4,
                    ),
                    Text(
                      'SMS · WhatsApp · Install',
                      style: NeonText.mono.copyWith(
                        fontSize: 10,
                        color: NeonColors.purple.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: NeonColors.green.withValues(alpha: 0.1),
                  border: Border.all(
                    color: NeonColors.green.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: NeonColors.green,
                        boxShadow: NeonGlow.soft(NeonColors.green, blur: 4, opacity: 0.1),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ONLINE',
                      style: NeonText.mono.copyWith(
                        fontSize: 10,
                        color: NeonColors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: _isGenerating
                      ? NeonGlow.pink(blur: 6)
                      : NeonGlow.cyan(blur: 4),
                ),
                child: TextField(
                  controller: _inputController,
                  minLines: 1,
                  maxLines: 5,
                  style: NeonText.body.copyWith(color: Colors.white, fontSize: 15),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'e.g. "Send an SMS to John saying Hello"',
                    hintStyle:
                        NeonText.body.copyWith(color: Colors.white30, fontSize: 14),
                    filled: true,
                    fillColor: NeonColors.bgCard.withValues(alpha: 0.8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: (_isGenerating ? NeonColors.pink : NeonColors.cyan)
                            .withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: (_isGenerating ? NeonColors.pink : NeonColors.cyan)
                            .withValues(alpha: 0.5),
                        width: 1.2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: NeonColors.purple.withValues(alpha: 0.25),
                        width: 0.8,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _isGenerating ? _stopGeneration : _sendMessage,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _isGenerating
                      ? LinearGradient(
                          colors: [Colors.red.shade700, Colors.red.shade400],
                        )
                      : NeonColors.primaryGradient,
                  boxShadow: _isGenerating
                      ? [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.2),
                            blurRadius: 8,
                          ),
                        ]
                      : NeonGlow.multi(blur: 8),
                ),
                child: Icon(
                  _isGenerating ? Icons.stop : Icons.send,
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

// --- data classes ----------------------------------------------------------

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
  });

  final String text;
  final bool isUser;
  final bool isError;
}

class _AgentStep {
  const _AgentStep(this.text, {this.isError = false});
  final String text;
  final bool isError;
}

// --- widgets ---------------------------------------------------------------

class _AgentStepsPanel extends StatelessWidget {
  const _AgentStepsPanel({required this.steps});

  final List<_AgentStep> steps;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: NeonColors.bgCard.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: NeonColors.purple.withValues(alpha: 0.25),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: NeonColors.purple.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: NeonColors.cyan.withValues(alpha: 0.15),
                  border: Border.all(
                    color: NeonColors.cyan.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: Icon(Icons.auto_awesome,
                    size: 12, color: NeonColors.cyan),
              ),
              const SizedBox(width: 8),
              Text('Agent Steps',
                  style: NeonText.mono.copyWith(
                    fontSize: 11,
                    color: NeonColors.cyan.withValues(alpha: 0.8),
                    letterSpacing: 1,
                  )),
            ],
          ),
          const SizedBox(height: 8),
          for (final s in steps)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: s.isError ? Colors.redAccent : NeonColors.pink,
                      boxShadow: [
                        BoxShadow(
                          color: (s.isError ? Colors.redAccent : NeonColors.pink)
                              .withValues(alpha: 0.2),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.text,
                      style: NeonText.body.copyWith(
                        fontSize: 12,
                        color: s.isError
                            ? Colors.redAccent
                            : Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.text,
    required this.isUser,
    this.isError = false,
    this.isStreaming = false,
  });

  final String text;
  final bool isUser;
  final bool isError;
  final bool isStreaming;

  @override
  Widget build(BuildContext context) {
    final accentColor = isError
        ? Colors.red
        : isUser
            ? NeonColors.cyan
            : NeonColors.purple;

    final bg = isError
        ? Colors.red.withValues(alpha: 0.08)
        : isUser
            ? NeonColors.cyan.withValues(alpha: 0.08)
            : NeonColors.bgCard.withValues(alpha: 0.6);

    final fg = isError
        ? Colors.redAccent
        : isUser
            ? Colors.white.withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.85);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isUser
                ? const Radius.circular(18)
                : const Radius.circular(4),
            bottomRight: isUser
                ? const Radius.circular(4)
                : const Radius.circular(18),
          ),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.15),
            width: 0.6,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.05),
              blurRadius: 6,
            ),
          ],
        ),
        child: text.isEmpty && isStreaming
            ? const TypingDots()
            : SelectableText(
                text,
                style: NeonText.body.copyWith(color: fg, fontSize: 15, height: 1.4),
              ),
      ),
    );
  }
}

/// Three pulsing neon dots shown while the model is "thinking" before the
/// first token arrives.
class TypingDots extends StatefulWidget {
  const TypingDots({super.key});

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots> with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = [NeonColors.cyan, NeonColors.purple, NeonColors.pink];
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (_controller.value * 3 - i).clamp(0.0, 1.0);
            final scale = 0.5 + 0.5 * (1 - (2 * t - 1).abs());
            final color = colors[i];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
