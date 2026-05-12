import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
          style: GoogleFonts.oswald(
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: primaryNavy,
        centerTitle: true,
        elevation: 0,
      ),
      // Envolvemos el body en un Center y un ConstrainedBox para limitar el ancho en la Web
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000), // Ancho máximo
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Alineación más moderna
              children: [
                const SizedBox(height: 10),

                /// Título
                Text(
                  "Menú de Gestión",
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32, // Un poco más grande para pantallas de escritorio
                    fontWeight: FontWeight.bold,
                    color: primaryNavy,
                  ),
                ),
                Text(
                  "Selecciona una opción para continuar",
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    color: primaryNavy.withOpacity(0.6),
                  ),
                ),

                const SizedBox(height: 30),

                /// Grid de opciones (Responsivo)
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Lógica de breakpoints para ajustar las columnas
                      int columns = 2;
                      if (constraints.maxWidth >= 800) {
                        columns = 4; // Pantallas grandes (Desktop/Web)
                      } else if (constraints.maxWidth >= 600) {
                        columns = 3; // Tablets
                      }

                      return GridView.count(
                        crossAxisCount: columns,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        // Ajustamos la proporción de la tarjeta para que no sean cuadrados perfectos en web
                        childAspectRatio: columns >= 3 ? 1.1 : 1.0, 
                        children: [
                          _buildCard(
                            context,
                            "NUEVA VENTA",
                            Icons.add_shopping_cart,
                            primaryNavy,
                            accentGold,
                            () => _navigateTo(context, const NewSaleScreen()),
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
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Navegación entre pantallas
  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  /// Tarjeta reutilizable del menú (Mejorada para Web con Hover)
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
        hoverColor: gold.withOpacity(0.05), // Efecto hover sutil para usar con mouse
        splashColor: gold.withOpacity(0.1),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: navy.withOpacity(0.08), // Sombra un poco más limpia
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: navy.withOpacity(0.03),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: gold),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.bold,
                    color: navy,
                    fontSize: 15,
                    letterSpacing: 1.2,
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