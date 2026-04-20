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
  }

  // --- MÉTODOS DE PRODUCTOS ---

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await instance.database;
    return await db.query(
      'products',
      where: 'is_active = 1',
      orderBy: 'name ASC',
    );
  }

  Future<void> insertProduct(
    String name,
    String category,
    double price,
    int stock,
  ) async {
    final db = await instance.database;
    final cleanName = name.trim();
    final existing = await db.query(
      'products',
      where: 'LOWER(name) = ?',
      whereArgs: [cleanName.toLowerCase()],
    );

    if (existing.isNotEmpty) {
      await db.update(
        'products',
        {
          'stock': (existing.first['stock'] as int) + stock,
          'price': price,
          'is_active': 1,
        },
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      await db.insert('products', {
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
    final db = await instance.database;
    return await db.update(
      'products',
      {
        'name': name.trim(),
        'category': category,
        'price': price,
        'stock': stock,
        'is_active': 1,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.update(
      'products',
      {'is_active': 0, 'stock': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- MÉTODOS DE VENTAS ---

  Future<void> processSale(
    List<Map<String, dynamic>> cart,
    double total,
  ) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      int saleId = await txn.insert('sales', {
        'date': DateTime.now().toIso8601String(),
        'total': total,
        'status': 'PAID',
        'item_count': cart.length,
      });

      for (var item in cart) {
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
      }
    });
  }

  Future<List<Map<String, dynamic>>> getSalesHistory() async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT s.id, s.date, s.total, s.item_count,
      GROUP_CONCAT(p.name || ' x' || si.quantity, ', ') AS products_summary
      FROM sales s
      JOIN sale_items si ON s.id = si.sale_id
      JOIN products p ON si.product_id = p.id
      GROUP BY s.id
      ORDER BY s.date DESC
    ''');
  }

  // --- MÉTODOS DE BÚSQUEDA ---

  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    final db = await instance.database;
    return await db.query(
      'products',
      where: 'name LIKE ? AND is_active = 1',
      whereArgs: ['%$query%'],
      orderBy: 'name ASC',
    );
  }

  // --- MÉTODOS DE REPORTES Y GRÁFICAS ---

  Future<List<FlSpot>> getSalesSpots(String filter) async {
    final db = await instance.database;
    String query = "";

    if (filter == 'Día' || filter == 'Hoy') {
      query =
          "SELECT STRFTIME('%H', date, 'localtime') as x, SUM(total) as y FROM sales WHERE DATE(date, 'localtime') = DATE('now', 'localtime') GROUP BY x ORDER BY x ASC";
    } else if (filter == 'Semana') {
      query =
          "SELECT STRFTIME('%d', date, 'localtime') as x, SUM(total) as y FROM sales WHERE DATE(date, 'localtime') >= DATE('now', 'localtime', '-7 days') GROUP BY x ORDER BY date ASC";
    } else {
      query =
          "SELECT STRFTIME('%d', date, 'localtime') as x, SUM(total) as y FROM sales WHERE STRFTIME('%m', date, 'localtime') = STRFTIME('%m', 'now', 'localtime') AND STRFTIME('%Y', date, 'localtime') = STRFTIME('%Y', 'now', 'localtime') GROUP BY x ORDER BY x ASC";
    }

    final result = await db.rawQuery(query);
    if (result.isEmpty) return [];

    return result.map((data) {
      double xValue = double.tryParse(data['x'].toString()) ?? 0.0;
      double yValue = (data['y'] as num?)?.toDouble() ?? 0.0;
      return FlSpot(xValue, yValue);
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getFilteredSalesHistory(
    String filter,
  ) async {
    final db = await instance.database;
    String dateCondition = "";

    if (filter == 'Hoy' || filter == 'Día') {
      dateCondition =
          "WHERE DATE(s.date, 'localtime') = DATE('now', 'localtime')";
    } else if (filter == 'Semana') {
      dateCondition =
          "WHERE DATE(s.date, 'localtime') >= DATE('now', 'localtime', '-7 days')";
    } else {
      dateCondition =
          "WHERE STRFTIME('%m', s.date, 'localtime') = STRFTIME('%m', 'now', 'localtime') AND STRFTIME('%Y', s.date, 'localtime') = STRFTIME('%Y', 'now', 'localtime')";
    }

    return await db.rawQuery('''
      SELECT s.id, s.date, s.total, s.item_count,
      GROUP_CONCAT(p.name || ' x' || si.quantity, ', ') AS products_summary
      FROM sales s
      JOIN sale_items si ON s.id = si.sale_id
      JOIN products p ON si.product_id = p.id
      $dateCondition
      GROUP BY s.id
      ORDER BY s.date DESC
    ''');
  }
}
