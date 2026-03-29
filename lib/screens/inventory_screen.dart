import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database_helper.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final Color primaryNavy = const Color(0xFF2C3E50);
  final Color accentGold = const Color(0xFFB89352);
  final Color lightBeige = const Color(0xFFF9F5F0);

  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryNavy,
      appBar: AppBar(
        backgroundColor: primaryNavy,
        elevation: 0,
        title: Text(
          "INVENTARIO",
          style: GoogleFonts.oswald(color: Colors.white, letterSpacing: 1.5),
        ),
        iconTheme: IconThemeData(color: accentGold),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showAddProductDialog(),
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
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: DatabaseHelper.instance.searchProducts(_searchQuery),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? "Sin productos"
                            : "Sin resultados",
                        style: TextStyle(color: primaryNavy.withOpacity(0.5)),
                      ),
                    );
                  }
                  final products = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: products.length,
                    itemBuilder: (context, i) {
                      final p = products[i];
                      return Card(
                        child: ListTile(
                          title: Text(p['name'] ?? 'Sin nombre'),
                          subtitle: Text("Stock: ${p['stock'] ?? 0}"),
                          trailing: Text("\$${p['price'] ?? 0}"),
                        ),
                      );
                    },
                  );
                },
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
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: "Buscar productos...",
          prefixIcon: Icon(Icons.search, color: accentGold),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Agregar producto"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Nombre"),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: "Precio"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: stockController,
              decoration: const InputDecoration(labelText: "Stock"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.instance.insertProduct(
                nameController.text,
                "General", // categoría por defecto
                double.tryParse(priceController.text) ?? 0.0,
                int.tryParse(stockController.text) ?? 0,
              );
              Navigator.pop(context);
              setState(() {}); // refresca la lista
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }
}
