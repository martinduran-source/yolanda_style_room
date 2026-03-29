import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database_helper.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  _NewSaleScreenState createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final Color primaryNavy = const Color(0xFF2C3E50);
  final Color accentGold = const Color(0xFFB89352);
  final Color lightBeige = const Color(0xFFF9F5F0);

  List<Map<String, dynamic>> cartItems = [];
  double totalSale = 0.0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    double tempTotal = 0;
    for (var item in cartItems) {
      tempTotal += (item['price'] * item['qty']);
    }
    setState(() => totalSale = tempTotal);
  }

  Future<void> _searchAndAddProduct(String query) async {
    if (query.trim().isEmpty) return;

    try {
      final products = await DatabaseHelper.instance.searchProducts(query);
      if (products.isNotEmpty) {
        _addProductToCart(products.first);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("No se encontró '$query'"),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _addProductToCart(Map<String, dynamic> product) {
    setState(() {
      int index = cartItems.indexWhere((item) => item['id'] == product['id']);
      if (index >= 0) {
        var updatedItem = Map<String, dynamic>.from(cartItems[index]);
        updatedItem['qty'] += 1;
        cartItems[index] = updatedItem;
      } else {
        cartItems.add({
          'id': product['id'],
          'name': product['name'] ?? 'Producto sin nombre',
          'price': (product['price'] as num?)?.toDouble() ?? 0.0,
          'qty': 1,
        });
      }
      _calculateTotal();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "NUEVA VENTA",
          style: GoogleFonts.oswald(color: Colors.white, letterSpacing: 1.5),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildCustomerInfo(),
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
              child: Column(
                children: [
                  _buildSearchBar(),
                  Expanded(child: _buildCartList()),
                  _buildCheckoutSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: accentGold,
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 15),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Cliente Walk-in",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Tarifa estándar",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Buscar productos (ej: Vestido, Blusa)...",
          prefixIcon: Icon(Icons.search, color: primaryNavy),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => _searchController.clear(),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
        onSubmitted: _searchAndAddProduct,
      ),
    );
  }

  Widget _buildCartList() {
    if (cartItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: primaryNavy.withOpacity(0.3),
            ),
            Text(
              "Carrito vacío",
              style: TextStyle(color: primaryNavy.withOpacity(0.5)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: cartItems.length,
      itemBuilder: (context, index) {
        final item = cartItems[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            title: Text(
              item['name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("\$${item['price'].toStringAsFixed(2)} c/u"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.red,
                  ),
                  onPressed: () {
                    setState(() {
                      if (item['qty'] > 1) {
                        item['qty']--;
                      } else {
                        cartItems.removeAt(index);
                      }
                      _calculateTotal();
                    });
                  },
                ),
                Text(
                  "${item['qty']}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.green,
                  ),
                  onPressed: () {
                    setState(() {
                      item['qty']++;
                      _calculateTotal();
                    });
                  },
                ),
                Text(
                  "\$${(item['price'] * item['qty']).toStringAsFixed(2)}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCheckoutSection() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "TOTAL",
                style: GoogleFonts.oswald(fontSize: 20, color: primaryNavy),
              ),
              Text(
                "\$${totalSale.toStringAsFixed(2)}",
                style: GoogleFonts.oswald(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: accentGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: cartItems.isEmpty
                  ? null
                  : () async {
                      try {
                        await DatabaseHelper.instance.processSale(
                          cartItems,
                          totalSale,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "¡Venta completada! Stock actualizado.",
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Error: $e"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryNavy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                "COMPLETAR VENTA",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
