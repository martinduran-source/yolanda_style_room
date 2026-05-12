import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  final supabase = Supabase.instance.client;

  DatabaseHelper._init();

  /// ===========================================================
  /// LÓGICA DE INVENTARIO
  /// ===========================================================

  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    final response = await supabase
        .from('products')
        .select()
        .ilike('name', '%$query%')
        .eq('is_active', 1)
        .order('stock', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> insertProduct(
    String name,
    String category,
    double price,
    int stock,
  ) async {
    final cleanName = name.trim();

    // Buscar si existe
    final existing = await supabase
        .from('products')
        .select()
        .ilike('name', cleanName)
        .maybeSingle();

    if (existing != null) {
      // Actualizar si existe
      int id = existing['id'];
      int currentStock = existing['stock'];
      await supabase.from('products').update({
        'stock': currentStock + stock,
        'price': price,
        'is_active': 1
      }).eq('id', id);
    } else {
      // Insertar nuevo
      await supabase.from('products').insert({
        'name': cleanName,
        'category': category,
        'price': price,
        'stock': stock,
        'is_active': 1,
      });
    }
  }

  Future<int> updateProduct(
    int id,
    String name,
    String category,
    double price,
    int stock,
  ) async {
    await supabase.from('products').update({
      'name': name.trim(),
      'category': category,
      'price': price,
      'stock': stock,
      'is_active': 1,
    }).eq('id', id);
    return 1; // Retornamos 1 simulando el conteo de filas afectadas de sqflite
  }

  Future<void> decreaseStock(int productId, int quantityToRemove) async {
    // Obtenemos el stock actual
    final product = await supabase
        .from('products')
        .select('stock')
        .eq('id', productId)
        .single();
        
    int currentStock = product['stock'];
    int newStock = currentStock - quantityToRemove;
    if (newStock < 0) newStock = 0;

    await supabase.from('products').update({'stock': newStock}).eq('id', productId);
  }

  Future<int> deleteProduct(int id) async {
    await supabase.from('products').update({
      'is_active': 0,
      'stock': 0
    }).eq('id', id);
    return 1;
  }

  Future<int> markAsOutOfStock(int id) async {
    await supabase.from('products').update({'stock': 0}).eq('id', id);
    return 1;
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final response = await supabase
        .from('products')
        .select()
        .eq('is_active', 1)
        .order('name', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  /// ===========================================================
  /// VENTAS Y GRÁFICAS
  /// ===========================================================

  Future<void> processSale(
    List<Map<String, dynamic>> cart,
    double total,
  ) async {
    // 1. Crear la venta y obtener su ID
    final sale = await supabase.from('sales').insert({
      'date': DateTime.now().toIso8601String(),
      'total': total,
      'status': 'PAID',
      'item_count': cart.length,
    }).select('id').single();

    int saleId = sale['id'];

    // 2. Procesar cada item (insertar detalle y restar stock)
    for (var item in cart) {
      int productId = item['id'];
      int qty = item['qty'];

      // Validar stock actual
      final product = await supabase
          .from('products')
          .select('stock, name')
          .eq('id', productId)
          .single();

      if (product['stock'] >= qty) {
        // Insertar en sale_items
        await supabase.from('sale_items').insert({
          'sale_id': saleId,
          'product_id': productId,
          'quantity': qty,
          'price_at_sale': item['price'],
        });

        // Descontar stock
        await supabase
            .from('products')
            .update({'stock': product['stock'] - qty})
            .eq('id', productId);
      } else {
        throw Exception("Stock insuficiente para ${product['name']}");
      }
    }
  }

  /// ===========================================================
  /// HISTORIAL FILTRADO CON RELACIONES (JOINs en Supabase)
  /// ===========================================================

  Future<List<Map<String, dynamic>>> getFilteredSalesHistory(String filter) async {
    DateTime now = DateTime.now();
    DateTime startDate;

    if (filter == 'Día') {
      startDate = DateTime(now.year, now.month, now.day);
    } else if (filter == 'Semana') {
      startDate = now.subtract(const Duration(days: 7));
    } else { // Mes
      startDate = DateTime(now.year, now.month, 1);
    }

    // Supabase permite hacer JOINs directamente pidiendo las tablas relacionadas
    final response = await supabase
        .from('sales')
        .select('id, date, total, item_count, sale_items(quantity, products(name))')
        .gte('date', startDate.toIso8601String())
        .order('date', ascending: false);

    // Mapeamos la respuesta para que la UI siga recibiendo 'products_summary'
    List<Map<String, dynamic>> formattedHistory = [];

    for (var row in response) {
      List items = row['sale_items'] as List;
      
      // Recreamos el GROUP_CONCAT de SQLite
      String summary = items.map((item) {
        String pName = item['products']['name'];
        int qty = item['quantity'];
        return '$pName (x$qty)';
      }).join(', ');

      formattedHistory.add({
        'id': row['id'],
        'date': row['date'],
        'total': row['total'],
        'item_count': row['item_count'],
        'products_summary': summary,
      });
    }

    return formattedHistory;
  }

  // GRÁFICA: Agrupación procesada en Dart
  Future<List<FlSpot>> getSalesSpots(String filter) async {
    DateTime now = DateTime.now();
    DateTime startDate;

    if (filter == 'Día' || filter == 'Hoy') {
      startDate = DateTime(now.year, now.month, now.day);
    } else { // Mes
      startDate = DateTime(now.year, now.month, 1);
    }

    final response = await supabase
        .from('sales')
        .select('date, total') // Cambié COUNT por total de ganancias como sugerimos antes
        .gte('date', startDate.toIso8601String());

    Map<int, double> groupedData = {};

    for (var row in response) {
      DateTime date = DateTime.parse(row['date']).toLocal();
      double total = (row['total'] as num).toDouble();
      
      int key = (filter == 'Día' || filter == 'Hoy') ? date.hour : date.day;
      
      groupedData[key] = (groupedData[key] ?? 0.0) + total;
    }

    List<FlSpot> spots = [];
    groupedData.forEach((key, value) {
      spots.add(FlSpot(key.toDouble(), value));
    });

    // Ordenar de menor a mayor (horas o días)
    spots.sort((a, b) => a.x.compareTo(b.x));

    return spots;
  }
}