import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:plantsapp/constanst.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _ctrl = Completer();
  Marker? _pickedMarker;
  String? _pickedAddress;
  String? _currentAddress;
  CameraPosition? _initialCamera;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _setupLocation();
  }

  Future<void> _setupLocation() async {
    try {
      // 1. Tentukan koordinat target (contoh: Monas Jakarta)
      const double targetLatitude = -7.810706569935517;
      const double targetLongitude = 110.32239733944637;
      final targetLatLng = LatLng(targetLatitude, targetLongitude);

      // 2. Set kamera awal
      _initialCamera = CameraPosition(target: targetLatLng, zoom: 16);

      // 3. Tambahkan marker di posisi awal
      final placemarks = await placemarkFromCoordinates(
        targetLatitude,
        targetLongitude,
      );

      final p = placemarks.first;
      setState(() {
        _pickedMarker = Marker(
          markerId: const MarkerId('initial_marker'),
          position: targetLatLng,
          infoWindow: InfoWindow(
            title: p.name?.isNotEmpty == true ? p.name : 'Lokasi Toko',
            snippet: '${p.street}, ${p.locality}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ), // Warna hijau untuk marker awal
        );

        _currentAddress = '${p.name},${p.locality},${p.country}';
        _pickedAddress = _currentAddress; // Set alamat awal
      });
    } catch (e) {
      _initialCamera = const CameraPosition(target: LatLng(0, 0), zoom: 2);
      setState(() {});
      print(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<Position> getPermissions() async {
    // 1. Cek Service GPS
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw 'Location Service Belum Aktif';
    }

    // 2. Cek & Minta Permission
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

    // 3. Semua Oke, Ambil Lokasi
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
      );
    });
    final ctrl = await _ctrl.future;
    await ctrl.animateCamera(CameraUpdate.newLatLngZoom(latlng, 16));

    setState(() {
      _pickedAddress =
          '${p.name}, ${p.street}, ${p.locality}, ${p.country}, ${p.postalCode}';
    });
  }

  // void _confirmSelection() {
  //   showDialog(
  //     context: context,
  //     builder:
  //         (_) => AlertDialog(
  //           title: const Text('Konfirmasi Alamat'),
  //           content: Text(_pickedAddress ?? ''),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.pop(context),
  //               child: const Text('Batal'),
  //             ),
  //             ElevatedButton(
  //               onPressed: () {
  //                 Navigator.pop(context);
  //                 Navigator.pop(context, _pickedAddress);
  //               },
  //               child: const Text("Pilih"),
  //             ),
  //           ],
  //         ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    if (_initialCamera == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        title: const Text("Alamat Toko", style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: _initialCamera!,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              mapType: MapType.satellite,
              compassEnabled: true,
              tiltGesturesEnabled: false,
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              rotateGesturesEnabled: true,
              trafficEnabled: true,
              buildingsEnabled: true,
              indoorViewEnabled: true,
              onMapCreated: (GoogleMapController ctrl) {
                _ctrl.complete(ctrl);
              },

              markers: _pickedMarker != null ? {_pickedMarker!} : {},
              onTap: _onTap,
            ),
            Positioned(
              top: 250,
              left: 56,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(_currentAddress ?? 'Kosong'),
              ),
            ),
            if (_pickedAddress != null)
              Positioned(
                bottom: 120,
                left: 16,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _pickedAddress!,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      // floatingActionButton: Column(
      //   mainAxisAlignment: MainAxisAlignment.end,
      //   crossAxisAlignment: CrossAxisAlignment.start,
      //   children: [
      //     const SizedBox(height: 8),
      //     if (_pickedAddress != null)
      //       FloatingActionButton.extended(
      //         onPressed: _confirmSelection,
      //         heroTag: "Confirm",
      //         label: const Text("Pilih Alamat"),
      //       ),

      //     const SizedBox(height: 8),
      //     if (_pickedAddress != null)
      //       // Clear
      //       FloatingActionButton.extended(
      //         heroTag: 'Clear',
      //         label: const Text("Hapus Alamat"),
      //         onPressed: () {
      //           setState(() {
      //             _pickedAddress = null;
      //             _pickedMarker = null;
      //           });
      //         },
      //       ),
      //   ],
      // ),
    );
  }
}
