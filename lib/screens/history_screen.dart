import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Definimos los mismos colores del Dashboard para mantener la identidad
    const Color primaryNavy = Color(0xFF2C3E50);
    const Color accentGold = Color(0xFFB89352);
    final supabaseService = SupabaseService();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F5F0), // Fondo crema suave
      appBar: AppBar(
        title: Text(
          "HISTORIAL DE VENTAS",
          style: GoogleFonts.oswald(color: Colors.white, letterSpacing: 2),
        ),
        backgroundColor: primaryNavy,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: supabaseService.getVentas(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: accentGold),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                "No hay ventas registradas",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  color: primaryNavy,
                ),
              ),
            );
          }

          final ventas = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: ventas.length,
            itemBuilder: (context, index) {
              final venta = ventas[index];
              // Ajusta los nombres de las columnas ('total', 'created_at')
              // según los hayas creado en Supabase
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  leading: const Icon(
                    Icons.receipt_long,
                    color: accentGold,
                    size: 30,
                  ),
                  title: Text(
                    "Venta #${venta['id']}",
                    style: GoogleFonts.lato(
                      fontWeight: FontWeight.bold,
                      color: primaryNavy,
                    ),
                  ),
                  subtitle: Text(
                    "Fecha: ${venta['created_at'].toString().split('T')[0]}", // Formato simple de fecha
                    style: GoogleFonts.lato(color: Colors.grey[600]),
                  ),
                  trailing: Text(
                    "\$${venta['total']}",
                    style: GoogleFonts.lato(
                      fontWeight: FontWeight.bold,
                      color: accentGold,
                      fontSize: 18,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
