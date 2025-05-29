import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapWidget extends StatefulWidget {
  final LatLng? fromLocation;
  final LatLng? toLocation;
  final Function(LatLng, bool) onLocationSelected;
  final Function(String, bool) onLocationNameFetched;

  const MapWidget({
    super.key,
    required this.fromLocation,
    required this.toLocation,
    required this.onLocationSelected,
    required this.onLocationNameFetched,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  final MapController _mapController = MapController();
  static const _defaultLocation = LatLng(19.0760, 72.8777);

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _defaultLocation,
        initialZoom: 10.0,
        onTap: _onMapTapped,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.journey_predict',
        ),
        MarkerLayer(markers: _buildMarkers()),
        if (widget.fromLocation != null && widget.toLocation != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [widget.fromLocation!, widget.toLocation!],
                strokeWidth: 3,
                color: Colors.blue,
              ),
            ],
          ),
      ],
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    if (widget.fromLocation != null) {
      markers.add(
        Marker(
          point: widget.fromLocation!,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: Colors.green, size: 40),
        ),
      );
    }

    if (widget.toLocation != null) {
      markers.add(
        Marker(
          point: widget.toLocation!,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
        ),
      );
    }

    return markers;
  }

  void _onMapTapped(TapPosition tapPosition, LatLng location) {
    final isSelectingFrom =
        widget.fromLocation == null ||
        (widget.fromLocation != null && widget.toLocation != null);

    widget.onLocationSelected(location, isSelectingFrom);
    _getLocationName(location, isSelectingFrom);
  }

  Future<void> _getLocationName(LatLng location, bool isFromLocation) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              'https://nominatim.openstreetmap.org/reverse?'
              'lat=${location.latitude}&lon=${location.longitude}&'
              'format=json&addressdetails=1',
            ),
            headers: {'User-Agent': 'Flutter Journey Predict App'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final name = data['display_name']?.split(',')[0] ?? 'Selected Location';
        widget.onLocationNameFetched(name, isFromLocation);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching location name: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
