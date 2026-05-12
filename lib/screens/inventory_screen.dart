import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart'; // Importamos el nuevo servicio

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final Color primaryNavy = const Color(0xFF2C3E50);
  final Color accentGold = const Color(0xFFB89352);
  final Color lightBeige = const Color(0xFFF9F5F0);

  // Instanciamos el servicio de Supabase
  final SupabaseService _supabaseService = SupabaseService();
  String _searchQuery = '';

  void _refresh() {
    setState(() {});
  }

  // --- MÉTODO PARA ELIMINAR PRODUCTO (SUPABASE) ---
  void _deleteProduct(int id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "¿Eliminar producto?",
          style: GoogleFonts.oswald(color: Colors.red),
        ),
        content: Text("¿Estás seguro de que deseas eliminar '$name'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              // Llamada a Supabase
              await _supabaseService.eliminarRegistro('productos', id);
              if (mounted) {
                Navigator.pop(context);
                _refresh();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Producto eliminado de la nube"),
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

  // --- MÉTODO PARA EDITAR PRODUCTO (SUPABASE) ---
  void _showEditProductDialog(Map<String, dynamic> product) {
    final nameController = TextEditingController(text: product['name']);
    final priceController = TextEditingController(
      text: product['price'].toString(),
    );
    final stockController = TextEditingController(
      text: product['stock'].toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Editar Producto",
          style: GoogleFonts.oswald(color: primaryNavy),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Nombre"),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: "Precio",
                  prefixText: "\$ ",
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: stockController,
                decoration: const InputDecoration(labelText: "Stock Actual"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCELAR"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryNavy),
            onPressed: () async {
              // Actualización en Supabase
              await _supabaseService.actualizarProducto(product['id'], {
                'name': nameController.text,
                'price': double.tryParse(priceController.text) ?? 0.0,
                'stock': int.tryParse(stockController.text) ?? 0,
              });
              if (mounted) {
                Navigator.pop(context);
                _refresh();
              }
            },
            child: const Text("GUARDAR", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- MÉTODO PARA AÑADIR PRODUCTO (SUPABASE) ---
  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Nuevo Producto", style: GoogleFonts.oswald()),
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
              decoration: const InputDecoration(labelText: "Stock inicial"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryNavy),
            onPressed: () async {
              // Inserción en Supabase
              await _supabaseService.insertarRegistro('productos', {
                'name': nameController.text,
                'price': double.tryParse(priceController.text) ?? 0,
                'stock': int.tryParse(stockController.text) ?? 0,
                'category': 'General',
              });
              Navigator.pop(context);
              _refresh();
            },
            child: const Text("Guardar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryNavy,
      appBar: AppBar(
        backgroundColor: primaryNavy,
        elevation: 0,
        iconTheme: IconThemeData(color: accentGold),
        title: Text(
          "INVENTARIO WEB",
          style: GoogleFonts.oswald(color: Colors.white, letterSpacing: 1.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _showAddProductDialog,
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
                // Usamos el servicio de Supabase para buscar
                future: _supabaseService.getProductos(_searchQuery),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        "Sin productos en la nube",
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
                      final int stock = p['stock'] ?? 0;
                      final bool isOutOfStock = stock <= 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          leading: Icon(Icons.inventory_2, color: accentGold),
                          title: Text(
                            p['name'] ?? 'Sin nombre',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            isOutOfStock
                                ? "FUERA DE STOCK"
                                : "Stock: $stock | Precio: \$${p['price']}",
                            style: TextStyle(
                              color: isOutOfStock ? Colors.red : Colors.black54,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit_note, color: accentGold),
                                onPressed: () => _showEditProductDialog(p),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_sweep_outlined,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () =>
                                    _deleteProduct(p['id'], p['name']),
                              ),
                            ],
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: "Buscar en Supabase...",
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
}
