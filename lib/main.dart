import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const AreaxApp());
}

const Color kPrimaryColor = Color(0xFF96A78D); // Primary: Greenish-Grey
const Color kErrorColor = Color(0xFFED3F27); // Error/Danger: Bright Red
const Color kSecondaryColor = Color(0xFFD9E9CF); // Secondary: Light Mint/Cream
const Color kBackgroundColor = Color(0xFFF0F0F0); // Background: Light Grey

const String kApiUrl = "https://areax-bridge.vercel.app";

class AreaxApp extends StatelessWidget {
  const AreaxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Areax',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimaryColor,
          primary: kPrimaryColor,
          secondary: kSecondaryColor,
          error: kErrorColor,
          background: kBackgroundColor,
          surface: Colors.white, 
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: kBackgroundColor, 
        appBarTheme: const AppBarTheme(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 4.0,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            foregroundColor: Colors.white, 
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          fillColor: Colors.white,
          filled: true,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide.none,
          ),
          prefixIconColor: kPrimaryColor,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        ),
      ),
      home: const BottomBarNavigator(),
    );
  }
}

class BottomBarNavigator extends StatefulWidget {
  const BottomBarNavigator({super.key});

  @override
  State<BottomBarNavigator> createState() => _BottomBarNavigatorState();
}

class _BottomBarNavigatorState extends State<BottomBarNavigator> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    MapScreen(),
    AreaListScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface, 
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              spreadRadius: 2,
              blurRadius: 10,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24.0), 
            topRight: Radius.circular(24.0),
          ),
          child: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.map_rounded),
                label: 'Area Select',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.list_alt_rounded),
                label: 'Area List',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Theme.of(context).colorScheme.primary, // #96A78D
            unselectedItemColor: Colors.grey.shade600,
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }
}

class AreaListScreen extends StatefulWidget {
  const AreaListScreen({super.key});

  @override
  State<AreaListScreen> createState() => _AreaListScreenState();
}

class _AreaListScreenState extends State<AreaListScreen> {
  late Future<List<Map<String, dynamic>>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchDataWithoutCoordinates();
  }

  Future<List<Map<String, dynamic>>> _fetchDataWithoutCoordinates() async {
    try {
      final response = await http.get(Uri.parse('$kApiUrl/fetch_data'));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.cast<Map<String, dynamic>>();
      } else {
        throw Exception(
            'Failed to load data. Status: ${response.statusCode}. Body: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network or parsing error: $e');
    }
  }

  void _refreshData() {
    setState(() {
      _dataFuture = _fetchDataWithoutCoordinates();
    });
  }

  void _showConfirmation(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Areas to be Mapped'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshData,
            tooltip: 'Refresh List',
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 60, color: kErrorColor),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading data: ${snapshot.error.toString()}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 60, color: kPrimaryColor),
                    const SizedBox(height: 16),
                    Text(
                      'All pending areas have been mapped!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final item = snapshot.data![index];
                final String docId = item['_id'] ?? 'N/A'; 
                final Map<String, dynamic> entities = item['entities'] ?? {};
                final String claimStatus = entities['claim_status'] ?? 'N/A';
                final String pattaHolder = entities['patta_holder'] ?? 'N/A';
                final String documentId = entities['document_id'] ?? 'N/A';
                final String fileName = item['fileName'] ?? 'N/A';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 4.0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Document ID:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                docId,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: kPrimaryColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 20),
                              color: kPrimaryColor,
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: docId));
                                _showConfirmation('Document ID copied!');
                              },
                              tooltip: 'Copy Document ID',
                            ),
                          ],
                        ),
                        const Divider(height: 16, thickness: 1, color: kBackgroundColor),
                        
                        _DataRow(label: 'Claim Status', value: claimStatus),
                        _DataRow(label: 'Patta Holder', value: pattaHolder),
                        _DataRow(label: 'Document ID (Entity)', value: documentId),
                        _DataRow(label: 'File Name', value: fileName),
                        
                        const SizedBox(height: 16),
                        
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              _showConfirmation('Opening map for $docId...');
                            },
                            icon: const Icon(Icons.map_rounded),
                            label: const Text('Start Mapping Coordinates'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;

  const _DataRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140, 
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
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
      _idController.clear();
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

      final tapPosition = TapPosition(Offset.zero, Offset.zero);
      _onMapTapped(tapPosition, latlng);

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
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
