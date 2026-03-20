import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SalesHistoryScreen extends StatelessWidget {
  // Paleta de colores consistente
  final Color primaryNavy = const Color(0xFF2C3E50);
  final Color accentGold = const Color(0xFFB89352);
  final Color lightBeige = const Color(0xFFF9F5F0);
  final Color cardNavy = const Color(0xFF34495E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryNavy,
      appBar: AppBar(
        backgroundColor: primaryNavy,
        elevation: 0,
        title: Text(
          "SALES HISTORY",
          style: GoogleFonts.oswald(color: Colors.white, letterSpacing: 1.5),
        ),
        iconTheme: IconThemeData(color: accentGold),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: accentGold),
            onPressed: () {
              // Aquí podrías abrir un DatePicker o un Modal de filtros
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPeriodSelector(),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: lightBeige,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildSectionTitle("TODAY"),
                    _buildHistoryItem(
                      "#1488",
                      "14:20 PM",
                      "2 items",
                      "\$185.00",
                      true,
                    ),
                    _buildHistoryItem(
                      "#1487",
                      "11:05 AM",
                      "1 item",
                      "\$210.00",
                      false,
                    ),
                    const SizedBox(height: 20),
                    _buildSectionTitle("YESTERDAY"),
                    _buildHistoryItem(
                      "#1486",
                      "18:45 PM",
                      "3 items",
                      "\$450.00",
                      true,
                    ),
                    _buildHistoryItem(
                      "#1485",
                      "16:20 PM",
                      "1 item",
                      "\$95.00",
                      true,
                    ),
                    _buildHistoryItem(
                      "#1484",
                      "10:15 AM",
                      "2 items",
                      "\$120.00",
                      false,
                    ),
                    const SizedBox(height: 20),
                    _buildSectionTitle("MARCH 18, 2026"),
                    _buildHistoryItem(
                      "#1483",
                      "12:30 PM",
                      "4 items",
                      "\$890.00",
                      true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Selector de Periodo (Hoy, Semana, Mes)
  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            _buildFilterChip("ALL TIME", false),
            _buildFilterChip("TODAY", true),
            _buildFilterChip("THIS WEEK", false),
            _buildFilterChip("THIS MONTH", false),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? accentGold : cardNavy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 15),
      child: Text(
        title,
        style: GoogleFonts.oswald(
          color: primaryNavy.withOpacity(0.7),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildHistoryItem(
    String id,
    String time,
    String qty,
    String total,
    bool isPaid,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: lightBeige,
          child: Icon(Icons.receipt_long, color: primaryNavy, size: 20),
        ),
        title: Text(
          "Order $id",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Row(
          children: [
            Text(time, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(width: 10),
            Text(
              "• $qty",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              total,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: primaryNavy,
              ),
            ),
            Text(
              isPaid ? "PAID" : "PENDING",
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: isPaid ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
        onTap: () {
          // Navegar al detalle de la venta si fuera necesario
        },
      ),
    );
  }
}
