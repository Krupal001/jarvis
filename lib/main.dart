import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_demo/chat_screen.dart';
import 'package:flutter_gemma_demo/core/model_url.dart';
import 'package:flutter_gemma_demo/core/services/automation_service.dart';
import 'package:flutter_gemma_demo/ui/neon_background.dart';
import 'package:flutter_gemma_demo/ui/neon_theme.dart';
import 'package:flutter_gemma_demo/ui/neon_widgets.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FlutterGemma.initialize(
    inferenceEngines: [
      LiteRtLmEngine(),
    ],
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neon Gemma AI',
      theme: neonTheme(),
      darkTheme: neonTheme(),
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      home: const BootstrapScreen(),
    );
  }
}

/// Handles model download (if needed) and then launches the chat screen.
class BootstrapScreen extends StatefulWidget {
  const BootstrapScreen({super.key});

  @override
  State<BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends State<BootstrapScreen>
    with SingleTickerProviderStateMixin , WidgetsBindingObserver {
  double? _downloadProgress;
  String _status = 'Checking model...';
  String? _error;
  bool _ready = false;
  bool _needsPermission = false;
  late final AnimationController _logoController;

  @override
  void initState() {
   
    super.initState();
     WidgetsBinding.instance.addObserver(this);
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _prepareModel();
    _checkAccessibility();
    
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _logoController.dispose();
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
    return Scaffold(
      body: Stack(
        children: [
          const NeonBackground(),
          if (_error != null)
            _buildError()
          else if (_needsPermission)
            _buildPermissionRequest()
          else if (_ready)
            const ChatScreen()
          else
            _buildLoading(),
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
              NeonProgressRing(progress: _downloadProgress! / 100, size: 140),
              const SizedBox(height: 24),
            ] else ...[
              const NeonPulseRing(size: 100),
              const SizedBox(height: 24),
            ],
            NeonShimmerText(
              _status,
              style: NeonText.heading.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            if (_downloadProgress != null)
              Text(
                '${_downloadProgress!.toStringAsFixed(1)}%',
                style: NeonText.mono.copyWith(
                  color: NeonColors.cyan,
                  fontSize: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, _) {
        final t = _logoController.value;
        final glowAlpha = 0.12 + 0.15 * t;
        return Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: NeonColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: NeonColors.cyan.withValues(alpha: glowAlpha),
                    blurRadius: 20 + 10 * t,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: NeonColors.purple.withValues(alpha: glowAlpha * 0.6),
                    blurRadius: 30 + 10 * t,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.auto_awesome,
                  size: 48,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
            const SizedBox(height: 24),
            NeonGlowText(
              'Gemma AI',
              style: NeonText.headingBold.copyWith(
                fontSize: 28,
                color: Colors.white,
                letterSpacing: 2,
              ),
              glowColor: NeonColors.cyan,
              glowRadius: 8,
            ),
            const SizedBox(height: 6),
            Text(
              'AI POWERED ASSISTANT',
              style: NeonText.mono.copyWith(
                color: NeonColors.purple.withValues(alpha: 0.5),
                fontSize: 11,
                letterSpacing: 2.5,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPermissionRequest() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: NeonGlassCard(
            glowColor: NeonColors.cyan,
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
                      color: NeonColors.cyan.withValues(alpha: 0.1),
                      border: Border.all(
                        color: NeonColors.cyan.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(Icons.accessibility_new,
                        size: 36, color: NeonColors.cyan),
                  ),
                  const SizedBox(height: 20),
                  NeonGlowText(
                    'Accessibility Permission',
                    style: NeonText.headingBold.copyWith(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                    glowColor: NeonColors.cyan,
                    glowRadius: 6,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This app needs accessibility permission to automate SMS, WhatsApp, and app installation. Please enable it in system settings.',
                    textAlign: TextAlign.center,
                    style: NeonText.body.copyWith(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 28),
                  NeonButton(
                    label: 'OPEN SETTINGS',
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
                      style: NeonText.body.copyWith(
                        color: Colors.white38,
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
          child: NeonGlassCard(
            glowColor: Colors.red,
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
                      color: Colors.red.withValues(alpha: 0.1),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.3),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.error_outline,
                        size: 36, color: Colors.redAccent),
                  ),
                  const SizedBox(height: 20),
                  NeonGlowText(
                    'Setup Failed',
                    style: NeonText.heading.copyWith(
                      fontSize: 22,
                      color: Colors.redAccent,
                    ),
                    glowColor: Colors.red,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: NeonText.body.copyWith(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 28),
                  NeonButton(
                    label: 'RETRY',
                    icon: Icons.refresh,
                    gradient: LinearGradient(
                      colors: [Colors.red.shade700, Colors.red.shade400],
                    ),
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
