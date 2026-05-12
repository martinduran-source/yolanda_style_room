import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final Color primaryNavy = const Color(0xFF2C3E50);
  final Color accentGold = const Color(0xFFB89352);
  final Color lightBeige = const Color(0xFFF9F5F0);

  final SupabaseService _supabaseService = SupabaseService();
  String _searchQuery = '';

  // --- ESTADO DEL CARRITO ---
  final List<Map<String, dynamic>> _cart = [];

  void _refresh() {
    if (mounted) setState(() {});
  }

  double _calculateTotal() {
    return _cart.fold(0, (sum, item) => sum + (item['price'] * item['qty']));
  }

  // --- LÓGICA DE VENTA ---

  void _addToCart(Map<String, dynamic> product) {
    final qtyController = TextEditingController(text: "1");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Cantidad para ${product['name']}",
          style: GoogleFonts.oswald(),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Stock disponible: ${product['stock']}"),
            const SizedBox(height: 10),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Cantidad",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCELAR"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryNavy),
            onPressed: () {
              int qty = int.tryParse(qtyController.text) ?? 0;
              if (qty > 0 && qty <= product['stock']) {
                setState(() {
                  // Si ya existe en el carrito, sumamos la cantidad
                  int index = _cart.indexWhere(
                    (item) => item['id'] == product['id'],
                  );
                  if (index >= 0) {
                    _cart[index]['qty'] += qty;
                  } else {
                    _cart.add({
                      'id': product['id'],
                      'name': product['name'],
                      'price': product['price'],
                      'qty': qty,
                    });
                  }
                });
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Cantidad no válida o excede el stock"),
                  ),
                );
              }
            },
            child: const Text("AGREGAR", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _processSale() async {
    if (_cart.isEmpty) return;

    try {
      await _supabaseService.realizarVentaCompleta(
        carrito: _cart,
        total: _calculateTotal(),
      );

      if (!mounted) return;

      setState(() => _cart.clear());
      _refresh();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("¡Venta realizada con éxito!"),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text("Error: $e")),
      );
    }
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
          "NUEVA VENTA",
          style: GoogleFonts.oswald(color: Colors.white, letterSpacing: 1.5),
        ),
        actions: [
          // Botón para ver/limpiar carrito rápido
          if (_cart.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
              onPressed: () => setState(() => _cart.clear()),
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
                future: _supabaseService.getProductos(_searchQuery),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        "Sin productos",
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
                          onTap: isOutOfStock ? null : () => _addToCart(p),
                          leading: Icon(
                            Icons.add_shopping_cart,
                            color: isOutOfStock ? Colors.grey : accentGold,
                          ),
                          title: Text(
                            p['name'] ?? 'Sin nombre',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            isOutOfStock
                                ? "SIN STOCK"
                                : "Stock: $stock | \$${p['price']}",
                            style: TextStyle(
                              color: isOutOfStock ? Colors.red : Colors.black54,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right),
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
      // --- PANEL INFERIOR DE COBRO ---
      bottomNavigationBar: _cart.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Items: ${_cart.length}",
                          style: GoogleFonts.lato(fontSize: 16),
                        ),
                        Text(
                          "Total: \$${_calculateTotal().toStringAsFixed(2)}",
                          style: GoogleFonts.oswald(
                            fontSize: 22,
                            color: primaryNavy,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentGold,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: _processSale,
                        child: Text(
                          "FINALIZAR VENTA",
                          style: GoogleFonts.oswald(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: "Buscar producto para vender...",
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
