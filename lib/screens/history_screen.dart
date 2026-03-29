import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Historial de Ventas")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseHelper.instance.getSalesHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No hay ventas registradas"));
          }
          final sales = snapshot.data!;
          return ListView.builder(
            itemCount: sales.length,
            itemBuilder: (context, i) {
              final s = sales[i];
              return ListTile(
                title: Text("Venta #${s['id']} - \$${s['total']}"),
                subtitle: Text("Fecha: ${s['date']}"),
                trailing: Text("${s['item_count']} items"),
              );
            },
          );
        },
      ),
    );
  }
}
