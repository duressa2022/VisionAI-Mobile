import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:vision_ai/screens/home_screen.dart';
import 'package:vision_ai/services/provider.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Request permissions and check status
  final permissionStatus = await [
    Permission.camera,
    Permission.microphone,
  ].request();

  print('Camera permission: ${permissionStatus[Permission.camera]}');
  print('Microphone permission: ${permissionStatus[Permission.microphone]}');

  if (permissionStatus[Permission.camera]!.isDenied ||
      permissionStatus[Permission.camera]!.isPermanentlyDenied) {
    print('Camera permission denied');
    if (permissionStatus[Permission.camera]!.isPermanentlyDenied) {
      await openAppSettings(); // Prompt user to enable in settings
    }
  } else {
    // Get available cameras
    try {
      cameras = await availableCameras();
      print('Available cameras: ${cameras.length}');
    } on CameraException catch (e) {
      print('Error initializing camera: $e');
    }
  }

  runApp(const VisionAIApp());
}

class VisionAIApp extends StatelessWidget {
  const VisionAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => VisionProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Vision AI',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6750A4),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6750A4),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: const HomeScreen(), // Start with HomeScreen
      ),
    );
  }
}
