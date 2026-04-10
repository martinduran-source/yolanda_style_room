import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/database_helper.dart';

class SalesChartScreen extends StatefulWidget {
  const SalesChartScreen({super.key});

  @override
  State<SalesChartScreen> createState() => _SalesChartScreenState();
}

class _SalesChartScreenState extends State<SalesChartScreen> {
  final Color primaryNavy = const Color(0xFF2C3E50);
  final Color accentGold = const Color(0xFFB89352);
  final Color lightBeige = const Color(0xFFF9F5F0);

  late Future<List<FlSpot>> _salesSpots;
String selectedFilter = 'Mes';

@override
void initState() {
  super.initState();
  _salesSpots = DatabaseHelper.instance.getSalesSpots(selectedFilter);
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "YOLANDA'S STYLE ROOM",
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            const Text(
              "Reportes del Mes",
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: lightBeige,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FutureBuilder<List<FlSpot>>(
            future: _salesSpots,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No hay datos de ventas"));
              }

              final spots = snapshot.data!;
              return LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: accentGold,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
