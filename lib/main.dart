import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package.google_maps_flutter/google_maps_flutter.dart';
import 'package.file_saver/file_saver.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const AreaxApp());
}

class AreaxApp extends StatelessWidget {
  const AreaxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Areax',
      // Using Material 3 theme with a seed color
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
  // Controllers for text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();

  // Map-related state
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final List<LatLng> _points = [];
  final Set<Polygon> _polygons = {};

  // A unique ID for the polygon
  final String _polygonId = 'area_polygon';

  // Centered on Ahmedabad, Gujarat
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(23.0225, 72.5714), 
    zoom: 12,
  );

  // Handles taps on the map to add pins
  void _onMapTapped(LatLng position) {
    setState(() {
      final markerId = MarkerId('pin_${_markers.length}');
      _markers.add(
        Marker(
          markerId: markerId,
          position: position,
          infoWindow: InfoWindow(
            title: 'Point ${_points.length + 1}',
            snippet:
                '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        ),
      );
      _points.add(position);
      _updatePolygon();
    });
  }

  // Updates or creates the polygon based on the current points
  void _updatePolygon() {
    if (_points.length >= 3) {
      setState(() {
        _polygons.clear();
        _polygons.add(
          Polygon(
            polygonId: PolygonId(_polygonId),
            points: _points,
            strokeWidth: 2,
            strokeColor: Colors.deepPurple,
            fillColor: Colors.deepPurple.withOpacity(0.25),
            geodesic: true,
          ),
        );
      });
    } else {
      // Clear the polygon if there are less than 3 points
      setState(() {
        _polygons.clear();
      });
    }
  }

  // Clears all data from the map and form
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

  // Generates and saves the JSON file
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

    // Prepare data for JSON
    final Map<String, dynamic> jsonData = {
      'name': name,
      'id': id,
      'evaluatedAt': DateTime.now().toIso8601String(),
      'areaCoordinates':
          _points.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
    };

    // Convert map to JSON string
    final String jsonString =
        const JsonEncoder.withIndent('  ').convert(jsonData);
    final Uint8List fileData = Uint8List.fromList(utf8.encode(jsonString));
    final String fileName = '$name-property-evaluatedat_$formattedDate.json';

    // Use file_saver to save the file
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
          GoogleMap(
            initialCameraPosition: _initialPosition,
            onMapCreated: (controller) => _mapController = controller,
            onTap: _onMapTapped,
            markers: _markers,
            polygons: _polygons,
            myLocationButtonEnabled: true,
            myLocationEnabled:
                true, // Requires location permissions in native configs
          ),
          // This is the floating dock
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
                        // Clear Button
                        FilledButton.icon(
                          onPressed: _clearAll,
                          icon: const Icon(Icons.delete_sweep_rounded),
                          label: const Text('Clear'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.amber.shade700,
                          ),
                        ),
                        // Save Button
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
    );
  }
}


