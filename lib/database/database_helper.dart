import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:fl_chart/fl_chart.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('yolanda_style.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      category TEXT NOT NULL,
      price REAL NOT NULL,
      stock INTEGER NOT NULL,
      is_active INTEGER NOT NULL DEFAULT 1
    )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        total REAL NOT NULL,
        status TEXT NOT NULL,
        item_count INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        price_at_sale REAL NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');

    await _insertMockData(db);
  }

  Future<void> _insertMockData(Database db) async {
    await db.insert('products', {
      'name': 'Silk Evening Dress',
      'category': 'Dresses',
      'price': 150.0,
      'stock': 12,
    });
  }

  /// ===========================================================
  /// LÓGICA DE INVENTARIO (CORREGIDA)
  /// ===========================================================

  // BUSCAR: Solo muestra productos activos
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    final db = await instance.database;
    return await db.query(
      'products',
      where: 'name LIKE ? AND is_active = 1',
      whereArgs: ['%$query%'],
      orderBy: 'id DESC',
    );
  }

  // AGREGAR: Ahora busca si existe para SUMAR, no para reemplazar
  Future<void> insertOrUpdateProduct(
    String name,
    String category,
    double price,
    int amountToAdd,
  ) async {
    final db = await instance.database;

    final List<Map<String, dynamic>> existing = await db.query(
      'products',
      where: 'name = ?',
      whereArgs: [name],
    );

    if (existing.isNotEmpty) {
      // Si ya existe, sumamos al stock actual
      int id = existing.first['id'];
      int currentStock = existing.first['stock'];
      await db.update(
        'products',
        {
          'stock': currentStock + amountToAdd,
          'price': price, // Actualizamos precio por si cambió
          'is_active': 1,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      // Si es nuevo, lo creamos
      await db.insert('products', {
        'name': name,
        'category': category,
        'price': price,
        'stock': amountToAdd,
        'is_active': 1,
      });
    }
  }

  // DISMINUIR STOCK: Para cuando quieres quitar unidades (ej. de 5 a 3)
  Future<void> decreaseStock(int productId, int quantityToRemove) async {
    final db = await instance.database;
    await db.rawUpdate(
      'UPDATE products SET stock = CASE WHEN stock - ? < 0 THEN 0 ELSE stock - ? END WHERE id = ?',
      [quantityToRemove, quantityToRemove, productId],
    );
  }

  // ELIMINADO LÓGICO: Para que ya no aparezca en la lista
  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.update(
      'products',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// ===========================================================
  /// VENTAS Y GRÁFICAS
  /// ===========================================================

  Future<void> processSale(List<Map<String, dynamic>> cart, double total) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      int saleId = await txn.insert('sales', {
        'date': DateTime.now().toIso8601String(),
        'total': total,
        'status': 'PAID',
        'item_count': cart.length,
      });

      for (var item in cart) {
        final currentStock = Sqflite.firstIntValue(
          await txn.rawQuery('SELECT stock FROM products WHERE id = ?', [item['id']]),
        );

        if (currentStock != null && currentStock >= item['qty']) {
          await txn.insert('sale_items', {
            'sale_id': saleId,
            'product_id': item['id'],
            'quantity': item['qty'],
            'price_at_sale': item['price'],
          });

          await txn.rawUpdate(
            'UPDATE products SET stock = stock - ? WHERE id = ?',
            [item['qty'], item['id']],
          );
        } else {
          throw Exception("Stock insuficiente");
        }
      }
    });
  }

  Future<List<Map<String, dynamic>>> getSalesHistory() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT s.id, s.total, s.date,
      GROUP_CONCAT(p.name || ' (\$ ' || si.price_at_sale || ' x ' || si.quantity || ')', '\n') AS products_summary,
      s.item_count
      FROM sales s
      JOIN sale_items si ON s.id = si.sale_id
      JOIN products p ON si.product_id = p.id
      GROUP BY s.id
      ORDER BY s.date DESC
    ''');
  }

  Future<double> getTotalSalesMonth() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      "SELECT SUM(total) as total FROM sales WHERE STRFTIME('%m', date) = STRFTIME('%m', 'now')",
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<List<FlSpot>> getSalesSpots(String filter) async {
    final db = await instance.database;
    String query = "";

    if (filter == 'Hoy' || filter == 'Día') {
      query = "SELECT STRFTIME('%H', date) as x, COUNT(id) as y FROM sales WHERE DATE(date) = DATE('now') GROUP BY x";
    } else {
      query = "SELECT STRFTIME('%d', date) as x, COUNT(id) as y FROM sales WHERE STRFTIME('%m', date) = STRFTIME('%m', 'now') GROUP BY x";
    }

    final result = await db.rawQuery(query);
    return result.map((data) => FlSpot(double.parse(data['x'].toString()), (data['y'] as num).toDouble())).toList();
  }
}