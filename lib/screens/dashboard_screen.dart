import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Importaciones de tus pantallas
import 'history_screen.dart';
import 'inventory_screen.dart';
import 'new_sale_screen.dart';
import 'sales_chart_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryNavy = Color(0xFF2C3E50);
    const Color accentGold = Color(0xFFB89352);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F5F0),
      appBar: AppBar(
        title: Text(
          "YOLANDA'S STYLE",
          style: GoogleFonts.oswald(color: Colors.white, letterSpacing: 2),
        ),
        backgroundColor: primaryNavy,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 10),

            /// Título
            Text(
              "Menú de Gestión",
              style: GoogleFonts.playfairDisplay(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: primaryNavy,
              ),
            ),

            const SizedBox(height: 30),

            /// Grid de opciones
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  _buildCard(
                    context,
                    "NUEVA VENTA",
                    Icons.add_shopping_cart,
                    primaryNavy,
                    accentGold,
                    () => _navigateTo(
                      context,
                      const NewSaleScreen(), // Si esto sigue en rojo, ve a new_sale_screen.dart y cambia el nombre de la clase
                    ),
                  ),

                  _buildCard(
                    context,
                    "HISTORIAL",
                    Icons.history,
                    primaryNavy,
                    accentGold,
                    () => _navigateTo(context, const HistoryScreen()),
                  ),

                  _buildCard(
                    context,
                    "INVENTARIO",
                    Icons.inventory_2_outlined,
                    primaryNavy,
                    accentGold,
                    () => _navigateTo(context, const InventoryScreen()),
                  ),

                  _buildCard(
                    context,
                    "REPORTES",
                    Icons.bar_chart,
                    primaryNavy,
                    accentGold,
                    () => _navigateTo(context, const SalesChartScreen()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Navegación entre pantallas
  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  /// Tarjeta reutilizable del menú
  Widget _buildCard(
    BuildContext context,
    String title,
    IconData icon,
    Color navy,
    Color gold,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: gold),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.bold,
                    color: navy,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
