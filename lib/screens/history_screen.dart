import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database_helper.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Colores del tema
  final Color primaryNavy = const Color(0xFF2C3E50);
  final Color accentGold = const Color(0xFFB89352);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5F0),
      appBar: AppBar(
        title: Text(
          "HISTORIAL",
          style: GoogleFonts.oswald(color: Colors.white, letterSpacing: 1.2),
        ),
        backgroundColor: primaryNavy,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseHelper.instance.getSalesHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final int totalVentas = snapshot.data?.length ?? 0;

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 50,
                        color: accentGold,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "$totalVentas",
                        style: GoogleFonts.oswald(
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                          color: primaryNavy,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  "VENTAS REALIZADAS",
                  style: GoogleFonts.oswald(
                    fontSize: 22,
                    letterSpacing: 2,
                    color: primaryNavy,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "En total desde el inicio",
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                if (totalVentas > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      "¡Datos listos para reportes!",
                      style: TextStyle(
                        color: accentGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
