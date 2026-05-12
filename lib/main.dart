import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

 
await Supabase.initialize(
    url: 'https://gcunqsuzbgscepmulyid.supabase.co',
    anonKey: 'sb_publishable_AWvy52IBpR7N0CC2kov01w_VgQjUNS-',
  );
  
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
