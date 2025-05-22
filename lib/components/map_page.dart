import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:plantsapp/constanst.dart';
import 'package:url_launcher/url_launcher.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _ctrl = Completer();
  Marker? _pickedMarker;
  Marker? _currentLocationMarker;
  String? _pickedAddress;
  String? _currentAddress;
  CameraPosition? _initialCamera;
  Position? _currentPosition;
  PolylinePoints polylinePoints = PolylinePoints();
  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  String googleAPiKey =
      "AIzaSyDibqZy4BQxwm3oM1BS57VmEEhKH_Ug1fU"; // Replace with your API key

  @override
  void initState() {
    super.initState();
    _setupLocation();
  }

  Future<void> _setupLocation() async {
    try {
      // Get current position
      _currentPosition = await getPermissions();

      // Set target location (example: Monas Jakarta)
      const double targetLatitude = -7.810706569935517;
      const double targetLongitude = 110.32239733944637;
      final targetLatLng = LatLng(targetLatitude, targetLongitude);

      // Set initial camera position
      _initialCamera = CameraPosition(target: targetLatLng, zoom: 16);

      // Get addresses
      final currentPlacemarks = await placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      final currentP = currentPlacemarks.first;
      _currentAddress = '${currentP.name}, ${currentP.locality}';

      final targetPlacemarks = await placemarkFromCoordinates(
        targetLatitude,
        targetLongitude,
      );
      final targetP = targetPlacemarks.first;
      final targetAddress = '${targetP.name}, ${targetP.locality}';

      setState(() {
        // Add target marker (red)
        _pickedMarker = Marker(
          markerId: const MarkerId('target_location'),
          position: targetLatLng,
          infoWindow: InfoWindow(title: 'Lokasi Toko', snippet: targetAddress),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        );

        // Add current location marker (blue)
        _currentLocationMarker = Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          infoWindow: InfoWindow(
            title: 'Posisi Anda',
            snippet: _currentAddress,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        );

        _pickedAddress = targetAddress;
      });

      // Get route
      await _getPolyline(targetLatLng);
    } catch (e) {
      _initialCamera = const CameraPosition(target: LatLng(0, 0), zoom: 2);
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _getPolyline(LatLng destination) async {
    try {
      polylineCoordinates.clear();

      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleAPiKey,
        PointLatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        PointLatLng(destination.latitude, destination.longitude),
        travelMode: TravelMode.driving,
      );

      if (result.points.isNotEmpty) {
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }

        setState(() {
          PolylineId id = const PolylineId('poly');
          Polyline polyline = Polyline(
            polylineId: id,
            color: Colors.blue,
            points: polylineCoordinates,
            width: 5,
          );
          polylines[id] = polyline;
        });
      }
    } catch (e) {
      print('Error getting polyline: $e');
    }
  }

  Future<Position> getPermissions() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw 'Location Service Belum Aktif';
    }

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        throw 'Izin Lokasi Ditolak';
      }
    }
    if (perm == LocationPermission.deniedForever) {
      throw 'Izin Lokasi Ditolak Permanen';
    }

    return Geolocator.getCurrentPosition();
  }

  Future<void> _onTap(LatLng latlng) async {
    final placemarks = await placemarkFromCoordinates(
      latlng.latitude,
      latlng.longitude,
    );

    final p = placemarks.first;
    setState(() {
      _pickedMarker = Marker(
        markerId: const MarkerId('picked'),
        position: latlng,
        infoWindow: InfoWindow(
          title: p.name?.isNotEmpty == true ? p.name : 'Lokasi Pilih',
          snippet: '${p.street}, ${p.locality}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );
    });

    final ctrl = await _ctrl.future;
    await ctrl.animateCamera(CameraUpdate.newLatLngZoom(latlng, 16));

    setState(() {
      _pickedAddress = '${p.name}, ${p.street}, ${p.locality}, ${p.country}';
    });

    // Get new route when user taps on map
    await _getPolyline(latlng);
  }

  void _openGoogleMaps() async {
    if (_pickedMarker != null && _currentPosition != null) {
      final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&origin=${_currentPosition!.latitude},${_currentPosition!.longitude}'
        '&destination=${_pickedMarker!.position.latitude},${_pickedMarker!.position.longitude}'
        '&travelmode=driving',
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka Google Maps')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initialCamera == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Prepare markers set
    Set<Marker> markers = {};
    if (_pickedMarker != null) markers.add(_pickedMarker!);
    if (_currentLocationMarker != null) markers.add(_currentLocationMarker!);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        title: const Text("Alamat Toko", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.directions, color: Colors.white),
            onPressed: _openGoogleMaps,
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: _initialCamera!,
              myLocationEnabled: true,
              myLocationButtonEnabled:
                  false, // Disable default my location button
              mapType: MapType.normal,
              compassEnabled: true,
              tiltGesturesEnabled: false,
              zoomGesturesEnabled: true,
              polylines: Set<Polyline>.of(polylines.values),
              markers: markers,
              onMapCreated: (GoogleMapController ctrl) {
                _ctrl.complete(ctrl);
              },
              onTap: _onTap,
            ),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: "Cari lokasi...",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.search, color: kPrimaryColor),
                        onPressed: () {
                          // Implement search functionality
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_pickedAddress != null)
              Positioned(
                bottom: 120,
                left: 16,
                right: 16,
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Lokasi Toko",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: kPrimaryColor,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(_pickedAddress!),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          onPressed: _openGoogleMaps,
                          child: const Text(
                            "Buka di Google Maps",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Custom my location button positioned at bottom left
            Positioned(
              left: 16,
              bottom: 16,
              child: FloatingActionButton(
                backgroundColor: kPrimaryColor,
                mini: true,
                onPressed: () async {
                  if (_currentPosition != null) {
                    final ctrl = await _ctrl.future;
                    await ctrl.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        16,
                      ),
                    );
                  }
                },
                child: const Icon(Icons.my_location, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
