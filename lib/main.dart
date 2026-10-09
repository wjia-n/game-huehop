import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'services/audio_service.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final settings = HueHopSettings();
  await settings.load();
  final audio = HueHopAudio();
  audio.configure(
    musicOn: settings.musicOn,
    sfxOn: settings.sfxOn,
    volume: settings.volume,
  );
  runApp(HueHopApp(settings: settings, audio: audio));
}

class HueHopApp extends StatefulWidget {
  final HueHopSettings settings;
  final HueHopAudio audio;
  const HueHopApp({super.key, required this.settings, required this.audio});

  @override
  State<HueHopApp> createState() => _HueHopAppState();
}

class _HueHopAppState extends State<HueHopApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.audio.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause (not stop) on interruption so music resumes exactly where it
    // left off; game screens additionally freeze their engines.
    if (state == AppLifecycleState.paused) {
      widget.audio.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      widget.audio.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (_, _) => MaterialApp(
        title: 'Hue Hop',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: widget.settings.theme.bg,
          colorScheme: ColorScheme.fromSeed(seedColor: widget.settings.theme.accent),
          useMaterial3: true,
        ),
        home: SplashScreen(audio: widget.audio, settings: widget.settings),
      ),
    );
  }
}
