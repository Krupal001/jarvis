import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_demo/chat_screen.dart';
import 'package:flutter_gemma_demo/core/model_url.dart';
import 'package:flutter_gemma_demo/core/services/automation_service.dart';
import 'package:flutter_gemma_demo/ui/app_background.dart';
import 'package:flutter_gemma_demo/ui/app_theme.dart';
import 'package:flutter_gemma_demo/ui/app_widgets.dart';
import 'package:flutter_gemma_demo/ui/assistant_screen.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:flutter_gemma_speech/flutter_gemma_speech.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const platform = MethodChannel('com.example.assistant/intent');
  await FlutterGemma.initialize(
     sttBackends:[LiteRtSttBackend()],
     ttsBackends:[LiteRtTtsBackend()],
     inferenceEngines: [
      LiteRtLmEngine(),
    ],
  );
  
  String launchType = "DEFAULT";
  try {
   launchType = await platform.invokeMethod('getLaunchIntentAction');
  } catch (e) {
    print("Failed to get launch intent: $e");
  }

  runApp(MyApp(launchType: launchType));
}

class MyApp extends StatelessWidget {
  final String launchType;
  const MyApp({super.key, required this.launchType});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gemma AI',
      theme: appTheme(launchType == "ASSIST" ? Colors.transparent : AppColors.bgBase),
      debugShowCheckedModeBanner: false,
      home: BootstrapScreen(launchType: launchType),
    );
  }
}
/// Handles model download (if needed) and then launches the chat screen.
class BootstrapScreen extends StatefulWidget {
  final String launchType;
  const BootstrapScreen({super.key, required this.launchType});

  @override
  State<BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends State<BootstrapScreen>
    with WidgetsBindingObserver {
  double? _downloadProgress;
  String _status = 'Checking model...';
  String? _error;
  bool _ready = false;
  bool _needsPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _prepareModel();
    _checkAccessibility();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAccessibility();
    }
  }
      
Future<void> _checkAccessibility() async {
  final enabled =
      await AutomationService.isAccessibilityEnabled();

  if (!mounted) return;

  if (!enabled) {
    _showPermissionRequest();
  } else {
    setState(() {
      _needsPermission = false;
    });
  }
}

  Future<void> _prepareModel() async {
    const filename = 'gemma-4-E2B-it.litertlm';

    try {
      await Permission.notification.request();

      final isInstalled = await FlutterGemma.isModelInstalled(filename);
      if (!isInstalled) {
        setState(() {
          _status = 'Downloading model...';
          _downloadProgress = 0;
        });

        await FlutterGemma
            .installModel(
              modelType: ModelType.gemma4,
              fileType: ModelFileType.litertlm,
            )
            .fromNetwork(modelUrl, foreground: true)
            .withProgress((progress) {
              if (!mounted) return;
              setState(() => _downloadProgress = progress.toDouble());
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
        _downloadProgress = null;
      });
    }
  }

  void _showPermissionRequest() {
    if (!mounted) return;
    setState(() => _needsPermission = true);
  }

  Future<void> _openAccessibilitySettings() async {
    await AutomationService.openAccessibilitySettings();
  }

  @override
Widget build(BuildContext context) {
  final isAssist = widget.launchType == "ASSIST";
  return Scaffold(
    backgroundColor: isAssist ? Colors.transparent : null,
    body: Stack(
      children: [
        if (!isAssist) const AppBackground(),
        if (_error != null)
          _buildError()
        else if (_needsPermission)
          _buildPermissionRequest()
        else if (!_ready)
          _buildLoading()
        else if (widget.launchType == "ASSIST")
          const AssistantScreen()
        else
          const ChatScreen(),
      ],
    ),
  );
}

  Widget _buildLoading() {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLogo(),
            const SizedBox(height: 48),
            if (_downloadProgress != null) ...[
              ProgressRing(progress: _downloadProgress! / 100, size: 140),
              const SizedBox(height: 24),
            ] else ...[
              const LoadingIndicator(size: 40),
              const SizedBox(height: 24),
            ],
            Text(
              _status,
              style: AppText.heading.copyWith(fontSize: 18, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            if (_downloadProgress != null)
              Text(
                '${_downloadProgress!.toStringAsFixed(1)}%',
                style: AppText.mono.copyWith(
                  color: AppColors.primary,
                  fontSize: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
            boxShadow: AppShadows.elevated(blur: 12, opacity: 0.1),
          ),
          child: Center(
            child: Icon(
              Icons.auto_awesome,
              size: 40,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Gemma AI',
          style: AppText.headingBold.copyWith(
            fontSize: 26,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'AI Powered Assistant',
          style: AppText.body.copyWith(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionRequest() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
            accentColor: AppColors.primary,
            borderRadius: 20,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.08),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(Icons.accessibility_new,
                        size: 36, color: AppColors.primary),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Accessibility Permission',
                    style: AppText.headingBold.copyWith(
                      fontSize: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This app needs accessibility permission to automate SMS, WhatsApp, and app installation. Please enable it in system settings.',
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 28),
                  GlassButton(
                    label: 'Open Settings',
                    icon: Icons.settings,
                    onPressed: _openAccessibilitySettings,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _needsPermission = false;
                      });
                    },
                    child: Text(
                      'Skip for now',
                      style: AppText.body.copyWith(
                        color: AppColors.textHint,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return SafeArea(
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
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.red.withValues(alpha: 0.08),
                      border: Border.all(
                        color: AppColors.red.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(Icons.error_outline,
                        size: 36, color: AppColors.red),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Setup Failed',
                    style: AppText.heading.copyWith(
                      fontSize: 22,
                      color: AppColors.red,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 28),
                  GlassButton(
                    label: 'Retry',
                    icon: Icons.refresh,
                    color: AppColors.red,
                    onPressed: () {
                      setState(() {
                        _error = null;
                        _status = 'Checking model...';
                      });
                      _prepareModel();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
