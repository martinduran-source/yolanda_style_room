import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InventoryScreen extends StatelessWidget {
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
          "INVENTORY",
          style: GoogleFonts.oswald(color: Colors.white, letterSpacing: 1.5),
        ),
        iconTheme: IconThemeData(color: accentGold),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              // Lógica para agregar nuevo producto
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
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
                    _buildInventoryStats(),
                    const SizedBox(height: 20),
                    Text(
                      "PRODUCT LIST",
                      style: GoogleFonts.oswald(
                        fontSize: 18,
                        color: primaryNavy,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Ejemplos de productos
                    _buildProductItem(
                      "Silk Evening Dress",
                      "Dresses",
                      12,
                      150.00,
                    ),
                    _buildProductItem(
                      "Leather High Heels",
                      "Shoes",
                      5,
                      85.00,
                      lowStock: true,
                    ),
                    _buildProductItem(
                      "Classic Navy Blazer",
                      "Outwear",
                      24,
                      120.00,
                    ),
                    _buildProductItem(
                      "Golden Accessories Set",
                      "Jewelry",
                      0,
                      45.00,
                      outOfStock: true,
                    ),
                    _buildProductItem("Casual Linen Pants", "Pants", 18, 65.00),
                    _buildProductItem("Velvet Clutch", "Bags", 8, 55.00),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Search products...",
          hintStyle: const TextStyle(color: Colors.white54),
          prefixIcon: Icon(Icons.search, color: accentGold),
          filled: true,
          fillColor: cardNavy,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryStats() {
    return Row(
      children: [
        _buildStatTile("In Stock", "345", Icons.inventory),
        const SizedBox(width: 10),
        _buildStatTile(
          "Low Stock",
          "3",
          Icons.warning_amber_rounded,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatTile(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? accentGold, size: 24),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(
    String name,
    String category,
    int stock,
    double price, {
    bool lowStock = false,
    bool outOfStock = false,
  }) {
    Color stockColor = outOfStock
        ? Colors.red
        : (lowStock ? Colors.orange : Colors.green);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          // Placeholder para imagen del producto
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: lightBeige,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.image, color: accentGold.withOpacity(0.5)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  category,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "\$${price.toStringAsFixed(2)}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryNavy,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: stockColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  outOfStock ? "Out of stock" : "$stock in stock",
                  style: TextStyle(
                    color: stockColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
