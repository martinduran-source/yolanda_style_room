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
    _initData();
  }

  Future<void> _initData() async {
    await loadSampleProducts();
    _refreshProducts();
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
      // Mejora: Cierra el teclado al tocar fuera de un TextField
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: primaryNavy,
        // Mejora: Evita que el teclado empuje y deforme el diseño
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            "NUEVA VENTA",
            style: GoogleFonts.oswald(color: Colors.white),
          ),
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: lightBeige,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
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
              _buildAvailableProductsList(),
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
              // El carrito ocupa el espacio flexible central
              Expanded(child: _buildCartList()),
              _buildCheckoutSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableProductsList() {
    return SizedBox(
      height: 125,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _availableProducts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No hay productos disponibles"));
          }
          final products = snapshot.data!;
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final p = products[index];
              final bool hasStock = (p['stock'] ?? 0) > 0;

              return GestureDetector(
                onTap: () => _addProductToCart(p),
                child: Opacity(
                  // Mejora: Se ve opaco si no hay stock
                  opacity: hasStock ? 1.0 : 0.5,
                  child: Container(
                    width: 105,
                    margin: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2,
                          color: hasStock ? accentGold : Colors.grey,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            p['name'],
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          "\$${p['price']}",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          "Stock: ${p['stock']}",
                          style: TextStyle(
                            fontSize: 10,
                            color: hasStock ? Colors.black54 : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
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

  Widget _buildCartList() {
    if (cartItems.isEmpty) {
      return Center(
        child: Text(
          "El carrito está vacío",
          style: TextStyle(color: primaryNavy.withOpacity(0.5)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: cartItems.length,
      itemBuilder: (context, index) {
        final item = cartItems[index];
        final bool canAddMore = item['qty'] < item['maxStock'];

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            title: Text(
              item['name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("\$${item['price'].toStringAsFixed(2)} c/u"),
            trailing: SizedBox(
              width: 130,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.redAccent,
                    ),
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
                  Text(
                    "${item['qty']}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: canAddMore ? Colors.green : Colors.grey,
                    ),
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
          ),
        );
      },
    );
  }

  Widget _buildCheckoutSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("TOTAL", style: GoogleFonts.oswald(fontSize: 20)),
              Text(
                "\$${totalSale.toStringAsFixed(2)}",
                style: GoogleFonts.oswald(
                  fontSize: 24,
                  color: accentGold,
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
                backgroundColor: primaryNavy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: cartItems.isEmpty
                  ? null
                  : () async {
                      try {
                        await DatabaseHelper.instance.processSale(
                          cartItems,
                          totalSale,
                        );
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("¡Venta completada!")),
                          );
                        }
                      } catch (e) {
                        _showWarning(e.toString());
                      }
                    },
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

// FUNCIÓN DE CARGA DE DATOS CORREGIDA
Future<void> loadSampleProducts() async {
  final db = DatabaseHelper.instance;

  // 1. Verificamos si ya existen productos en la base de datos
  final existingProducts = await db.getProducts();

  // 2. Si la lista NO está vacía, salimos de la función para no duplicar datos
  if (existingProducts.isNotEmpty) {
    return;
  }

  final List<Map<String, dynamic>> sampleProducts = [
    {
      'name': 'Vestido Seda Rojo',
      'cat': 'Vestidos',
      'price': 150.0,
      'stock': 15,
    },
    {
      'name': 'Pantalón Jean Clásico',
      'cat': 'Pantalones',
      'price': 45.0,
      'stock': 20,
    },
    {
      'name': 'Blusa Encaje Blanca',
      'cat': 'Blusas',
      'price': 35.0,
      'stock': 12,
    },
    {
      'name': 'Chaqueta Cuero Negra',
      'cat': 'Abrigos',
      'price': 85.0,
      'stock': 5,
    },
    {
      'name': 'Falda Plisada Beige',
      'cat': 'Faldas',
      'price': 40.0,
      'stock': 10,
    },
    {
      'name': 'Top Deportivo Neon',
      'cat': 'Deportiva',
      'price': 25.0,
      'stock': 2,
    },
    {
      'name': 'Vestido Cóctel Negro',
      'cat': 'Vestidos',
      'price': 120.0,
      'stock': 1,
    },
    {
      'name': 'Cinturón Oro Rosa',
      'cat': 'Accesorios',
      'price': 15.0,
      'stock': 3, // El culpable de los "3" productos fantasma
    },
    {
      'name': 'Bufanda Cachemira',
      'cat': 'Accesorios',
      'price': 30.0,
      'stock': 0,
    },
    {'name': 'Sandalias Verano', 'cat': 'Calzado', 'price': 28.0, 'stock': 0},
    {
      'name': 'Camiseta Algodón XL',
      'cat': 'Básicos',
      'price': 18.0,
      'stock': 25,
    },
    {
      'name': 'Short Mezclilla',
      'cat': 'Pantalones',
      'price': 32.0,
      'stock': 14,
    },
    {'name': 'Suéter Lana Gris', 'cat': 'Abrigos', 'price': 55.0, 'stock': 8},
    {
      'name': 'Vestido Playero Azul',
      'cat': 'Vestidos',
      'price': 65.0,
      'stock': 11,
    },
    {
      'name': 'Gorra Bordada Style',
      'cat': 'Accesorios',
      'price': 20.0,
      'stock': 7,
    },
    {
      'name': 'Leggins High Waist',
      'cat': 'Deportiva',
      'price': 38.0,
      'stock': 18,
    },
    {
      'name': 'Cardigan Largo Rosa',
      'cat': 'Abrigos',
      'price': 48.0,
      'stock': 9,
    },
  ];

  for (var p in sampleProducts) {
    await db.insertProduct(
      p['name'],
      p['cat'],
      (p['price'] as num).toDouble(),
      p['stock'],
    );
  }
}
