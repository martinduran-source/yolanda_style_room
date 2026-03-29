import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:fl_chart/fl_chart.dart'; // <--- AGREGA ESTA LÍNEA

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
      onCreate: _createDB,
      // Habilitar claves foráneas para que al borrar una venta se limpien sus detalles
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future _createDB(Database db, int version) async {
    // 1. Tabla de Productos (Inventario)
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        price REAL NOT NULL,
        stock INTEGER NOT NULL
      )
    ''');

    // 2. Tabla de Ventas (Cabecera del Historial)
    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        total REAL NOT NULL,
        status TEXT NOT NULL,      -- 'PAID' o 'PENDING'
        item_count INTEGER NOT NULL
      )
    ''');

    // 3. Tabla Detalle de Ventas (Relación N:N)
    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        price_at_sale REAL NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    // Opcional: Insertar algunos datos de prueba al crear la base
    await _insertMockData(db);
  }

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

  // --- MÉTODOS DE OPERACIÓN ---
  // Método para obtener los puntos de la gráfica
  Future<List<FlSpot>> getSalesSpots() async {
    final db = await instance.database;
    final now = DateTime.now();

    // Filtramos por el mes actual (Ej: 2026-02)
    final currentMonth = "${now.year}-${now.month.toString().padLeft(2, '0')}";

    // Consulta SQL: Agrupa ventas por día y suma el total
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT STRFTIME('%d', date) as day, SUM(total) as daily_total 
      FROM sales 
      WHERE date LIKE '$currentMonth%'
      GROUP BY day
      ORDER BY day ASC
    ''');

    // Convertimos los resultados a una lista de FlSpot
    List<FlSpot> spots = result.map((data) {
      // x = día del mes, y = total vendido ese día
      double x = double.parse(data['day'].toString());
      double y = (data['daily_total'] as num).toDouble();
      return FlSpot(x, y);
    }).toList();

    // Si no hay ventas, devolvemos un punto en 0 para que no falle la gráfica
    if (spots.isEmpty) {
      return [const FlSpot(0, 0)];
    }

    return spots;
  }

  // Buscar productos para la pantalla de NewSale
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    final db = await instance.database;
    return await db.query(
      'products',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
    );
  }

  // Finalizar Venta: Inserta venta, detalles y resta Stock
  Future<void> processSale(
    List<Map<String, dynamic>> cart,
    double total,
  ) async {
    final db = await instance.database;

    await db.transaction((txn) async {
      // Guardar la venta
      int saleId = await txn.insert('sales', {
        'date': DateTime.now().toIso8601String(),
        'total': total,
        'status': 'PAID',
        'item_count': cart.length,
      });

      // Procesar cada item
      for (var item in cart) {
        await txn.insert('sale_items', {
          'sale_id': saleId,
          'product_id': item['id'],
          'quantity': item['qty'],
          'price_at_sale': item['price'],
        });

        // Actualizar el stock del producto
        await txn.rawUpdate(
          'UPDATE products SET stock = stock - ? WHERE id = ?',
          [item['qty'], item['id']],
        );
      }
    });
  }

  // Obtener todas las ventas para el historial
  Future<List<Map<String, dynamic>>> getSalesHistory() async {
    final db = await instance.database;
    // Ordenamos por fecha descendente (la más nueva primero)
    return await db.query('sales', orderBy: 'date DESC');
  }

  // Opcional: Obtener los productos de una venta específica
  Future<List<Map<String, dynamic>>> getSaleDetails(int saleId) async {
    final db = await instance.database;
    return await db.rawQuery(
      '''
      SELECT si.*, p.name 
      FROM sale_items si
      JOIN products p ON si.product_id = p.id
      WHERE si.sale_id = ?
    ''',
      [saleId],
    );
  }

  // 1. Obtener el total de ventas del mes actual
  Future<double> getTotalSalesMonth() async {
    final db = await instance.database;
    final now = DateTime.now();
    // Formato: 2026-03
    final currentMonth = "${now.year}-${now.month.toString().padLeft(2, '0')}";

    final result = await db.rawQuery('''
      SELECT SUM(total) as total 
      FROM sales 
      WHERE date LIKE '$currentMonth%'
    ''');

    // Si no hay ventas, devolvemos 0.0
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // 2. Obtener la suma total de todos los productos en inventario
  Future<int> getTotalStock() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      "SELECT SUM(stock) as total FROM products",
    );

    // Si está vacío, devolvemos 0
    return (result.first['total'] as num?)?.toInt() ?? 0;
  }

  // Insertar un nuevo producto en la tabla 'products'
  Future<void> insertProduct(
    String name,
    String category,
    double price,
    int stock,
  ) async {
    final db = await instance.database;
    await db.insert(
      'products',
      {'name': name, 'category': category, 'price': price, 'stock': stock},
      conflictAlgorithm: ConflictAlgorithm.replace, // opcional
    );
  }
}
