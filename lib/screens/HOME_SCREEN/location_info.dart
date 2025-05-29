import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class LocationDisplay extends StatefulWidget {
  final Function(double latitude, double longitude)? onLocationChanged;
  const LocationDisplay({super.key, this.onLocationChanged});

  @override
  State<LocationDisplay> createState() => _LocationDisplayState();
}

class _LocationDisplayState extends State<LocationDisplay> {
  String _currentLocation = 'Loading...';
  String _currentDate = '';
  bool _isLoading = true;
  bool _isOnline = true;
  LatLng? _currentLatLng;

  static const _defaultLocation = 'Mumbai';
  static const _defaultCoords = LatLng(19.0760, 72.8777);
  static const _timeout = Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _updateDate();
    await _checkConnectivity();
    await _loadSavedLocation();
    if (_isOnline) await _getCurrentLocationSafely();
  }

  Future<void> _checkConnectivity() async {
    try {
      _isOnline =
          await Connectivity().checkConnectivity() != ConnectivityResult.none;
    } catch (e) {
      _isOnline = false;
    }
    if (mounted) setState(() {});
  }

  void _updateDate() {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final now = DateTime.now();
    final suffix = (day) => day >= 11 && day <= 13
        ? 'th'
        : ['th', 'st', 'nd', 'rd'][day % 10 > 3 ? 0 : day % 10];

    setState(() {
      _currentDate =
          '${now.day}${suffix(now.day)} ${months[now.month - 1]}, ${days[now.weekday - 1]}';
    });
  }

  Future<void> _loadSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final location = prefs.getString('last_location') ?? _defaultLocation;
      final lat = prefs.getDouble('last_latitude') ?? _defaultCoords.latitude;
      final lng = prefs.getDouble('last_longitude') ?? _defaultCoords.longitude;

      setState(() {
        _currentLocation = location;
        _currentLatLng = LatLng(lat, lng);
        _isLoading = false;
      });

      if (!prefs.containsKey('last_location')) {
        await _saveLocation(
          _defaultLocation,
          _defaultCoords.latitude,
          _defaultCoords.longitude,
        );
      }
    } catch (e) {
      _setDefaultLocation();
    }
  }

  void _setDefaultLocation() {
    setState(() {
      _currentLocation = _defaultLocation;
      _currentLatLng = _defaultCoords;
      _isLoading = false;
    });
  }

  Future<void> _getCurrentLocationSafely() async {
    if (!_isOnline || !await Geolocator.isLocationServiceEnabled()) return;

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever)
        return;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: _timeout,
      );
      await _updateLocationFromPosition(position);
    } catch (e) {}
  }

  Future<void> _updateLocationFromPosition(Position position) async {
    String locationName = _defaultLocation;

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(_timeout);
      if (placemarks.isNotEmpty) {
        locationName =
            placemarks.first.locality ??
            placemarks.first.subAdministrativeArea ??
            placemarks.first.administrativeArea ??
            _defaultLocation;
      }
    } catch (e) {}

    setState(() {
      _currentLocation = locationName;
      _currentLatLng = LatLng(position.latitude, position.longitude);
    });

    await _saveLocation(locationName, position.latitude, position.longitude);
    widget.onLocationChanged?.call(position.latitude, position.longitude);
  }

  Future<void> _saveLocation(
    String location,
    double latitude,
    double longitude,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setString('last_location', location),
        prefs.setDouble('last_latitude', latitude),
        prefs.setDouble('last_longitude', longitude),
      ]);
    } catch (e) {}
  }

  void _openMapSelector() {
    if (!_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Map selection requires internet connection'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapSelectorScreen(
          currentLocation: _currentLatLng,
          onLocationSelected: (location, locationName) async {
            setState(() {
              _currentLocation = locationName;
              _currentLatLng = location;
            });
            await _saveLocation(
              locationName,
              location.latitude,
              location.longitude,
            );
            widget.onLocationChanged?.call(
              location.latitude,
              location.longitude,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openMapSelector,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: _isOnline ? Colors.red : Colors.grey,
                  size: 30,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isLoading
                        ? 'Loading...'
                        : _currentLocation.length > 7
                        ? '${_currentLocation.substring(0, 6)}...'
                        : _currentLocation,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 25,
                    ),
                  ),
                ),
                if (!_isOnline)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.offline_bolt,
                      color: Colors.white70,
                      size: 16,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              _currentDate,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class MapSelectorScreen extends StatefulWidget {
  final LatLng? currentLocation;
  final Function(LatLng, String) onLocationSelected;

  const MapSelectorScreen({
    super.key,
    required this.currentLocation,
    required this.onLocationSelected,
  });

  @override
  State<MapSelectorScreen> createState() => _MapSelectorScreenState();
}

class _MapSelectorScreenState extends State<MapSelectorScreen> {
  final _mapController = MapController();
  final _searchController = TextEditingController();

  LatLng? _selectedLocation;
  String _selectedLocationName = '';
  bool _isSearching = false;
  bool _isOnline = true;
  List<SearchResult> _searchResults = [];

  static const _defaultLocation = LatLng(19.0760, 72.8777);
  static const _timeout = Duration(seconds: 10);

  // Debounce timer for search
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.currentLocation ?? _defaultLocation;
    _getLocationName(_selectedLocation!);
    _checkConnectivity();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    try {
      _isOnline =
          await Connectivity().checkConnectivity() != ConnectivityResult.none;
    } catch (e) {
      _isOnline = false;
    }
    if (mounted) setState(() {});
  }

  Future<void> _getLocationName(LatLng location) async {
    setState(() => _isSearching = true);

    String locationName = 'Selected Location';
    if (_isOnline) {
      try {
        final placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        ).timeout(_timeout);
        if (placemarks.isNotEmpty) {
          locationName =
              placemarks.first.locality ??
              placemarks.first.subAdministrativeArea ??
              placemarks.first.administrativeArea ??
              'Selected Location';
        }
      } catch (e) {}
    }

    setState(() {
      _selectedLocationName = locationName;
      _isSearching = false;
    });
  }

  void _onMapTapped(TapPosition tapPosition, LatLng location) {
    setState(() {
      _selectedLocation = location;
      _searchResults.clear();
    });
    _getLocationName(location);
  }

  Future<void> _searchLocation([String? query]) async {
    final searchQuery = query ?? _searchController.text;
    if (searchQuery.isEmpty || !_isOnline) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final response = await http
          .get(
            Uri.parse(
              'https://nominatim.openstreetmap.org/search?'
              'q=${Uri.encodeComponent(searchQuery)}&'
              'format=json&limit=5&addressdetails=1',
            ),
            headers: {'User-Agent': 'Flutter Location App'},
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        setState(() {
          _searchResults = data
              .map((item) => SearchResult.fromJson(item))
              .toList();
          _isSearching = false;
        });

        if (_searchResults.isEmpty &&
            mounted &&
            searchQuery == _searchController.text) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No results found for: $searchQuery')),
          );
        }
      }
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  void _onSearchChanged(String value) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    if (value.isEmpty) {
      setState(() => _searchResults.clear());
      return;
    }

    // Start new timer for debounced search
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchLocation(value);
    });
  }

  void _selectSearchResult(SearchResult result) {
    final location = LatLng(result.lat, result.lon);
    setState(() {
      _selectedLocation = location;
      _selectedLocationName = result.displayName;
      _searchResults.clear();
    });
    _searchController.clear();
    _mapController.move(location, 15.0);

    // Hide keyboard
    FocusScope.of(context).unfocus();
  }

  Future<void> _getCurrentLocation() async {
    if (!_isOnline) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Current location requires internet connection'),
          ),
        );
      }
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: _timeout,
      );

      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedLocation = latLng;
        _searchResults.clear();
      });

      _mapController.move(latLng, 15.0);
      _getLocationName(latLng);
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map as background
          _buildMap(),
          // Top search overlay
          _buildSearchOverlay(),
          // Bottom panel
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomPanel()),
        ],
      ),
    );
  }

  Widget _buildSearchOverlay() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Column(
        children: [
          // Main search card
          Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(28),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Back button
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    color: Colors.grey[700],
                  ),
                  // Search field
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      enabled: _isOnline,
                      decoration: InputDecoration(
                        hintText: _isOnline
                            ? 'Search for places'
                            : 'Search requires internet',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                      style: const TextStyle(fontSize: 16),
                      onChanged: _onSearchChanged,
                      onSubmitted: (_) => _searchLocation(),
                    ),
                  ),
                  // Loading or clear button
                  if (_isSearching)
                    Container(
                      padding: const EdgeInsets.all(12),
                      child: const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else if (_searchController.text.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchResults.clear());
                      },
                      icon: const Icon(Icons.clear),
                      color: Colors.grey[600],
                    ),
                  // Current location button
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Material(
                      color: _isOnline ? Colors.blue : Colors.grey,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _isOnline ? _getCurrentLocation : null,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Offline indicator
                  if (!_isOnline)
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.offline_bolt,
                            color: Colors.orange[700],
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Offline',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Search results dropdown
          if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: 8),
            Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _searchResults.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: Colors.grey[200], indent: 56),
                  itemBuilder: (context, index) {
                    final result = _searchResults[index];
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: Colors.blue[600],
                          size: 20,
                        ),
                      ),
                      title: Text(
                        result.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        result.displayName,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      onTap: () => _selectSearchResult(result),
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _selectedLocation ?? _defaultLocation,
        initialZoom: 15.0,
        onTap: _onMapTapped,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.location_app',
          maxZoom: 19,
        ),
        if (_selectedLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _selectedLocation!,
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.place, color: Colors.blue[600], size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Location',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isSearching
                          ? 'Getting location name...'
                          : _selectedLocationName.isEmpty
                          ? 'Tap on map to select location'
                          : _selectedLocationName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedLocation != null && !_isSearching
                  ? () {
                      widget.onLocationSelected(
                        _selectedLocation!,
                        _selectedLocationName.isEmpty
                            ? 'Selected Location'
                            : _selectedLocationName,
                      );
                      Navigator.pop(context);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: Text(
                'Confirm Location',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SearchResult {
  final String name;
  final String displayName;
  final double lat;
  final double lon;

  const SearchResult({
    required this.name,
    required this.displayName,
    required this.lat,
    required this.lon,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      name: json['name'] ?? json['display_name'] ?? 'Unknown',
      displayName: json['display_name'] ?? '',
      lat: double.parse(json['lat']),
      lon: double.parse(json['lon']),
    );
  }
}
