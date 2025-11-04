import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'historial_screen.dart';

class CartScreen extends StatelessWidget {
  final List<Map<String, dynamic>> carrito;
  final Function() onClearCart;
  final Function(String) onDeleteItem;
  final String userId;

  const CartScreen({
    super.key,
    required this.carrito,
    required this.onClearCart,
    required this.onDeleteItem,
    required this.userId,
  });

  double get total =>
      carrito.fold(0, (sum, item) => sum + (item['subtotal'] as num? ?? 0).toDouble());

  Future<void> registrarCompraEnHistorial(BuildContext context) async {
    if (carrito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El carrito está vacío')),
      );
      return;
    }

    try {
      final compraData = {
        'fecha': Timestamp.now(),
        'total': total,
        'productos': carrito.map((item) {
          return {
            'nombre': item['nombre'],
            'cantidad': item['cantidad'],
            'subtotal': item['subtotal'],
          };
        }).toList(),
      };

      await FirebaseFirestore.instance
          .collection('UsuariosPanaderia')
          .doc(userId)
          .collection('historial')
          .add(compraData);

      onClearCart();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Compra registrada en el historial')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar compra: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[50],
      appBar: AppBar(
        title: const Text('Carrito de Compras'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial de compras',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistorialScreen(userId: userId),
                ),
              );
            },
          ),
        ],
      ),
      body: carrito.isEmpty
          ? const Center(
              child: Text(
                '🛒 No hay productos en el carrito',
                style: TextStyle(fontSize: 16, color: Colors.brown),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: carrito.length,
                    itemBuilder: (context, index) {
                      final item = carrito[index];
                      return Card(
                        elevation: 3,
                        margin:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.local_cafe, color: Colors.brown),
                          title: Text(
                            item['nombre'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.brown,
                            ),
                          ),
                          subtitle: Text(
                            'Cantidad: ${item['cantidad']}\nSubtotal: S/. ${item['subtotal'].toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Eliminar producto',
                            onPressed: () {
                              onDeleteItem(item['nombre']);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '${item['nombre']} eliminado del carrito'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, -1),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total a pagar:',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'S/. ${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => registrarCompraEnHistorial(context),
                        icon: const Icon(Icons.payment, color: Colors.white),
                        label: const Text(
                          'Comprar',
                          style: TextStyle(
                              fontSize: 16, color: Colors.white, height: 1.2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
