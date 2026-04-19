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

  /// ===========================================================
  /// LÓGICA DE INVENTARIO
  /// ===========================================================

  // BUSCAR: Solo muestra productos activos (incluye stock 0)
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    final db = await instance.database;
    return await db.query(
      'products',
      where: 'name LIKE ? AND is_active = 1',
      whereArgs: ['%$query%'],
      orderBy: 'stock DESC', // Opcional: primero los que tienen stock
    );
  }

  // INSERTAR O ACTUALIZAR: Suma stock si el nombre ya existe
  Future<void> insertProduct(
    String name,
    String category,
    double price,
    int stock,
  ) async {
    final db = await instance.database;
    final cleanName = name.trim();

    final List<Map<String, dynamic>> existing = await db.query(
      'products',
      where: 'LOWER(name) = ?',
      whereArgs: [cleanName.toLowerCase()],
    );

    if (existing.isNotEmpty) {
      int id = existing.first['id'];
      int currentStock = existing.first['stock'];
      await db.update(
        'products',
        {
          'stock': currentStock + stock,
          'price': price,
          'is_active': 1, // Reactivamos si estaba borrado
        },
        where: 'id = ?',
        whereArgs: [id],
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

  // RESTAR STOCK: Útil para ajustes manuales o mermas
  Future<void> decreaseStock(int productId, int quantityToRemove) async {
    final db = await instance.database;
    await db.rawUpdate(
      'UPDATE products SET stock = CASE WHEN stock - ? < 0 THEN 0 ELSE stock - ? END WHERE id = ?',
      [quantityToRemove, quantityToRemove, productId],
    );
  }

  // ELIMINADO LÓGICO: Oculta el producto pero mantiene historial
  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.update(
      'products',
      {'is_active': 0, 'stock': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // NUEVO: Marcar producto como agotado sin desactivarlo
  Future<int> markAsOutOfStock(int id) async {
    final db = await instance.database;
    return await db.update(
      'products',
      {'stock': 0}, // Solo bajamos el stock a 0
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// ===========================================================
  /// VENTAS Y GRÁFICAS
  /// ===========================================================

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
        // Validación de stock antes de descontar
        final currentStock = Sqflite.firstIntValue(
          await txn.rawQuery('SELECT stock FROM products WHERE id = ?', [
            item['id'],
          ]),
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
          throw Exception("Stock insuficiente para ${item['name']}");
        }
      }
    });
  }
  // MÉTODOS PARA OBTENER PRODUCTOS (PARA LA SELECCIÓN RÁPIDA)

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await instance.database;
    // Traemos solo los productos activos para vender
    return await db.query(
      'products',
      where: 'is_active = 1',
      orderBy: 'name ASC',
    );
  }

  // HISTORIAL: con detalle de productos vendidos
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

  // GRÁFICA: Número de ventas por hora o día
  Future<List<FlSpot>> getSalesSpots(String filter) async {
    final db = await instance.database;
    String query = "";

    if (filter == 'Hoy' || filter == 'Día') {
      query = """
        SELECT STRFTIME('%H', date) as x, COUNT(id) as y 
        FROM sales 
        WHERE DATE(date) = DATE('now') 
        GROUP BY x 
        ORDER BY x ASC
      """;
    } else {
      query = """
        SELECT STRFTIME('%d', date) as x, COUNT(id) as y 
        FROM sales 
        WHERE STRFTIME('%m', date) = STRFTIME('%m', 'now') 
        GROUP BY x 
        ORDER BY x ASC
      """;
    }

    final result = await db.rawQuery(query);
    if (result.isEmpty) return [];

    return result.map((data) {
      return FlSpot(
        double.parse(data['x'].toString()),
        (data['y'] as num).toDouble(),
      );
    }).toList();
  }


  // Dentro de tu clase DatabaseHelper
  Future<int> updateProduct(
    int id,
    String name,
    String category,
    double price,
    int stock,
  ) async {
    final db = await instance.database;
    return await db.update(
      'products', // Asegúrate que este sea el nombre de tu tabla
      {'name': name, 'category': category, 'price': price, 'stock': stock},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Método para insertar una venta y obtener su ID

  Future<int> insertSale(Map<String, dynamic> row) async {
    final db = await instance.database;
    // 'sales' debe ser el nombre de tu tabla de ventas
    return await db.insert('sales', row);
  }

  // Método para insertar un producto específico dentro de una venta

  Future<int> insertSaleItem(Map<String, dynamic> row) async {
    final db = await instance.database;
    // 'sale_items' debe ser el nombre de tu tabla de detalles
    return await db.insert('sale_items', row);
  }
}
