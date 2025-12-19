import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:window_manager/window_manager.dart';
import 'lottery.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 在非移动端设置窗口大小限制
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    await windowManager.ensureInitialized();

    const windowSize = Size(432, 785);

    WindowOptions windowOptions = const WindowOptions(
      size: windowSize,
      maximumSize: windowSize,
      minimumSize: Size(320, 480),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LuckyU',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 48, 200, 76),
        ),
        useMaterial3: true,
      ),
      // 在浏览器环境下限制内容最大宽度
      builder: (context, child) {
        if (kIsWeb) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 432),
              child: child,
            ),
          );
        }
        return child!;
      },
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LotteryScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 62, 143, 206),
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = 120.0;
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final baseHue = (_controller.value * 360);
                final colors = List<Color>.generate(6, (i) {
                  final hue = (baseHue + i * 60) % 360;
                  return HSVColor.fromAHSV(1.0, hue, 0.9, 0.95).toColor();
                });

                final shader = LinearGradient(
                  colors: colors,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ).createShader(Rect.fromLTWH(0, 0, width, height));

                final opacity = 0.6 + 0.4 * (0.5 + 0.5 * (1.0 - (_controller.value - 0.5).abs() * 2));

                return Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Text(
                    'Good Luck To You',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      foreground: Paint()..shader = shader,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
