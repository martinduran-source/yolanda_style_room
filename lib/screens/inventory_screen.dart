import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database_helper.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  // =====================
  // COLORES
  // =====================
  final Color primaryNavy = const Color(0xFF2C3E50);
  final Color accentGold = const Color(0xFFB89352);
  final Color lightBeige = const Color(0xFFF9F5F0);

  String _searchQuery = '';

  // =====================
  // UI PRINCIPAL
  // =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryNavy,

      /// APP BAR
      appBar: AppBar(
        backgroundColor: primaryNavy,
        elevation: 0,
        iconTheme: IconThemeData(color: accentGold),
        title: Text(
          "INVENTARIO",
          style: GoogleFonts.oswald(
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _showAddProductDialog,
          ),
        ],
      ),

      /// BODY
      body: Column(
        children: [
          _buildSearchBar(),

          /// LISTA DE PRODUCTOS
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF9F5F0),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future:
                    DatabaseHelper.instance.searchProducts(_searchQuery),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? "Sin productos"
                            : "Sin resultados",
                        style: TextStyle(
                          color: primaryNavy.withOpacity(0.5),
                        ),
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
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 5,
                          ),
                          title: Text(
                            p['name'] ?? 'Sin nombre',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            "Stock: ${p['stock'] ?? 0} | "
                            "Precio: \$${p['price'] ?? 0}",
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_forever,
                              color: Colors.redAccent,
                              size: 28,
                            ),
                            onPressed: () => _showDeleteDialog(
                              p['id'],
                              p['name'],
                            ),
                          ),
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

  // =====================
  // BARRA DE BÚSQUEDA
  // =====================
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: TextField(
        onChanged: (value) =>
            setState(() => _searchQuery = value),
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

  // =====================
  // ELIMINAR PRODUCTO
  // =====================
  void _showDeleteDialog(int? id, String? name) {
    if (id == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text("¿Eliminar producto?"),
        content: Text(
          "Estás a punto de borrar '$name'. "
          "Esta acción no se puede deshacer.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "CANCELAR",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              await DatabaseHelper.instance.deleteProduct(id);

              Navigator.pop(context);
              setState(() {});

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("'$name' ha sido eliminado"),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text(
              "ELIMINAR",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // =====================
  // AGREGAR PRODUCTO
  // =====================
  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Nuevo Producto"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration:
                  const InputDecoration(labelText: "Nombre"),
            ),
            TextField(
              controller: priceController,
              decoration:
                  const InputDecoration(labelText: "Precio"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: stockController,
              decoration:
                  const InputDecoration(labelText: "Stock"),
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
              if (nameController.text.isNotEmpty) {
                await DatabaseHelper.instance.insertProduct(
                  nameController.text,
                  "General",
                  double.tryParse(priceController.text) ?? 0.0,
                  int.tryParse(stockController.text) ?? 0,
                );

                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }
}