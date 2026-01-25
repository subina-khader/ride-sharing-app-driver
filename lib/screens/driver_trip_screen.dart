import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:trippo_mobile_app_driver/global/global.dart';
import 'package:trippo_mobile_app_driver/models/ride_request_model_driver.dart';
import 'package:trippo_mobile_app_driver/assistants/route_helper_driver.dart';

class DriverTripScreen extends StatefulWidget {
  final RideRequest rideRequest;

  const DriverTripScreen({Key? key, required this.rideRequest}) : super(key: key);

  @override
  State<DriverTripScreen> createState() => _DriverTripScreenState();
}

class _DriverTripScreenState extends State<DriverTripScreen> {
  LatLng? currentLocation;
  MapController mapController = MapController();
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<DatabaseEvent>? _rideRequestStream;

  String rideStatus = 'accepted'; // accepted, arrived, started, completed
  List<LatLng> routePoints = [];
  LatLng? destinationLocation;
  bool isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _listenToRideStatus();

    // Set initial destination to pickup location
    destinationLocation = LatLng(
      widget.rideRequest.pickupLatitude!,
      widget.rideRequest.pickupLongitude!,
    );

    rideStatus = widget.rideRequest.status ?? 'accepted';
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _rideRequestStream?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      currentLocation = LatLng(pos.latitude, pos.longitude);
    });

    _drawRoute();
    _listenToLocationChanges();
  }

  void _listenToLocationChanges() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position pos) {
      LatLng newLocation = LatLng(pos.latitude, pos.longitude);

      setState(() {
        currentLocation = newLocation;
      });

      // Update driver location in Firebase
      _updateDriverLocationInFirebase(newLocation);
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

  void _listenToRideStatus() {
    DatabaseReference requestRef = FirebaseDatabase.instance
        .ref()
        .child("rideRequests")
        .child(widget.rideRequest.rideRequestId!);

    _rideRequestStream = requestRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        RideRequest updatedRequest = RideRequest.fromSnapshot(event.snapshot);

        setState(() {
          rideStatus = updatedRequest.status ?? 'accepted';
        });
      }
    });
  }

  Future<void> _drawRoute() async {
    if (currentLocation == null || destinationLocation == null) return;

    setState(() {
      isLoadingRoute = true;
    });

    final routeData = await RouteHelper.getRoute(currentLocation!, destinationLocation!);

    if (routeData['success'] == true) {
      setState(() {
        routePoints = routeData['points'];
        isLoadingRoute = false;
      });

      _fitRouteBounds();
    } else {
      setState(() {
        isLoadingRoute = false;
      });
    }
  }

  void _fitRouteBounds() {
    if (routePoints.isEmpty || currentLocation == null) return;

    List<LatLng> allPoints = [currentLocation!, ...routePoints];

    double minLat = allPoints.first.latitude;
    double maxLat = allPoints.first.latitude;
    double minLng = allPoints.first.longitude;
    double maxLng = allPoints.first.longitude;

    for (var point in allPoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  Future<void> _handleArrived() async {
    print("✅ Driver arrived at pickup location");

    DatabaseReference requestRef = FirebaseDatabase.instance
        .ref()
        .child("rideRequests")
        .child(widget.rideRequest.rideRequestId!);

    await requestRef.update({
      'status': 'arrived',
    });

    setState(() {
      rideStatus = 'arrived';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Marked as arrived. Waiting for passenger...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _handleStartJourney() async {
    print("✅ Starting journey to destination");

    DatabaseReference requestRef = FirebaseDatabase.instance
        .ref()
        .child("rideRequests")
        .child(widget.rideRequest.rideRequestId!);

    await requestRef.update({
      'status': 'started',
    });

    // Update destination to drop-off location
    setState(() {
      rideStatus = 'started';
      destinationLocation = LatLng(
        widget.rideRequest.destinationLatitude!,
        widget.rideRequest.destinationLongitude!,
      );
    });

    // Redraw route to destination
    await _drawRoute();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Journey started! Navigate to destination'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _handleEndJourney() async {
    print("✅ Journey completed");

    DatabaseReference requestRef = FirebaseDatabase.instance
        .ref()
        .child("rideRequests")
        .child(widget.rideRequest.rideRequestId!);

    await requestRef.update({
      'status': 'completed',
    });

    // Set driver as available again
    DatabaseReference driverRef = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(currentDriver!.uid);

    await driverRef.update({
      'isAvailable': true,
    });

    // Show fare summary
    _showFareSummary();
  }

  void _showFareSummary() {
    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: darkTheme ? Colors.grey.shade900 : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 60,
              ),
              const SizedBox(height: 15),
              Text(
                'Trip Completed!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: darkTheme ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: Column(
                  children: [
                    Text(
                      'Fare Amount',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '₹${widget.rideRequest.fare?.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: darkTheme ? Colors.grey.shade800 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Distance:'),
                        Text(
                          RouteHelper.formatDistance(widget.rideRequest.distance ?? 0),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Passenger:'),
                        Text(
                          widget.rideRequest.userName ?? 'User',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Return to main screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.blue,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Done',
                  style: TextStyle(
                    color: darkTheme ? Colors.black : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    if (currentLocation == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.blue,
        title: Text(
          _getAppBarTitle(),
          style: TextStyle(
            color: darkTheme ? Colors.black : Colors.white,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: darkTheme ? Colors.black : Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
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

              // Route
              if (routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      strokeWidth: 4.0,
                      color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                    ),
                  ],
                ),

              MarkerLayer(
                markers: [
                  // Driver location
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

                  // Destination marker
                  if (destinationLocation != null)
                    Marker(
                      point: destinationLocation!,
                      width: 40,
                      height: 40,
                      child: Icon(
                        rideStatus == 'started'
                            ? Icons.location_on
                            : Icons.person_pin_circle,
                        color: rideStatus == 'started' ? Colors.red : Colors.green,
                        size: 40,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Loading overlay
          if (isLoadingRoute)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),

          // Bottom control panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: darkTheme ? Colors.grey.shade900 : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Trip Info
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: darkTheme ? Colors.grey.shade800 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.blue,
                              child: const Icon(Icons.person, color: Colors.white),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.rideRequest.userName ?? 'Passenger',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    widget.rideRequest.userPhone ?? '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${widget.rideRequest.fare?.toStringAsFixed(2) ?? '0'}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Divider(),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              rideStatus == 'started'
                                  ? Icons.location_on
                                  : Icons.person_pin_circle,
                              color: rideStatus == 'started' ? Colors.red : Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                rideStatus == 'started'
                                    ? widget.rideRequest.destinationAddress ?? 'Destination'
                                    : widget.rideRequest.pickupAddress ?? 'Pickup',
                                style: const TextStyle(fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Action Button
                  _buildActionButton(darkTheme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    switch (rideStatus) {
      case 'accepted':
        return 'Navigate to Pickup';
      case 'arrived':
        return 'Waiting for Passenger';
      case 'started':
        return 'Trip in Progress';
      default:
        return 'Trip';
    }
  }

  Widget _buildActionButton(bool darkTheme) {
    String buttonText;
    Color buttonColor;
    VoidCallback onPressed;

    switch (rideStatus) {
      case 'accepted':
        buttonText = 'Arrived at Pickup';
        buttonColor = Colors.green;
        onPressed = _handleArrived;
        break;
      case 'arrived':
        buttonText = 'Start Journey';
        buttonColor = darkTheme ? Colors.amber.shade400 : Colors.blue;
        onPressed = _handleStartJourney;
        break;
      case 'started':
        buttonText = 'End Journey';
        buttonColor = Colors.red;
        onPressed = _handleEndJourney;
        break;
      default:
        buttonText = 'Continue';
        buttonColor = Colors.grey;
        onPressed = () {};
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        buttonText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}