import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter_gemma/core/api/flutter_gemma.dart';
import 'package:flutter_gemma/core/model_management/model_specs.dart';
import 'package:flutter_gemma/flutter_gemma_interface.dart';
import 'package:record/record.dart';
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
final AudioRecorder _recorder = AudioRecorder();
SpeechRecognizer? _recognizer;
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
       _recognizer = await FlutterGemma.getActiveStt();


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

  }
Future<void> startRecording() async {
  if (!await _recorder.hasPermission()) {
    return;
  }

  final path = '${Directory.systemTemp.path}/recording.wav';

  await _recorder.start(
    const RecordConfig(
      encoder: AudioEncoder.wav,
      sampleRate: 16000,
      numChannels: 1,
    ),
    path: path,
  );
}

Uint8List extractPcmFromWav(Uint8List wavBytes) {
  // Standard WAV header is usually 44 bytes.
  // Find the "data" chunk instead of assuming 44 bytes,
  // because WAV headers can vary.

  for (int i = 12; i < wavBytes.length - 8; i++) {
    if (wavBytes[i] == 0x64 && // d
        wavBytes[i + 1] == 0x61 && // a
        wavBytes[i + 2] == 0x74 && // t
        wavBytes[i + 3] == 0x61) { // a

      final dataSize =
          wavBytes[i + 4] |
          (wavBytes[i + 5] << 8) |
          (wavBytes[i + 6] << 16) |
          (wavBytes[i + 7] << 24);

      final dataStart = i + 8;
      final dataEnd = dataStart + dataSize;

      return Uint8List.fromList(
        wavBytes.sublist(
          dataStart,
          dataEnd > wavBytes.length ? wavBytes.length : dataEnd,
        ),
      );
    }
  }

  throw Exception('Invalid WAV: PCM data chunk not found');
}

Future<void> stopRecording() async {
  final path = await _recorder.stop();

  if (path == null) return;

  final wavBytes = await File(path).readAsBytes();

  // Extract PCM from WAV here.
  final Uint8List pcm16kMono = extractPcmFromWav(wavBytes);

  final text = await _recognizer!.transcribe(pcm16kMono);

  print('TRANSCRIPT: $text');
}
  @override
  void initState() {
    _prepareModel();
    super.initState();
  }
  

  Future<void> _toggleVoiceRecording() async {
  if (_isVoiceMode) {
    await _recorderController.stop();
    await stopRecording();

    if (!mounted) return;

    setState(() {
      _isVoiceMode = false;
    });
  } else {
    await startRecording();
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
  _recorder.dispose();
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
                  child: !_ready
                      ? _buildDownloadOverlay()
                      : _buildGeminiInputBar(),
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
  Widget _buildDownloadOverlay() {
  final modelProgress = _downloadProgresssstMOdel ?? 0;
  final tokenizerProgress = _downloadProgressssTokenizer ?? 0;

  return Center(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome,
            color: Colors.blueAccent,
            size: 32,
          ),

          const SizedBox(height: 16),

          const Text(
            'Preparing Assistant',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Downloading speech model...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 20),

          LinearProgressIndicator(
            value: modelProgress / 100,
            minHeight: 5,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${modelProgress.toStringAsFixed(0)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Tokenizer ${tokenizerProgress.toStringAsFixed(0)}%',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),
  );
}
}
