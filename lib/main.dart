import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'screens/brain_dump_screen.dart';
import 'services/groq_service.dart';
import 'services/trim_session_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await TrimSessionRepository.instance.init();
  await GroqService.clearApiKey();

  // Edge-to-edge mobile setup
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const TrimApp());
}

class TrimApp extends StatelessWidget {
  const TrimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trim',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.dark,
      home: const BrainDumpScreen(),
    );
  }
}
