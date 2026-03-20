import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

class SalesChartScreen extends StatelessWidget {
  const SalesChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Colores basados en la imagen de Yolanda's Style Room
    const Color primaryNavy = Color(0xFF2C3E50);
    const Color accentGold = Color(0xFFB89352);
    const Color lightBeige = Color(0xFFF9F5F0);

    return Scaffold(
      backgroundColor: primaryNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // Para que la flecha de regreso sea blanca
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Yolanda's Style Room",
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              "Created 07/02/2026", // Fecha del proyecto [cite: 7]
              style: TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("INICIO", style: TextStyle(color: accentGold, fontSize: 10)),
                Text("Roberto Hernández", style: TextStyle(color: Colors.white, fontSize: 12)), // Autor [cite: 9]
              ],
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              "SALES FLUX CHART",
              style: GoogleFonts.oswald(
                color: accentGold,
                fontSize: 24,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: lightBeige,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                children: [
                  const Text(
                    "SALES PERFORMANCE: FEB 2026",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 30),
                  // Gráfica corregida
                  AspectRatio(
                    aspectRatio: 1.7,
                    child: LineChart(mainData(accentGold)),
                  ),
                  const SizedBox(height: 30),
                  // Estadísticas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statItem("MONTH-TO-DATE SALES", "\$15,840.00"),
                      _statItem("BEST-SELLING CATEGORY", "Dresses (35%)"),
                    ],
                  ),
                  const Spacer(),
                  // Selectores de tiempo
                  ToggleButtons(
                    isSelected: const [true, false, false],
                    onPressed: (int index) {},
                    borderRadius: BorderRadius.circular(10),
                    selectedColor: Colors.white,
                    fillColor: primaryNavy,
                    color: primaryNavy.withOpacity(0.5),
                    constraints: const BoxConstraints(minHeight: 35, minWidth: 80),
                    children: const [Text("Daily"), Text("Weekly"), Text("Monthly")],
                  ),
                  const SizedBox(height: 20),
                  // Botón Generar Reporte
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentGold,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("GENERATE REPORT", style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
      ],
    );
  }

  LineChartData mainData(Color color) {
    return LineChartData(
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      titlesData: const FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: const [
            FlSpot(0, 5), FlSpot(5, 12), FlSpot(10, 8), FlSpot(15, 18), 
            FlSpot(20, 14), FlSpot(25, 22), FlSpot(28, 19),
          ],
          isCurved: true,
          color: color,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true, 
            color: color.withOpacity(0.2),
          ),
        ),
      ],
    );
  }
}