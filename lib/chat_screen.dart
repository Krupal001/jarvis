import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_agent/flutter_gemma_agent.dart';
import 'package:flutter_gemma_demo/agent/agent_service.dart';
import 'package:flutter_gemma_demo/core/services/contact_service.dart';
import 'package:flutter_gemma_demo/core/services/sms_service.dart';
import 'package:flutter_gemma_demo/core/services/whatsapp_service.dart';
import 'package:flutter_gemma_demo/ui/app_background.dart';
import 'package:flutter_gemma_demo/ui/app_theme.dart';
import 'package:flutter_gemma_demo/ui/app_widgets.dart';
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

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  AgentService? _agentService;
  AgentSession? _session;
  InferenceModel? _model;
  

  final List<_ChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isInitializing = true;
  bool _isGenerating = false;
  bool _isCancelled = false;
  int _generationId = 0;
  String? _initError;
  Timer? _backgroundTimer;

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
// void didChangeAppLifecycleState(AppLifecycleState state) {
//   if (state == AppLifecycleState.paused) {
//     _backgroundTimer?.cancel();

//     _backgroundTimer = Timer(
//       const Duration(minutes: 2),
//       () async { 
//         await _releaseModel();
//       },
//     );
//   }

//   if (state == AppLifecycleState.resumed) {
//     _backgroundTimer?.cancel();
//     _backgroundTimer = null;

//     if (_model == null) {
//       _initSession();
//     }
//   }
// }

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

      _model = await FlutterGemma.getActiveModel(
        maxTokens: 8000,
        preferredBackend: PreferredBackend.gpu,
      );

      final session = await _agentService!.createSession(_model!);

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
//   Future<void> _releaseModel() async {
//   final model = _model;

//   if (model == null) return;

//   try {
//     await model.close();

//     _model = null;
//     _session = null;

//     debugPrint('Gemma model closed');
//   } catch (e) {
//     debugPrint('Error closing Gemma model: $e');
//   }
// }

//   Future<void> _stopGeneration() async {
//   if (!_isGenerating) return;

//   _isCancelled = true;
//   _generationId++;

//   try {
//     await _session?.chat.session.stopGeneration();
//   } catch (_) {
//     // Generation may already have finished.
//     debugPrint('Generation may already have finished');
//   }

//   if (!mounted) return;

//   setState(() {
//     if (_streamingText.isNotEmpty) {
//       _messages.add(
//         _ChatMessage(
//           text: _streamingText,
//           isUser: false,
//         ),
//       );
//     }
//     _streamingText = '';
//     _isGenerating = false;
//   });
// }

StreamSubscription? _eventSubscription;

