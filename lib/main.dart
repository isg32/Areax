import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

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

  // New function to locate by IP
  Future<void> _locateByIp() async {
    try {
      final response = await http.get(Uri.parse('http://ip-api.com/json'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final lat = data['lat'];
        final lon = data['lon'];
        if (lat != null && lon != null) {
          _mapController.move(LatLng(lat, lon), 14.0);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Located by IP address!')),
          );
        } else {
          _showErrorSnackBar('Could not find location data from IP.');
        }
      } else {
        _showErrorSnackBar('Failed to get location data from API.');
      }
    } catch (e) {
      _showErrorSnackBar('Error locating by IP: $e');
    }
  }

  Future<void> _saveJson() async {
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
    final String formattedDate =
        DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());

    final Map<String, dynamic> jsonData = {
      'name': name,
      'id': id,
      'evaluatedAt': DateTime.now().toIso8601String(),
      'areaCoordinates':
          _points.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
    };

    final String jsonString =
        const JsonEncoder.withIndent('  ').convert(jsonData);
    final Uint8List fileData = Uint8List.fromList(utf8.encode(jsonString));
    final String fileName = '$name-property-evaluatedat_$formattedDate.json';

    try {
      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: fileData,
        fileExtension: 'json',
        mimeType: MimeType.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully saved $fileName')),
      );
    } catch (e) {
      _showErrorSnackBar('Error saving file: $e');
    }
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
                  borderRadius: BorderRadius.circular(16)),
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
                    const SizedBox(height: 16),
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
                          onPressed: _saveJson,
                          icon: const Icon(Icons.save_alt_rounded),
                          label: const Text('Save Area'),
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
      // This is the new floating action button
      floatingActionButton: FloatingActionButton(
        onPressed: _locateByIp,
        tooltip: 'Locate by IP',
        backgroundColor: Theme.of(context).colorScheme.tertiary,
        child: const Icon(Icons.my_location_rounded, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
