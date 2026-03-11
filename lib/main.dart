import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:media_kit/media_kit.dart';
import 'providers/channel_provider.dart';
import 'screens/main_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize media_kit
  MediaKit.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ChannelProvider(),
      child: const StreamVisionApp(),
    ),
  );
}

class StreamVisionApp extends StatelessWidget {
  const StreamVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StreamVision IPTV',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainScreen(),
    );
  }
}
