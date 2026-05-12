import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // Instancia única del cliente de Supabase
  final _supabase = Supabase.instance.client;

  // ==========================================
  // SECCIÓN DE PRODUCTOS (Inventario)
  // ==========================================

  /// Obtiene productos, opcionalmente filtrados por nombre
  Future<List<Map<String, dynamic>>> getProductos(String query) async {
    try {
      var request = _supabase.from('productos').select();

      if (query.isNotEmpty) {
        request = request.ilike('name', '%$query%');
      }

      final data = await request.order('name', ascending: true);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Error en getProductos: $e');
      return [];
    }
  }

  /// Actualiza un producto existente (Stock, Precio, etc.)
  Future<void> actualizarProducto(int id, Map<String, dynamic> datos) async {
    try {
      await _supabase.from('productos').update(datos).eq('id', id);
    } catch (e) {
      print('Error al actualizar producto: $e');
      rethrow;
    }
  }

  // ==========================================
  // SECCIÓN DE VENTAS (Procesamiento y Carrito)
  // ==========================================

  /// Procesa una venta completa en la nube.
  /// Registra la venta, los detalles y descuenta el stock automáticamente.
  /// Nota: Requiere la función 'procesar_venta_v2' creada en el SQL Editor de Supabase.
  Future<void> realizarVentaCompleta({
    required List<Map<String, dynamic>> carrito,
    required double total,
  }) async {
    try {
      // Formateamos los detalles para que el JSON coincida con la función SQL
      final List<Map<String, dynamic>> detalles = carrito
          .map(
            (item) => {
              'producto_id': item['id'],
              'cantidad': item['qty'],
              'precio_unitario': item['price'],
            },
          )
          .toList();

      await _supabase.rpc(
        'procesar_venta_v2',
        params: {
          'p_total': total,
          'p_cantidad_items': carrito.length,
          'p_detalles': detalles,
        },
      );
    } catch (e) {
      print('Error en realizarVentaCompleta: $e');
      rethrow;
    }
  }

  /// Obtener todas las ventas (Historial General)
  Future<List<Map<String, dynamic>>> getVentas() async {
    try {
      final response = await _supabase
          .from('ventas')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error al obtener ventas: $e');
      return [];
    }
  }

  /// Obtiene ventas filtradas por tiempo para las gráficas del Dashboard
  Future<List<Map<String, dynamic>>> getVentasFiltradas(String filtro) async {
    final ahora = DateTime.now();
    DateTime fechaInicio;

    if (filtro == 'Día') {
      fechaInicio = DateTime(ahora.year, ahora.month, ahora.day);
    } else if (filtro == 'Semana') {
      fechaInicio = ahora.subtract(const Duration(days: 7));
    } else {
      // Mes actual
      fechaInicio = DateTime(ahora.year, ahora.month, 1);
    }

    try {
      final data = await _supabase
          .from('ventas')
          .select()
          .gte('created_at', fechaInicio.toIso8601String())
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Error filtrando ventas: $e');
      return [];
    }
  }

  // ==========================================
  // SECCIÓN DE SERVICIOS
  // ==========================================

  Future<List<Map<String, dynamic>>> getServicios() async {
    try {
      final data = await _supabase.from('servicios').select();
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Error al obtener servicios: $e');
      return [];
    }
  }

  // ==========================================
  // MÉTODOS GENÉRICOS (Insertar, Borrar)
  // ==========================================

  /// Inserta un nuevo registro en cualquier tabla
  Future<void> insertarRegistro(
    String tabla,
    Map<String, dynamic> datos,
  ) async {
    try {
      await _supabase.from(tabla).insert(datos);
    } catch (e) {
      print('Error al insertar en $tabla: $e');
      rethrow;
    }
  }

  /// Elimina un registro por ID de cualquier tabla
  Future<void> eliminarRegistro(String tabla, int id) async {
    try {
      await _supabase.from(tabla).delete().match({'id': id});
    } catch (e) {
      print('Error al eliminar registro: $e');
      rethrow;
    }
  }
}
