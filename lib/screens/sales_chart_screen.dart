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
  double totalSales = 0.0;

  // 1. Obtener datos para la Gráfica
  Future<List<FlSpot>> _getSpots() async {
    final spots = await DatabaseHelper.instance.getSalesSpots(selectedFilter);
    double currentTotal = 0.0;
    for (var spot in spots) {
      currentTotal += spot.y;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && totalSales != currentTotal) {
        setState(() => totalSales = currentTotal);
      }
    });
    return spots;
  }

  // 2. Obtener datos para la Lista de Detalles
  Future<List<Map<String, dynamic>>> _getHistoryDetails() {
    return DatabaseHelper.instance.getFilteredSalesHistory(selectedFilter);
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
              style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 18),
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildFilterSelector(),
              const SizedBox(height: 15),
              _buildSummaryCard(),
              const SizedBox(height: 20),

              // --- LA GRÁFICA DE BARRAS ---
              SizedBox(
                height: 200, // Ajustamos la altura para que la gráfica se vea bien
                child: FutureBuilder<List<FlSpot>>(
                  future: _getSpots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text("Sin datos para graficar", style: TextStyle(color: primaryNavy.withOpacity(0.5))));
                    }
                    
                    // CAMBIO A BAR CHART
                    return BarChart(_mainBarData(snapshot.data!));
                  },
                ),
              ),
              const SizedBox(height: 20),

              // --- TÍTULO DE DETALLES ---
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Detalle de Productos Vendidos",
                  style: GoogleFonts.oswald(
                    fontSize: 18,
                    color: primaryNavy,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // --- LISTA DE PRODUCTOS VENDIDOS ---
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _getHistoryDetails(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text("Sin ventas en este periodo", style: TextStyle(color: primaryNavy.withOpacity(0.5))));
                    }

                    final history = snapshot.data!;
                    return ListView.builder(
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final item = history[index];
                        // Formatear la fecha
                        DateTime date = DateTime.parse(item['date']);
                        String formattedDate = "${date.day}/${date.month} - ${date.hour}:${date.minute.toString().padLeft(2, '0')} hrs";

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
                              item['products_summary'] ?? 'Producto eliminado',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            subtitle: Text(
                              formattedDate,
                              style: TextStyle(color: primaryNavy.withOpacity(0.5), fontSize: 11),
                            ),
                            trailing: Text(
                              "\$${(item['total'] as num).toStringAsFixed(2)}",
                              style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: primaryNavy.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          Text(
            "Total Ingresos ($selectedFilter)",
            style: TextStyle(color: primaryNavy.withOpacity(0.6), fontSize: 14),
          ),
          Text(
            "\$${totalSales.toStringAsFixed(2)}",
            style: GoogleFonts.oswald(color: primaryNavy, fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSelector() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'Día', label: Text('Hoy')),
        ButtonSegment(value: 'Semana', label: Text('Semana')),
        ButtonSegment(value: 'Mes', label: Text('Mes')),
      ],
      selected: {selectedFilter},
      onSelectionChanged: (newSelection) {
        setState(() {
          selectedFilter = newSelection.first;
          totalSales = 0.0;
        });
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) return accentGold;
          return Colors.white;
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return primaryNavy;
        }),
      ),
    );
  }
// --- NUEVA CONFIGURACIÓN PARA GRÁFICA DE BARRAS ---
  BarChartData _mainBarData(List<FlSpot> spots) {
    // Convertir FlSpots en BarChartGroups (Las barras)
    List<BarChartGroupData> barGroups = spots.map((spot) {
      return BarChartGroupData(
        x: spot.x.toInt(),
        barRods: [
          BarChartRodData(
            toY: spot.y,
            color: accentGold,
            width: selectedFilter == 'Mes' ? 8 : 14, 
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (group) => primaryNavy.withOpacity(0.9),
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            String time = "";
            if (selectedFilter == 'Día') {
              time = "${group.x}:00 hrs";
            } else if (selectedFilter == 'Semana') {
              time = "Día ${group.x}";
            } else {
              time = "Día ${group.x}";
            }
            
            return BarTooltipItem(
              "$time\nGenerado: \$${rod.toY.toStringAsFixed(2)}",
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            );
          },
        ),
      ),
      // Mantenemos solo una instancia de gridData
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 35,
            getTitlesWidget: (value, meta) => Text(
              "\$${value.toInt()}",
              style: TextStyle(color: primaryNavy.withOpacity(0.6), fontSize: 10),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              String text = "";
              if (selectedFilter == 'Día') {
                text = "${value.toInt()}h";
              } else if (selectedFilter == 'Semana') {
                text = "Día ${value.toInt()}";
              } else {
                text = value.toInt().toString();
              }
              
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(text, style: TextStyle(color: primaryNavy, fontSize: 9, fontWeight: FontWeight.bold)),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups: barGroups,
    );
  }
}
