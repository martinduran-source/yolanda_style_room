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
  final Color lightBeige = const Color(0xFFF9F5F0);

  // Variable para almacenar el Future
  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    // Llamamos al método de Supabase. Puedes cambiar 'Mes' por 'Semana' o 'Día' 
    // según lo que quieras mostrar por defecto en esta pantalla.
    _historyFuture = DatabaseHelper.instance.getFilteredSalesHistory('Mes');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBeige,
      appBar: AppBar(
        title: Text(
          "HISTORIAL DE VENTAS",
          style: GoogleFonts.oswald(color: Colors.white, letterSpacing: 1.2),
        ),
        backgroundColor: primaryNavy,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 60, color: primaryNavy.withOpacity(0.3)),
                  const SizedBox(height: 15),
                  Text(
                    "No hay ventas registradas en este periodo.",
                    style: TextStyle(color: primaryNavy.withOpacity(0.6), fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final history = snapshot.data!;
          final int totalVentas = history.length;

          return Column(
            children: [
              // --- 1. TARJETA DE RESUMEN SUPERIOR ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: primaryNavy.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Total de Transacciones",
                          style: TextStyle(color: primaryNavy.withOpacity(0.6), fontSize: 14),
                        ),
                        Text(
                          "$totalVentas",
                          style: GoogleFonts.oswald(
                            color: primaryNavy, 
                            fontSize: 32, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ],
                    ),
                    CircleAvatar(
                      backgroundColor: accentGold.withOpacity(0.15),
                      radius: 28,
                      child: Icon(Icons.shopping_bag_outlined, color: accentGold, size: 30),
                    )
                  ],
                ),
              ),
              
              const SizedBox(height: 10),

              // --- 2. LISTA DEL HISTORIAL ---
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
                    
                    // Formateo de fecha de ISO 8601 a un formato legible
                    DateTime date = DateTime.parse(item['date']).toLocal();
                    String formattedDate = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} - ${date.hour}:${date.minute.toString().padLeft(2, '0')} hrs";

                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primaryNavy.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.receipt, color: primaryNavy),
                        ),
                        title: Text(
                          item['products_summary'] ?? 'Venta general',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            formattedDate,
                            style: TextStyle(color: primaryNavy.withOpacity(0.6), fontSize: 12),
                          ),
                        ),
                        trailing: Text(
                          "\$${(item['total'] as num).toStringAsFixed(2)}",
                          style: GoogleFonts.oswald(
                            color: accentGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}