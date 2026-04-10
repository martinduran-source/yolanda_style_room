import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:fl_chart/fl_chart.dart';

class DatabaseHelper {

  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// =============================
  /// OBTENER BASE DE DATOS
  /// =============================
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('yolanda_style.db');
    return _database!;
  }

  /// =============================
  /// INICIALIZAR DB
  /// =============================
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

  /// =============================
  /// CREAR TABLAS
  /// =============================
  Future _createDB(Database db, int version) async {

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        price REAL NOT NULL,
        stock INTEGER NOT NULL
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

  /// =============================
  /// DATOS DE PRUEBA
  /// =============================
  Future<void> _insertMockData(Database db) async {
    await db.insert('products', {
      'name': 'Silk Evening Dress',
      'category': 'Dresses',
      'price': 150.0,
      'stock': 12,
    });

    await db.insert('products', {
      'name': 'Leather High Heels',
      'category': 'Shoes',
      'price': 85.0,
      'stock': 3,
    });
  }

  /// =============================
  /// BUSCAR PRODUCTOS
  /// =============================
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    final db = await instance.database;

    return await db.query(
      'products',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'id DESC',
    );
  }

  /// =============================
  /// INSERTAR PRODUCTO
  /// =============================
  Future<void> insertProduct(
      String name,
      String category,
      double price,
      int stock) async {

    final db = await instance.database;

    await db.insert(
      'products',
      {
        'name': name,
        'category': category,
        'price': price,
        'stock': stock,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// =============================
  /// ELIMINAR PRODUCTO
  /// =============================
  Future<int> deleteProduct(int id) async {
    final db = await instance.database;

    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// =============================
  /// PROCESAR VENTA
  /// =============================
  Future<void> processSale(
      List<Map<String, dynamic>> cart,
      double total) async {

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

  /// =============================
  /// HISTORIAL DE VENTAS
  /// =============================
  Future<List<Map<String, dynamic>>> getSalesHistory() async {
    final db = await instance.database;

    return await db.rawQuery('''
      SELECT s.id, s.total, s.date,
      GROUP_CONCAT(
        p.name || ' (\$ ' || si.price_at_sale || ' x ' || si.quantity || ')',
        '\n'
      ) AS products_summary,
      s.item_count
      FROM sales s
      JOIN sale_items si ON s.id = si.sale_id
      JOIN products p ON si.product_id = p.id
      GROUP BY s.id
      ORDER BY s.date DESC
    ''');
  }

  /// =============================
  /// TOTAL VENTAS DEL MES
  /// =============================
  Future<double> getTotalSalesMonth() async {
    final db = await instance.database;

    final now = DateTime.now();
    final currentMonth =
        "${now.year}-${now.month.toString().padLeft(2, '0')}";

    final result = await db.rawQuery(
      "SELECT SUM(total) as total FROM sales WHERE date LIKE '$currentMonth%'",
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// =============================
  /// STOCK TOTAL
  /// =============================
  Future<int> getTotalStock() async {
    final db = await instance.database;

    final result =
        await db.rawQuery("SELECT SUM(stock) as total FROM products");

    return (result.first['total'] as num?)?.toInt() ?? 0;
  }

  /// =============================
  /// DATOS PARA GRÁFICAS
  /// =============================
  Future<List<FlSpot>> getSalesSpots(String filter) async {

    final db = await instance.database;
    String query = "";

    if (filter == 'Hoy' || filter == 'Día') {

      query = '''
        SELECT STRFTIME('%H', date) as x_label, COUNT(id) as y_value
        FROM sales
        WHERE DATE(date) = DATE('now','localtime')
        GROUP BY x_label
        ORDER BY x_label ASC
      ''';

    } else if (filter == 'Semana') {

      query = '''
        SELECT STRFTIME('%d', date) as x_label, COUNT(id) as y_value
        FROM sales
        WHERE date >= DATE('now','-7 days','localtime')
        GROUP BY x_label
      ''';

    } else {

      query = '''
        SELECT STRFTIME('%d', date) as x_label, COUNT(id) as y_value
        FROM sales
        WHERE STRFTIME('%m', date)=STRFTIME('%m','now','localtime')
        AND STRFTIME('%Y', date)=STRFTIME('%Y','now','localtime')
        GROUP BY x_label
      ''';
    }

    final result = await db.rawQuery(query);

    List<FlSpot> spots = result.map((data) {
      double x =
          double.tryParse(data['x_label'].toString()) ?? 0.0;
      double y = (data['y_value'] as num).toDouble();
      return FlSpot(x, y);
    }).toList();

    return spots.isEmpty ? [const FlSpot(0, 0)] : spots;
  }
}