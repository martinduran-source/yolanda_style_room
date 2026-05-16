import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/database_helper.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final Color primaryNavy = const Color(0xFF2C3E50);
  final Color accentGold = const Color(0xFFB89352);
  final Color lightBeige = const Color(0xFFF9F5F0);

  List<Map<String, dynamic>> cartItems = [];
  double totalSale = 0.0;
  final TextEditingController _searchController = TextEditingController();

  late Future<List<Map<String, dynamic>>> _availableProducts;

  @override
  void initState() {
    super.initState();
    _availableProducts = DatabaseHelper.instance.getProducts();
  }



  void _refreshProducts() {
    if (mounted) {
      setState(() {
        _availableProducts = DatabaseHelper.instance.getProducts();
      });
    }
  }

  void _calculateTotal() {
    double tempTotal = 0;
    for (var item in cartItems) {
      tempTotal += (item['price'] * item['qty']);
    }
    setState(() => totalSale = tempTotal);
  }

  void _addProductToCart(Map<String, dynamic> product) {
    setState(() {
      int index = cartItems.indexWhere((item) => item['id'] == product['id']);
      int currentStock = product['stock'] ?? 0;

      if (currentStock <= 0) {
        _showWarning("El producto '${product['name']}' está agotado.");
        return;
      }

      if (index >= 0) {
        if (cartItems[index]['qty'] < currentStock) {
          cartItems[index]['qty'] += 1;
        } else {
          _showWarning("Límite de stock alcanzado (${product['name']})");
        }
      } else {
        cartItems.add({
          'id': product['id'],
          'name': product['name'],
          'price': (product['price'] as num).toDouble(),
          'qty': 1,
          'maxStock': currentStock,
        });
      }
      _calculateTotal();
    });
  }

  void _showWarning(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange[800],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: primaryNavy,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            "PUNTO DE VENTA",
            style: GoogleFonts.oswald(color: Colors.white, letterSpacing: 1.5),
          ),
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: lightBeige,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // LÓGICA RESPONSIVA: Si la pantalla es ancha (Web/Desktop), usa pantalla dividida.
              if (constraints.maxWidth >= 800) {
                return _buildWebLayout();
              } else {
                return _buildMobileLayout();
              }
            },
          ),
        ),
      ),
    );
  }

  // ========================================================
  // LAYOUT PARA WEB Y DESKTOP (Pantalla Dividida)
  // ========================================================
  Widget _buildWebLayout() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PANEL IZQUIERDO: Búsqueda y Cuadrícula de Productos
          Expanded(
            flex: 6, // Ocupa el 60% de la pantalla
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(),
                const SizedBox(height: 15),
                Text(
                  "Catálogo de Productos",
                  style: GoogleFonts.oswald(fontSize: 20, color: primaryNavy),
                ),
                const SizedBox(height: 10),
                Expanded(child: _buildProductsView(isWeb: true)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          
          // PANEL DERECHO: Carrito de Compras
          Expanded(
            flex: 4, // Ocupa el 40% de la pantalla
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(Icons.shopping_cart_outlined, color: primaryNavy),
                        const SizedBox(width: 10),
                        Text(
                          "CARRITO",
                          style: GoogleFonts.oswald(fontSize: 20, color: primaryNavy),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(child: _buildCartList()),
                  _buildCheckoutSection(isWeb: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // LAYOUT PARA MÓVIL (El diseño original adaptado)
  // ========================================================
  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildSearchBar(),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Selección rápida",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        SizedBox(
          height: 140,
          child: _buildProductsView(isWeb: false),
        ),
        const Divider(),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Carrito",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        Expanded(child: _buildCartList()),
        _buildCheckoutSection(isWeb: false),
      ],
    );
  }

  // ========================================================
  // COMPONENTES REUTILIZABLES
  // ========================================================
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(20).copyWith(bottom: 0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _availableProducts = DatabaseHelper.instance.searchProducts(value);
          });
        },
        decoration: InputDecoration(
          hintText: "Buscar producto específico...",
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

  // Lista/Cuadrícula de productos adaptativa
  Widget _buildProductsView({required bool isWeb}) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _availableProducts,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No hay productos disponibles"));
        }
        final products = snapshot.data!;

        // Si es Web, mostramos una cuadrícula bonita. Si es móvil, la lista horizontal.
        if (isWeb) {
          return GridView.builder(
            padding: const EdgeInsets.only(bottom: 20),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180, // Ancho máximo de la tarjeta
              childAspectRatio: 0.85,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) => _buildProductCard(products[index]),
          );
        } else {
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: products.length,
            itemBuilder: (context, index) => _buildProductCard(products[index], isMobileCard: true),
          );
        }
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> p, {bool isMobileCard = false}) {
    final bool hasStock = (p['stock'] ?? 0) > 0;

    return GestureDetector(
      onTap: () => _addProductToCart(p),
      child: Opacity(
        opacity: hasStock ? 1.0 : 0.5,
        child: Container(
          width: isMobileCard ? 110 : null,
          margin: isMobileCard ? const EdgeInsets.all(5) : null,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: primaryNavy.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(color: primaryNavy.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hasStock ? primaryNavy.withOpacity(0.05) : Colors.red.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.inventory_2,
                  color: hasStock ? accentGold : Colors.redAccent,
                  size: isMobileCard ? 24 : 32,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  p['name'],
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, height: 1.1),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "\$${p['price']}",
                style: TextStyle(fontSize: 13, color: primaryNavy, fontWeight: FontWeight.w600),
              ),
              Text(
                hasStock ? "Stock: ${p['stock']}" : "AGOTADO",
                style: TextStyle(
                  fontSize: 11,
                  color: hasStock ? Colors.black54 : Colors.red,
                  fontWeight: hasStock ? FontWeight.normal : FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartList() {
    if (cartItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_checkout, size: 60, color: primaryNavy.withOpacity(0.2)),
            const SizedBox(height: 10),
            Text(
              "El carrito está vacío",
              style: TextStyle(color: primaryNavy.withOpacity(0.5)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      itemCount: cartItems.length,
      itemBuilder: (context, index) {
        final item = cartItems[index];
        final bool canAddMore = item['qty'] < item['maxStock'];

        return Card(
          elevation: 0,
          color: primaryNavy.withOpacity(0.03),
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text("\$${item['price'].toStringAsFixed(2)} c/u"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                  onPressed: () {
                    setState(() {
                      if (item['qty'] > 1) {
                        item['qty'] -= 1;
                      } else {
                        cartItems.removeAt(index);
                      }
                      _calculateTotal();
                    });
                  },
                ),
                SizedBox(
                  width: 20,
                  child: Text(
                    "${item['qty']}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle_outline, color: canAddMore ? Colors.green : Colors.grey),
                  onPressed: !canAddMore
                      ? () => _showWarning("Stock máximo alcanzado")
                      : () {
                          setState(() {
                            item['qty'] += 1;
                            _calculateTotal();
                          });
                        },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCheckoutSection({required bool isWeb}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isWeb ? Colors.transparent : Colors.white,
        borderRadius: isWeb ? null : const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: isWeb ? null : [const BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("TOTAL", style: GoogleFonts.oswald(fontSize: 22, color: primaryNavy)),
              Text(
                "\$${totalSale.toStringAsFixed(2)}",
                style: GoogleFonts.oswald(
                  fontSize: 28,
                  color: accentGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryNavy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: cartItems.isEmpty ? null : _procesarVenta,
              child: const Text(
                "COMPLETAR VENTA",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Lógica de Supabase migrada de tu código anterior ---
  Future<void> _procesarVenta() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      await DatabaseHelper.instance.processSale(cartItems, totalSale);

      if (mounted) {
        Navigator.pop(context); // Cierra loading
        setState(() {
          cartItems.clear();
          totalSale = 0.0;
        });
        _refreshProducts(); // Actualiza el stock visualmente
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Venta registrada con éxito!")),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cierra loading
        _showWarning(e.toString());
      }
    }
  }
}

