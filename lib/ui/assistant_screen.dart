import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter_gemma/core/api/flutter_gemma.dart';
import 'package:flutter_gemma/core/model_management/model_specs.dart';
import 'package:zo_animated_border/zo_animated_border.dart';
import 'dart:ui' as ui show Gradient;

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  final RecorderController _recorderController = RecorderController();
  double? _downloadProgresssstMOdel;
  double? _downloadProgressssTokenizer;
  bool _isVoiceMode = false;
  String _status = 'Checking model...';
  String? _error;
  bool _ready = false;

  Future<void> _prepareModel() async {
    try {
      final isInstalled = await FlutterGemma.isModelInstalled('moonshine_tiny_5s_f32.tflite');
      if (!isInstalled) {
      await FlutterGemma.installStt()
          .modelFromNetwork(
            'https://huggingface.co/litert-community/moonshine-tiny/resolve/main/moonshine_tiny_5s_f32.tflite',
          )
          .tokenizerFromNetwork(
            'https://huggingface.co/UsefulSensors/moonshine/resolve/main/ctranslate2/tiny/tokenizer.json',
          )
          .ofType(SttModelType.moonshine)
          .withModelProgress((progress) {
            if (!mounted) return;
            setState(() => _downloadProgresssstMOdel = progress.toDouble());
          })
          .withTokenizerProgress((progress) {
            if (!mounted) return;
            setState(() => _downloadProgressssTokenizer = progress.toDouble());
          })
          .install();

      }

      if (!mounted) return;
      setState(() {
        _ready = true;
        _status = 'Ready';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _downloadProgresssstMOdel = null;
        _downloadProgressssTokenizer = null;
      });
    }
    final recognizer = await FlutterGemma.getActiveStt();

// pcm: 16 kHz mono 16-bit little-endian PCM bytes (Uint8List) — e.g. the data
// chunk of a WAV, or frames from a recorder. moonshine-tiny handles up to ~5 s.
final transcript = await recognizer.transcribe(pcm);
print(transcript); // "She had ... watch for all year."

await recognizer.close();

  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _toggleVoiceRecording() async {
  if (_isVoiceMode) {
    await _recorderController.stop();

    if (!mounted) return;

    setState(() {
      _isVoiceMode = false;
    });
  } else {
    await _recorderController.record();

    if (!mounted) return;

    setState(() {
      _isVoiceMode = true;
    });
  }
}

  @override
  void dispose() {
    _textController.dispose();
    _recorderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ZoSegmentBorder(
        glowOpacity: _isVoiceMode ? 1 : 0.3,
        borderRadius: 28,
        segmentLength: 0.2,
        colors: const [Colors.blueAccent, Colors.purpleAccent],
        glowSpread: 20,
        child: Stack(
          children: [
            // Full-screen tap catcher to dismiss assistant
            Positioned.fill(
              child: GestureDetector(
                onTap: () => SystemNavigator.pop(),
                child: Container(color: Colors.transparent),
              ),
            ),
            // Floating Gemini-style input bar
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 90,
                  left: 16,
                  right: 16,
                ),
                child: GestureDetector(
                  onTap: () {},
                  child: _buildGeminiInputBar(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeminiInputBar() {
    return ZoSegmentBorder(
      glowOpacity: _isVoiceMode ? 1 : 0.3,
      borderRadius: 28,
      segmentLength: 0.2,
      colors: const [Colors.blueAccent, Colors.purpleAccent],
      glowSpread: 8,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(28),
        ),
        padding: const EdgeInsets.only(left: 20, right: 8, top: 6, bottom: 6),
        child: Row(
          children: [
            Expanded(
              child: _isVoiceMode
                  ? _buildAudioWaveAnimator()
                  : _buildTextFieldInput(),
            ),
            const SizedBox(width: 8),
            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFieldInput() {
    return TextField(
      controller: _textController,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      cursorColor: Colors.blueAccent,
      decoration: InputDecoration(
        hintText: "Ask Gemma...",
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        border: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildAudioWaveAnimator() {
    return Row(
      children: [
        Expanded(
          child: AudioWaveforms(
            size: const Size(double.infinity, 36),
            recorderController: _recorderController,
            enableGesture: false,
            waveStyle: WaveStyle(
              waveColor: Colors.blueAccent,
              extendWaveform: true,
              showMiddleLine: false,
              spacing: 3.5,
              gradient: ui.Gradient.linear(Offset(0, 0), Offset(1, 0), [
                Colors.blue.shade400,
                Colors.purple.shade400,
              ]),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          "Listening",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildActionButton() {
    return InkWell(
      onTap: _toggleVoiceRecording,
      customBorder: const CircleBorder(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isVoiceMode
              ? Colors.redAccent.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.08),
        ),
        child: Icon(
          _isVoiceMode ? Icons.stop_rounded : Icons.mic_none_rounded,
          color: _isVoiceMode ? Colors.redAccent.shade200 : Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
