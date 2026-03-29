import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryNavy = Color(0xFF2C3E50);
    const Color accentGold = Color(0xFFB89352);

    return MaterialApp(
      title: "Yolanda's Style Room",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryNavy,
          primary: primaryNavy,
          secondary: accentGold,
          surface: const Color(0xFFF9F5F0),
        ),
        textTheme: GoogleFonts.latoTextTheme(),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryNavy,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}
