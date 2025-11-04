import 'dart:async';
import 'dart:convert'; 
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class UbicacionScreen extends StatefulWidget {
  const UbicacionScreen({super.key});

  @override
  State<UbicacionScreen> createState() => _UbicacionScreenState();
}

class _UbicacionScreenState extends State<UbicacionScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  LatLng? _ubicacionActual;
  String _direccionActual = 'Ubicación no disponible'; // 🆕 Nueva variable
  final LatLng _ubicacionPanaderia = const LatLng(-12.0651, -75.2049);

  @override
  void initState() {
    super.initState();
    _obtenerUbicacionActual();
  }

  // 🔹 Obtiene la ubicación actual y dirección usando Geolocator y Google API
  Future<void> _obtenerUbicacionActual() async {
    bool servicioHabilitado;
    LocationPermission permiso;

    servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, habilita la ubicación.')),
      );
      return;
    }

    permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso de ubicación denegado.')),
        );
        return;
      }
    }

    if (permiso == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Los permisos de ubicación están bloqueados.')),
      );
      return;
    }

    final posicion = await Geolocator.getCurrentPosition();
    setState(() {
      _ubicacionActual = LatLng(posicion.latitude, posicion.longitude);
    });

    // 🆕 Llamada a la API de Google Maps para obtener la dirección
    await _obtenerDireccionDesdeCoordenadas(
      posicion.latitude,
      posicion.longitude,
    );
  }

  // 🆕 Función que obtiene la dirección textual a partir de coordenadas
  Future<void> _obtenerDireccionDesdeCoordenadas(
      double lat, double lng) async {
    const apiKey = 'TU_API_KEY_DE_GOOGLE_MAPS'; // 🔑 reemplaza con tu clave real
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List<dynamic>;
        if (results.isNotEmpty) {
          setState(() {
            _direccionActual = results[0]['formatted_address'];
          });
        }
      } else {
        setState(() {
          _direccionActual = 'No se pudo obtener la dirección.';
        });
      }
    } catch (e) {
      setState(() {
        _direccionActual = 'Error al obtener la dirección.';
      });
    }
  }

  Future<void> _moverACentroPanaderia() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newLatLngZoom(_ubicacionPanaderia, 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[50],
      appBar: AppBar(
        title: const Text('Ubicación de Panadería Delicia'),
        backgroundColor: Colors.orange,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _obtenerUbicacionActual,
            tooltip: 'Actualizar ubicación',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _ubicacionActual == null
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.orange),
                        SizedBox(height: 10),
                        Text(
                          'Obteniendo tu ubicación...',
                          style: TextStyle(
                              color: Colors.brown, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  )
                : GoogleMap(
                    mapType: MapType.normal,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    markers: {
                      Marker(
                        markerId: const MarkerId('panaderia'),
                        position: _ubicacionPanaderia,
                        infoWindow: const InfoWindow(
                          title: 'Panadería Delicia',
                          snippet: 'Av. Los Pinos 123 – Huancayo, Perú',
                        ),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueOrange),
                      ),
                      Marker(
                        markerId: const MarkerId('usuario'),
                        position: _ubicacionActual!,
                        infoWindow:
                            InfoWindow(title: 'Tú', snippet: _direccionActual),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueAzure),
                      ),
                    },
                    initialCameraPosition: CameraPosition(
                      target: _ubicacionPanaderia,
                      zoom: 15,
                    ),
                    onMapCreated: (GoogleMapController controller) {
                      _controller.complete(controller);
                    },
                  ),
          ),

          // 🟠 Bloque informativo inferior
          Container(
            width: double.infinity,
            color: Colors.orange[100],
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  '📍 Panadería Delicia - Huancayo',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Av. Los Pinos 123 – Huancayo, Junín, Perú\n'
                  '🕒 Lunes a Sábado: 7:00 a.m. - 9:00 p.m.\n'
                  'Domingos: 8:00 a.m. - 7:00 p.m.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.brown, fontSize: 14),
                ),
                const SizedBox(height: 10),
                Text(
                  'Tu ubicación actual:\n$_direccionActual', // 🆕 Dirección obtenida de la API
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.brown,
                      fontSize: 14,
                      fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ElevatedButton.icon(
              onPressed: _moverACentroPanaderia,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.directions, color: Colors.white),
              label: const Text(
                'Ver panadería en el mapa',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
