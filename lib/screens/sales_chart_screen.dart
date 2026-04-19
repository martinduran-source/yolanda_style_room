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

  Future<List<FlSpot>> _getSpots() {
    return DatabaseHelper.instance.getSalesSpots(selectedFilter);
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
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Colors.amber),
            tooltip: "Generar ventas con productos actuales",
            onPressed: () async {
              final dbHelper = DatabaseHelper.instance;
              final db = await dbHelper.database;

              // 1. Limpiamos solo historial de ventas (NO productos)
              await db.delete('sale_items');
              await db.delete('sales');

              // 2. Pequeño respiro para la DB
              await Future.delayed(const Duration(milliseconds: 300));

              // 3. Crear historial de ventas usando tus productos existentes
              await seedHistoricalSales();

              // 4. Forzar el refresco de la pantalla para ver la gráfica
              setState(() {
                selectedFilter = selectedFilter;
              });

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("¡Ventas generadas usando tus productos!"),
                    backgroundColor: Colors.blueAccent,
                  ),
                );
              }
            },
          ),
        ],
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
              const SizedBox(height: 30),
              Expanded(
                child: FutureBuilder<List<FlSpot>>(
                  future: _getSpots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData ||
                        snapshot.data!.isEmpty ||
                        snapshot.data!.length < 2) {
                      return Center(
                        child: Text(
                          "No hay suficientes datos para graficar $selectedFilter",
                          style: TextStyle(color: primaryNavy.withOpacity(0.5)),
                        ),
                      );
                    }

                    final spots = snapshot.data!;
                    return LineChart(_mainData(spots));
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- MÉTODOS DE APOYO UI ---

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

  LineChartData _mainData(List<FlSpot> spots) {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) => Text(
              value.toInt().toString(),
              style: TextStyle(
                color: primaryNavy.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              String text = value.toInt().toString();
              if (selectedFilter == 'Día') text = "${value.toInt()}h";
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(text, style: const TextStyle(fontSize: 10)),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: accentGold,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: accentGold.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  // --- FUNCIÓN SEMILLA DE VENTAS (SOLO VENTAS) ---

  Future<void> seedHistoricalSales() async {
    final db = DatabaseHelper.instance;
    final now = DateTime.now();

    // Obtenemos los productos que ya tienes en tu base de datos
    final products = await db.getProducts();

    if (products.isEmpty) {
      debugPrint("No hay productos registrados para generar ventas.");
      return;
    }

    for (int i = 0; i < 30; i++) {
      final saleDate = now.subtract(Duration(days: i));

      // Formato YYYY-MM-DD para que la DB lo reconozca bien
      final dateString =
          "${saleDate.year}-${saleDate.month.toString().padLeft(2, '0')}-${saleDate.day.toString().padLeft(2, '0')}";

      // Generar entre 1 y 3 ventas aleatorias por día
      for (int v = 0; v < (i % 3 + 1); v++) {
        final product = (products..shuffle()).first;
        double price = (product['price'] as num).toDouble();

        int saleId = await db.insertSale({
          'date': dateString,
          'total': price,
          'status': 'completado',
          'item_count': 1,
        });

        await db.insertSaleItem({
          'sale_id': saleId,
          'product_id': product['id'],
          'quantity': 1,
          'price_at_sale': price,
        });
      }
    }
  }
}
