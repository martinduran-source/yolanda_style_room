import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database_helper.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  // ======================
  // COLORES
  // ======================
  final Color primaryNavy = const Color(0xFF2C3E50);
  final Color accentGold = const Color(0xFFB89352);
  final Color lightBeige = const Color(0xFFF9F5F0);

  // ======================
  // VARIABLES
  // ======================
  List<Map<String, dynamic>> cartItems = [];
  double totalSale = 0.0;

  final TextEditingController _searchController =
      TextEditingController();

  // ======================
  // CALCULAR TOTAL
  // ======================
  void _calculateTotal() {
    double tempTotal = 0;

    for (var item in cartItems) {
      tempTotal += (item['price'] * item['qty']);
    }

    setState(() => totalSale = tempTotal);
  }

  // ======================
  // BUSCAR PRODUCTO
  // ======================
  Future<void> _searchAndAddProduct(String query) async {
    if (query.trim().isEmpty) return;

    final products =
        await DatabaseHelper.instance.searchProducts(query);

    if (products.isNotEmpty) {
      _addProductToCart(products.first);
      _searchController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No se encontró '$query'"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // ======================
  // AGREGAR AL CARRITO
  // ======================
  void _addProductToCart(Map<String, dynamic> product) {
    setState(() {
      int index = cartItems.indexWhere(
        (item) => item['id'] == product['id'],
      );

      if (index >= 0) {
        cartItems[index]['qty'] += 1;
      } else {
        cartItems.add({
          'id': product['id'],
          'name': product['name'],
          'price': (product['price'] as num).toDouble(),
          'qty': 1,
        });
      }

      _calculateTotal();
    });
  }

  // ======================
  // UI PRINCIPAL
  // ======================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryNavy,

      /// APP BAR
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "NUEVA VENTA",
          style: GoogleFonts.oswald(color: Colors.white),
        ),
      ),

      /// BODY
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF9F5F0),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30),
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

  // ======================
  // SEARCH BAR
  // ======================
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: TextField(
        controller: _searchController,
        onSubmitted: _searchAndAddProduct,
        decoration: InputDecoration(
          hintText: "Buscar producto...",
          prefixIcon: Icon(Icons.search, color: primaryNavy),
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

  // ======================
  // LISTA DEL CARRITO
  // ======================
  Widget _buildCartList() {
    if (cartItems.isEmpty) {
      return const Center(child: Text("Carrito vacío"));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: cartItems.length,
      itemBuilder: (context, index) {
        final item = cartItems[index];

        return Card(
          child: ListTile(
            title: Text(
              item['name'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle:
                Text("\$${item['price']} x ${item['qty']}"),
            trailing: IconButton(
              icon: const Icon(
                Icons.delete,
                color: Colors.red,
              ),
              onPressed: () {
                setState(() {
                  cartItems.removeAt(index);
                  _calculateTotal();
                });
              },
            ),
          ),
        );
      },
    );
  }

  // ======================
  // CHECKOUT
  // ======================
  Widget _buildCheckoutSection() {
    return Container(
      padding: const EdgeInsets.all(25),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "TOTAL",
                style: GoogleFonts.oswald(fontSize: 20),
              ),
              Text(
                "\$${totalSale.toStringAsFixed(2)}",
                style: GoogleFonts.oswald(
                  fontSize: 24,
                  color: accentGold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryNavy,
              ),
              onPressed: cartItems.isEmpty
                  ? null
                  : () async {
                      await DatabaseHelper.instance
                          .processSale(
                        cartItems,
                        totalSale,
                      );

                      Navigator.pop(context);
                    },
              child: const Text(
                "COMPLETAR VENTA",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}