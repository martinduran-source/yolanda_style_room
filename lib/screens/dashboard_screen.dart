import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yolanda_style_room/screens/sales_chart_screen.dart';

class DashboardScreen extends StatelessWidget {
  // Paleta de colores consistente con la marca
  final Color primaryNavy = const Color(0xFF2C3E50);
  final Color accentGold = const Color(0xFFB89352);
  final Color lightBeige = const Color(0xFFF9F5F0);
  final Color cardNavy = const Color(0xFF34495E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryNavy,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "HOME / DASHBOARD",
                        style: GoogleFonts.oswald(
                          fontSize: 22,
                          color: primaryNavy,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Tarjetas de Resumen (Ventas e Inventario)
                      Row(
                        children: [
                          _buildSummaryCard(
                            "TOTAL SALES THIS MONTH",
                            "\$15,840.00",
                            Icons.bar_chart,
                            Colors.white,
                            Colors.black,
                          ),
                          const SizedBox(width: 10),
                          _buildSummaryCard(
                            "ITEMS IN STOCK",
                            "345",
                            Icons.checkroom,
                            Colors.white,
                            Colors.black,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Botones de Acción (Grid)
                      Row(
                        children: [
                          _buildActionButton(
                            "NEW SALE",
                            Icons.add,
                            accentGold,
                            flex: 1,
                          ),
                          const SizedBox(width: 10),
                          _buildActionButton(
                            "INVENTARIO",
                            Icons.grid_view,
                            cardNavy,
                            flex: 1,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          // Ejemplo de cómo conectar el botón a la pantalla de la gráfica
                          _buildActionButton(
                            "SALES CHART",
                            Icons.show_chart,
                            cardNavy,
                            flex: 1,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SalesChartScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 10),
                          _buildActionButton(
                            "HISTORY",
                            Icons.history,
                            cardNavy,
                            flex: 1,
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),
                      Text(
                        "RECENT SALES ACTIVITY",
                        style: GoogleFonts.oswald(
                          fontSize: 18,
                          color: primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Lista de Actividad Reciente
                      _buildRecentSale(
                        "#1488",
                        "10 min ago",
                        "Blazer, Heels",
                        "\$185.00",
                      ),
                      _buildRecentSale(
                        "#1487",
                        "1 hr ago",
                        "Dress, Belt",
                        "\$210.00",
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // --- Widgets de Componentes ---

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Yolanda's Style Room",
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "Created 07/02/2026",
                style: TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "INICIO",
                style: TextStyle(color: Color(0xFFB89352), fontSize: 10),
              ),
              Text(
                "Roberto Hernández",
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color bg,
    Color textCol,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textCol,
                    ),
                  ),
                ),
                Icon(icon, color: accentGold, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Añadimos 'VoidCallback? onTap' como parámetro
  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color, {
    required int flex,
    VoidCallback? onTap,
  }) {
    return Expanded(
      flex: flex,
      child: InkWell(
        // Usamos InkWell para detectar el toque y dar efecto visual
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 30),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSale(String id, String time, String items, String price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.sell, color: accentGold, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Sale $id ($time):",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  items,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      backgroundColor: primaryNavy,
      selectedItemColor: accentGold,
      unselectedItemColor: Colors.white54,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2),
          label: 'Inventory',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Charts'),
        BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Sales'),
      ],
    );
  }
}
