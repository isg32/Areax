import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const AreaxApp());
}

class AreaxApp extends StatelessWidget {
  const AreaxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Areax',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey.shade100,
      ),
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();

  final MapController _mapController = MapController();
  final List<Marker> _markers = [];
  final List<LatLng> _points = [];
  final List<Polygon> _polygons = [];

  static const LatLng _initialPosition = LatLng(23.0225, 72.5714);

  void _onMapTapped(TapPosition tapPosition, LatLng latlng) {
    setState(() {
      final marker = Marker(
        width: 80.0,
        height: 80.0,
        point: latlng,
        child: const Icon(
          Icons.location_pin,
          color: Colors.deepPurple,
          size: 40.0,
        ),
      );
      _markers.add(marker);
      _points.add(latlng);
      _updatePolygon();
    });
  }

  void _updatePolygon() {
    if (_points.length >= 3) {
      _polygons.clear();
      _polygons.add(
        Polygon(
          points: _points,
          color: Colors.deepPurple.withOpacity(0.25),
          borderColor: Colors.deepPurple,
          borderStrokeWidth: 2,
        ),
      );
    } else {
      _polygons.clear();
    }
  }

  void _clearAll() {
    setState(() {
      _nameController.clear();
      _idController.clear();
      _markers.clear();
      _points.clear();
      _polygons.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cleared all data.')),
    );
  }

  // New function to undo the last dropped point
  void _undoLastPoint() {
    setState(() {
      if (_points.isNotEmpty) {
        _points.removeLast();
        _markers.removeLast();
        _updatePolygon();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Undo last point.')),
        );
      }
    });
  }

  Future<void> _locateUser() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showErrorSnackBar('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showErrorSnackBar('Location permissions are denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showErrorSnackBar(
          'Location permissions are permanently denied, we cannot request permissions.');
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final LatLng latlng = LatLng(position.latitude, position.longitude);
      _mapController.move(latlng, 14.0);

      // Create a dummy TapPosition with the current location's LatLng
      final tapPosition = TapPosition(Offset(0, 0), Offset(0, 0));

      // Call _onMapTapped with the dummy TapPosition and the LatLng
      _onMapTapped(tapPosition, latlng);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Located and added your current position.')),
      );
    } catch (e) {
      _showErrorSnackBar('Error locating user: $e');
    }
  }

  // New function to show JSON in a pop-up
  Future<void> _showJsonPopup() async {
    if (_nameController.text.isEmpty || _idController.text.isEmpty) {
      _showErrorSnackBar('Name and ID fields cannot be empty.');
      return;
    }
    if (_points.length < 3) {
      _showErrorSnackBar('At least 3 points are required to define an area.');
      return;
    }

    final String name = _nameController.text;
    final String id = _idController.text;
    final Map<String, dynamic> jsonData = {
      'name': name,
      'id': id,
      'evaluatedAt': DateTime.now().toIso8601String(),
      'areaCoordinates':
          _points.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
    };

    final String jsonString =
        const JsonEncoder.withIndent('  ').convert(jsonData);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generated JSON'),
        content: SingleChildScrollView(
          child: SelectableText(jsonString),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonString));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('JSON copied to clipboard!')),
              );
              Navigator.of(context).pop();
            },
            child: const Text('Copy and Close'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Areax'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialPosition,
              initialZoom: 12.0,
              onTap: _onMapTapped,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.areax',
              ),
              PolygonLayer(polygons: _polygons),
              MarkerLayer(markers: _markers),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              elevation: 8.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Property Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _idController,
                      decoration: const InputDecoration(
                        labelText: 'Property ID',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.pin_rounded),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        FilledButton.icon(
                          onPressed: _undoLastPoint,
                          icon: const Icon(Icons.undo_rounded),
                          label: const Text('Undo'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.grey.shade600,
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: _locateUser,
                          label: const Icon(Icons.my_location_rounded,
                              color: Colors.white),
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.tertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        FilledButton.icon(
                          onPressed: _clearAll,
                          icon: const Icon(Icons.delete_sweep_rounded),
                          label: const Text('Clear'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.amber.shade700,
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: _showJsonPopup,
                          icon: const Icon(Icons.code_rounded),
                          label: const Text('Show JSON'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
