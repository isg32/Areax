import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

class MapScreen extends StatefulWidget {
  // New: Accept an optional initial document ID
  final String? initialDocId;

  const MapScreen({super.key, this.initialDocId});

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

  @override
  void initState() {
    super.initState();
    // New: Pre-fill the ID controller if an initialDocId was passed
    if (widget.initialDocId != null) {
      _idController.text = widget.initialDocId!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    super.dispose();
  }

  void _onMapTapped(TapPosition tapPosition, LatLng latlng) {
    setState(() {
      final marker = Marker(
        width: 80.0,
        height: 80.0,
        point: latlng,
        child: const Icon(
          Icons.location_pin,
          color: kErrorColor,
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
          color: kPrimaryColor.withOpacity(0.35),
          borderColor: kPrimaryColor,
          borderStrokeWidth: 3,
        ),
      );
    } else {
      _polygons.clear();
    }
  }

  void _clearAll() {
    setState(() {
      _nameController.clear();
      // Keep ID if passed initially, otherwise clear it
      if (widget.initialDocId == null) {
        _idController.clear();
      }
      _markers.clear();
      _points.clear();
      _polygons.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Map data cleared.')),
    );
  }

  void _undoLastPoint() {
    setState(() {
      if (_points.isNotEmpty) {
        _points.removeLast();
        _markers.removeLast();
        _updatePolygon();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Last point undone.')),
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

      // Add the current location as a point (simulating a tap)
      _onMapTapped(TapPosition(Offset.zero, Offset.zero), latlng);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current location added as a point.')),
      );
    } catch (e) {
      _showErrorSnackBar('Error locating user: $e');
    }
  }

  Future<void> _showJsonPopup() async {
    if (_nameController.text.isEmpty || _idController.text.isEmpty) {
      _showErrorSnackBar('Please fill out both Name and ID fields.');
      return;
    }
    if (_points.length < 3) {
      _showErrorSnackBar('You need at least 3 points to define an area.');
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
          child: SelectableText(
            jsonString,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Copy'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonString));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('JSON copied to clipboard!')),
              );
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendToDatabase() async {
    if (_idController.text.isEmpty || _points.length < 3) {
      _showErrorSnackBar('Property ID and at least 3 points are required.');
      return;
    }

    final String id = _idController.text;
    final coordinates = _points
        .map((p) => {'lat': p.latitude, 'lng': p.longitude})
        .toList();

    final body = jsonEncode({
      'id': id,
      'coordinates': coordinates,
    });

    try {
      final response = await http.post(
        Uri.parse("$kApiUrl/update_coordinates"),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: const Text("✅ Coordinates updated successfully!"),
              backgroundColor: Colors.green.shade700),
        );
      } else {
        _showErrorSnackBar("API Failed: ${response.body}");
      }
    } catch (e) {
      _showErrorSnackBar("Network Error: $e");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Area Selector'),
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
                userAgentPackageName: 'com.isg32.areax',
              ),
              PolygonLayer(polygons: _polygons),
              MarkerLayer(markers: _markers),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Card(
              elevation: 12.0,
              color: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Property Name',
                        prefixIcon: Icon(Icons.business_rounded, color: kPrimaryColor),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _idController,
                      keyboardType: TextInputType.text, // Changed to text to handle ObjectId strings
                      decoration: InputDecoration(
                        labelText: 'Property ID (Mandatory)',
                        prefixIcon: Icon(Icons.pin_rounded, color: kPrimaryColor),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _undoLastPoint,
                            icon: const Icon(Icons.undo_rounded),
                            label: const Text('Undo'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.grey.shade600,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _locateUser,
                            icon: const Icon(Icons.my_location_rounded),
                            label: const Text('Locate'),
                            style: FilledButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _showJsonPopup,
                            icon: const Icon(Icons.code_rounded),
                            label: const Text('JSON'),
                            style: FilledButton.styleFrom(
                                backgroundColor: kPrimaryColor,
                                foregroundColor: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _sendToDatabase,
                            icon: const Icon(Icons.cloud_upload_rounded),
                            label: const Text('Send'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _clearAll,
                        icon: const Icon(Icons.delete_sweep_rounded),
                        label: const Text('Clear All Points'),
                        style: FilledButton.styleFrom(
                          backgroundColor: kErrorColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
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
