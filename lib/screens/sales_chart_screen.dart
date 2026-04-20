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

  String selectedFilter = 'Mes';

  // Consolidamos la carga de datos para evitar desincronización
  Future<Map<String, dynamic>> _fetchReportData() async {
    final spots = await DatabaseHelper.instance.getSalesSpots(selectedFilter);
    final history = await DatabaseHelper.instance.getFilteredSalesHistory(
      selectedFilter,
    );

    double total = 0.0;
    for (var spot in spots) {
      total += spot.y;
    }

    return {'spots': spots, 'history': history, 'total': total};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
              "Reportes de Ventas",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 10),
        decoration: BoxDecoration(
          color: lightBeige,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _buildFilterSelector(),
            ),
            Expanded(
              // ValueKey garantiza que el FutureBuilder se reinicie al cambiar el filtro
              child: FutureBuilder<Map<String, dynamic>>(
                key: ValueKey(selectedFilter),
                future: _fetchReportData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return _buildEmptyState("Error al cargar datos");
                  }

                  final data = snapshot.data!;
                  final List<FlSpot> spots = data['spots'];
                  final List<Map<String, dynamic>> history = data['history'];
                  final double totalSales = data['total'];

                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildSummaryCard(totalSales),
                      const SizedBox(height: 25),

                      // Gráfica de Ventas
                      SizedBox(
                        height: 200,
                        child: spots.isEmpty
                            ? _buildEmptyState("Sin datos para graficar")
                            : BarChart(_mainBarData(spots)),
                      ),

                      const SizedBox(height: 30),
                      Text(
                        "Detalle de Productos Vendidos",
                        style: GoogleFonts.oswald(
                          fontSize: 18,
                          color: primaryNavy,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 15),

                      history.isEmpty
                          ? _buildEmptyState("Sin ventas en este periodo")
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: history.length,
                              itemBuilder: (context, index) =>
                                  _buildHistoryItem(history[index]),
                            ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    DateTime date = DateTime.parse(item['date']);
    String formattedDate =
        "${date.day}/${date.month} - ${date.hour}:${date.minute.toString().padLeft(2, '0')} hrs";

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: accentGold.withOpacity(0.2),
          child: Icon(Icons.shopping_bag, color: accentGold, size: 20),
        ),
        title: Text(
          item['products_summary'] ?? 'Producto sin nombre',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Text(
          formattedDate,
          style: TextStyle(color: primaryNavy.withOpacity(0.5), fontSize: 11),
        ),
        trailing: Text(
          "\$${(item['total'] as num).toStringAsFixed(2)}",
          style: TextStyle(
            color: primaryNavy,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          message,
          style: TextStyle(color: primaryNavy.withOpacity(0.4)),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryNavy.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Total Ingresos ($selectedFilter)",
            style: TextStyle(color: primaryNavy.withOpacity(0.6), fontSize: 14),
          ),
          Text(
            "\$${total.toStringAsFixed(2)}",
            style: GoogleFonts.oswald(
              color: primaryNavy,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSelector() {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'Día', label: Text('Hoy')),
          ButtonSegment(value: 'Semana', label: Text('Semana')),
          ButtonSegment(value: 'Mes', label: Text('Mes')),
        ],
        selected: {selectedFilter},
        onSelectionChanged: (newSelection) {
          setState(() => selectedFilter = newSelection.first);
        },
        style: SegmentedButton.styleFrom(
          backgroundColor: Colors.white,
          selectedBackgroundColor: accentGold,
          selectedForegroundColor: Colors.white,
          foregroundColor: primaryNavy,
        ),
      ),
    );
  }

  BarChartData _mainBarData(List<FlSpot> spots) {
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: spots.isEmpty ? 10 : null,
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (group) => primaryNavy.withOpacity(0.9),
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            String time = selectedFilter == 'Día'
                ? "${group.x.toInt()}:00h"
                : "Día ${group.x.toInt()}";
            return BarTooltipItem(
              "$time\n\$${rod.toY.toStringAsFixed(2)}",
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 35,
            getTitlesWidget: (value, meta) => Text(
              "\$${value.toInt()}",
              style: TextStyle(
                color: primaryNavy.withOpacity(0.6),
                fontSize: 9,
              ),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              String text = selectedFilter == 'Día'
                  ? "${value.toInt()}h"
                  : "${value.toInt()}";
              return SideTitleWidget(
                meta: meta,
                space: 8,
                child: Text(
                  text,
                  style: TextStyle(
                    color: primaryNavy,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      barGroups: spots.map((spot) {
        return BarChartGroupData(
          x: spot.x.toInt(),
          barRods: [
            BarChartRodData(
              toY: spot.y,
              color: accentGold,
              width: selectedFilter == 'Mes' ? 8 : 16,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
