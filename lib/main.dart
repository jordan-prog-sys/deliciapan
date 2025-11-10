import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'catalog_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'historial_screen.dart';
import 'ubicacion_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Delicia App',
      theme: ThemeData(primarySwatch: Colors.orange),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
      },
    );
  }
}

class MainApp extends StatefulWidget {
  final String userId;
  final String nombreUsuario;

  const MainApp({
    super.key,
    required this.userId,
    required this.nombreUsuario,
  });

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> carrito = [];

  void _agregarAlCarrito(Map<String, dynamic> producto) {
    setState(() {
      final existente =
          carrito.indexWhere((p) => p['nombre'] == producto['nombre']);
      if (existente >= 0) {
        carrito[existente]['cantidad'] += producto['cantidad'];
        carrito[existente]['subtotal'] =
            carrito[existente]['cantidad'] * carrito[existente]['costo'];
      } else {
        carrito.add(producto);
      }
    });
  }

  void _eliminarDelCarrito(String nombreProducto) {
    setState(() {
      carrito.removeWhere((p) => p['nombre'] == nombreProducto);
    });
  }

  void _limpiarCarrito() {
    setState(() {
      carrito.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      CatalogScreen(
        onAddToCart: _agregarAlCarrito,
        carritoActual: carrito,
      ),
      const UbicacionScreen(),
      ProfileScreen(userId: widget.userId),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Bienvenido ${widget.nombreUsuario}'),
        backgroundColor: Colors.orange,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CartScreen(
                        carrito: carrito,
                        onClearCart: _limpiarCarrito,
                        onDeleteItem: _eliminarDelCarrito,
                        userId: widget.userId,
                      ),
                    ),
                  );
                },
              ),
              if (carrito.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.red,
                    child: Text(
                      carrito.fold<int>(
                        0,
                        (suma, item) => suma + (item['cantidad'] as int),
                      ).toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.cake), label: 'Catálogo'),
          BottomNavigationBarItem(
              icon: Icon(Icons.location_on), label: 'Ubicación'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