Future<void> _stopGeneration() async {
  if (!_isGenerating) return;
  _isCancelled = true;
  _generationId++;

  await _eventSubscription?.cancel();
  _eventSubscription = null;

  try {
    await _session?.chat.session.stopGeneration();
  } catch (_) {}

  // The native FFI session's cancel flag doesn't reset — force a fresh session.
  try {
    await _session?.close();
  } catch (_) {}
  if (_model != null) {
    _session = await _agentService!.createSession(_model!);
  }

  if (!mounted) return;
  setState(() {
    if (_streamingText.isNotEmpty) {
      _messages.add(_ChatMessage(text: _streamingText, isUser: false));
    }
    _streamingText = '';
    _isGenerating = false;
  });
}

  Future<void> _requestContactPermission() async {
    final status = await Permission.contacts.status;
    if (status.isGranted) return;
    await Permission.contacts.request();
  }

  // Future<void> _sendMessage() async {
  //   final text = _inputController.text.trim();
  //   if (text.isEmpty || _isGenerating || _session == null) return;

  //   _inputController.clear();

  //   final myGen = ++_generationId;
  //   setState(() {
  //     _messages.add(_ChatMessage(text: text, isUser: true));
  //     _isGenerating = true;
  //     _isCancelled = false;
  //     _streamingText = '';
  //     _steps.clear();
  //   });
  //   _scrollToBottom();
  //   try {
  //     final eventStream = _session!.ask(text,
  //       isCancelled: () => _isCancelled,
  //     );
  //     await for (final event in eventStream) {
  //       if (!mounted || _generationId != myGen) return;
  //       switch (event) {
  //         case SkillLoadEvent(:final skillName, :final found):
  //           setState(() {
  //             _steps.add(_AgentStep(
  //               'Loading skill "$skillName"...',
  //               isError: !found,
  //             ));
  //           });
  //         case ToolCallEvent(:final toolName, :final args):
  //           setState(() {
  //             _steps.add(_AgentStep(
  //               'Calling $toolName(${_formatArgs(args)})',
  //             ));
  //           });
  //         case ToolResultEvent(:final result):
  //           final summary = switch (result) {
  //             TextResult(:final text) => text,
  //             ErrorResult(:final message) => 'Error: $message',
  //             _ => result.toString(),
  //           };
  //           setState(() {
  //             _steps.add(_AgentStep('Result: $summary'));
  //           });
  //         case TextChunkEvent(:final text):
  //           setState(() => _streamingText += text);
  //          // _scrollToBottom();
  //         case DoneEvent(:final text):
  //           setState(() {
  //             if (text.isNotEmpty) {
  //               _messages.add(_ChatMessage(text: text, isUser: false));
  //             } else if (_streamingText.isNotEmpty) {
  //               _messages.add(_ChatMessage(text: _streamingText, isUser: false));
  //             }
  //             _streamingText = '';
  //             _isGenerating = false;
  //           });
  //         case MaxIterationsEvent(:final iterations):
  //           setState(() {
  //             _messages.add(_ChatMessage(
  //               text: 'Reached the maximum number of steps ($iterations).',
  //               isUser: false,
  //               isError: true,
  //             ));
  //             _isGenerating = false;
  //           });
  //         case AgentErrorEvent(:final message):
  //           setState(() {
  //             _steps.add(_AgentStep('Error: $message', isError: true));
  //           });
  //     }
  //     }

  //     // If the stream ended without a DoneEvent (e.g. cancelled), flush.
  //     if (mounted && _isGenerating && _generationId == myGen) {
  //       setState(() {
  //         if (_streamingText.isNotEmpty) {
  //           _messages.add(_ChatMessage(text: _streamingText, isUser: false));
  //         }
  //         _streamingText = '';
  //         _isGenerating = false;
  //       });
  //     }
  //   } catch (e) {
  //     if (!mounted || _generationId != myGen) return;
  //     setState(() {
  //       if (_streamingText.isNotEmpty) {
  //         _messages.add(_ChatMessage(text: _streamingText, isUser: false));
  //       }
  //       _messages.add(_ChatMessage(
  //         text: 'Error: $e',
  //         isUser: false,
  //         isError: true,
  //       ));
  //       _streamingText = '';
  //       _isGenerating = false;
  //     });
  //   }
  // }

  Future<void> _sendMessage() async {
  final text = _inputController.text.trim();
  if (text.isEmpty || _isGenerating || _session == null) return;

  _inputController.clear();
  final myGen = ++_generationId;

  setState(() {
    _messages.add(_ChatMessage(text: text, isUser: true));
    _isGenerating = true;
    _isCancelled = false;
    _streamingText = '';
    _steps.clear();
  });
  _scrollToBottom();


void _handleEvent(AgentEvent event) {
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
    case DoneEvent(:final text):
  debugPrint('=== DoneEvent text="$text" | _streamingText="$_streamingText" ===');
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
  final completer = Completer<void>();
  final eventStream = _session!.ask(text, isCancelled: () => _isCancelled);

  _eventSubscription = eventStream.listen(
    (event) {
      if (!mounted || _generationId != myGen) return;
      _handleEvent(event); // move your switch-case into a helper
    },
    onError: (e) {
      if (mounted && _generationId == myGen) {
        setState(() {
          _messages.add(_ChatMessage(text: 'Error: $e', isUser: false, isError: true));
          _isGenerating = false;
        });
      }
      if (!completer.isCompleted) completer.complete();
    },
    onDone: () {
      if (mounted && _isGenerating && _generationId == myGen) {
        setState(() {
          if (_streamingText.isNotEmpty) {
            _messages.add(_ChatMessage(text: _streamingText, isUser: false));
          }
          _streamingText = '';
          _isGenerating = false;
        });
      }
      if (!completer.isCompleted) completer.complete();
    },
    cancelOnError: true,
  );

  await completer.future;
  _eventSubscription = null;
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
                      style: AppText.heading.copyWith(fontSize: 24, color: AppColors.textSecondary),
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
                            child: const Icon(Icons.error_outline,
                                size: 32, color: AppColors.red),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to initialize',
                            style: AppText.heading.copyWith(
                              fontSize: 18,
                              color: AppColors.red,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _initError!,
                            textAlign: TextAlign.center,
                            style: AppText.body
                                .copyWith(color: AppColors.textSecondary, fontSize: 14),
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
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: _messages.isEmpty && !_isGenerating
                ? const _WelcomeState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _messages.length +
                        (_isGenerating ? 1 : 0) +
                        (_steps.isNotEmpty ? 1 : 0),
                    itemBuilder: (context, index) {
                      final stepPanelIndex = _messages.length;
                      final streamingIndex = stepPanelIndex +
                          (_steps.isNotEmpty ? 1 : 0);

                      if (index == stepPanelIndex && _steps.isNotEmpty) {
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
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: SafeArea(
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
      ),
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
                style: AppText.body.copyWith(color: AppColors.textPrimary, fontSize: 16),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Message Gemma AI...',
                  hintStyle: AppText.body.copyWith(color: AppColors.textHint, fontSize: 16),
                  filled: true,
                  fillColor: AppColors.bgSoft,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 4),
      dense: true,
      leading: const Icon(Icons.psychology, size: 18, color: AppColors.primary),
      title: Text(
        'Agent Steps',
        style: AppText.bodySemiBold.copyWith(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final s in steps)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: s.isError ? AppColors.red : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s.text,
                          style: AppText.body.copyWith(
                            fontSize: 13,
                            color: s.isError
                                ? AppColors.red
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
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
    final isAI = !isUser && !isError;

    final bg = isError
        ? AppColors.red.withValues(alpha: 0.06)
        : isUser
            ? AppColors.primary
            : Colors.transparent;

    final fg = isError
        ? AppColors.red
        : isUser
            ? Colors.white
            : AppColors.textPrimary;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.80,
        ),
        padding: isAI
            ? const EdgeInsets.symmetric(horizontal: 4, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: text.isEmpty && isStreaming
            ? const TypingDots()
            : SelectableText(
                text,
                style: AppText.body.copyWith(color: fg, fontSize: 15, height: 1.5),
              ),
      ),
    );
  }
}

/// Three pulsing dots shown while the model is thinking.
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
    final colors = [AppColors.primary, AppColors.primary, AppColors.primary];
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
                    color: color.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
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

/// Empty-state shown when no messages exist yet.
/// Displays the Ghostsmart Lottie + a typewriter "How may I help you?".
class _WelcomeState extends StatefulWidget {
  const _WelcomeState();

  @override
  State<_WelcomeState> createState() => _WelcomeStateState();
}

class _WelcomeStateState extends State<_WelcomeState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _typeController;
  static const _fullText = 'How may I help you?';

  @override
  void initState() {
    super.initState();
    _typeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
  }

  @override
  void dispose() {
    _typeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/Ghostsmart.json',
            width: 200,
            height: 200,
            repeat: true,
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _typeController,
            builder: (context, _) {
              final charCount =
                  (_typeController.value * _fullText.length).floor();
              final shown = _fullText.substring(
                  0, charCount.clamp(0, _fullText.length));
              final showCursor = _typeController.value < 1.0;
              return Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    shown,
                    style: AppText.heading.copyWith(
                      fontSize: 24,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (showCursor)
                    Text(
                      '|',
                      style: AppText.heading.copyWith(
                        fontSize: 24,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
