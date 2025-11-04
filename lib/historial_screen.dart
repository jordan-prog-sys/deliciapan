import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistorialScreen extends StatefulWidget {
  final String userId; // 🔹 ID del usuario actual (para acceder a su subcolección)

  const HistorialScreen({super.key, required this.userId});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[50],
      appBar: AppBar(
        title: const Text('Historial de Compras'),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 🔹 Escucha en tiempo real la subcolección "historial" del usuario
        stream: FirebaseFirestore.instance
            .collection('UsuariosPanaderia')
            .doc(widget.userId)
            .collection('historial')
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Aún no hay compras registradas 🧁',
                style: TextStyle(fontSize: 16, color: Colors.brown),
              ),
            );
          }

          final historial = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: historial.length,
            itemBuilder: (context, index) {
              final compra = historial[index].data() as Map<String, dynamic>;
              final fecha = (compra['fecha'] as Timestamp).toDate();
              final total = compra['total'] ?? 0.0;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: const Icon(Icons.receipt_long,
                      color: Colors.brown, size: 32),
                  title: Text(
                    'Compra del ${fecha.day}/${fecha.month}/${fecha.year}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.brown),
                  ),
                  subtitle: Text(
                    'Total: S/. ${total.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 15),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.info_outline, color: Colors.orange),
                    onPressed: () {
                      // 🔹 Aquí se podría mostrar detalle de la compra en el futuro
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Compra del ${fecha.day}/${fecha.month}/${fecha.year}\nTotal: S/. ${total.toStringAsFixed(2)}',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
