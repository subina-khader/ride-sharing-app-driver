import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:trippo_mobile_app_driver/global/global.dart';

class DriverMapScreen extends StatefulWidget {
  const DriverMapScreen({super.key});

  @override
  State<DriverMapScreen> createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends State<DriverMapScreen> {
  LatLng? currentLocation;
  MapController mapController = MapController(); // FIXED: Removed final and initialized directly
  StreamSubscription<Position>? _positionStream;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    await _checkPermission();
    await _getCurrentLocation();
    _listenToLocationChanges();
  }

  Future<void> _checkPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permissions are permanently denied, cannot request.',
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      LatLng loc = LatLng(pos.latitude, pos.longitude);

      setState(() {
        currentLocation = loc;
        isLoading = false;
      });

      // Update driver location in Firebase
      _updateDriverLocationInFirebase(loc);

      // Center map on current location
      mapController.move(loc, 15.0);
    } catch (e) {
      print("Error getting location: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void _listenToLocationChanges() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position pos) {
      LatLng newLocation = LatLng(pos.latitude, pos.longitude);

      setState(() {
        currentLocation = newLocation;
      });

      // Update driver location in Firebase in real-time
      _updateDriverLocationInFirebase(newLocation);

      // Smoothly move map to new location
      mapController.move(newLocation, mapController.camera.zoom);
    });
  }

  void _updateDriverLocationInFirebase(LatLng location) {
    if (currentDriver != null) {
      DatabaseReference driverRef = FirebaseDatabase.instance
          .ref()
          .child("drivers")
          .child(currentDriver!.uid)
          .child("location");

      driverRef.set({
        "latitude": location.latitude,
        "longitude": location.longitude,
        "timestamp": DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || currentLocation == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Stack(
      children: [
        // Map
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: currentLocation!,
            initialZoom: 15.0,
            maxZoom: 18.0,
            minZoom: 3.0,
          ),
          children: [
            TileLayer(
              urlTemplate:
              'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'com.example.trippo_mobile_app_driver',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: currentLocation!,
                  width: 60,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.navigation,
                      color: Colors.blue,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        // Recenter button
        Positioned(
          bottom: 100,
          right: 20,
          child: FloatingActionButton(
            onPressed: () {
              if (currentLocation != null) {
                mapController.move(currentLocation!, 15.0);
              }
            },
            backgroundColor: Colors.white,
            child: const Icon(
              Icons.my_location,
              color: Colors.blue,
            ),
          ),
        ),
      ],
    );
  }
}