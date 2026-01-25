import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:trippo_mobile_app_driver/global/global.dart';
import 'package:trippo_mobile_app_driver/screens/driver_map_screen.dart';
import 'package:trippo_mobile_app_driver/screens/driver_trip_screen.dart';
import 'package:trippo_mobile_app_driver/models/ride_request_model_driver.dart';
import 'package:trippo_mobile_app_driver/models/driver_model.dart';
import 'package:trippo_mobile_app_driver/widgets/ride_request_dialog.dart';

class DriverMainScreen extends StatefulWidget {
  const DriverMainScreen({super.key});

  @override
  State<DriverMainScreen> createState() => _DriverMainScreenState();
}

class _DriverMainScreenState extends State<DriverMainScreen> {
  int _selectedIndex = 0;
  bool isDriverOnline = false;
  StreamSubscription<DatabaseEvent>? _rideRequestsStream;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
    _checkDriverStatus();
  }

  @override
  void dispose() {
    _rideRequestsStream?.cancel();
    super.dispose();
  }

  // Load driver data from Firebase
  Future<void> _loadDriverData() async {
    currentDriver = firebaseAuth.currentUser;

    if (currentDriver != null) {
      DatabaseReference driverRef = FirebaseDatabase.instance
          .ref()
          .child("drivers")
          .child(currentDriver!.uid);

      DatabaseEvent event = await driverRef.once();

      if (event.snapshot.value != null) {
        setState(() {
          driverModelCurrentInfo = DriverModel.fromSnapshot(event.snapshot);
        });
        print("✅ Driver data loaded: ${driverModelCurrentInfo!.name}");
        print("✅ Vehicle Type: ${driverModelCurrentInfo!.vehicleType}");
        print("✅ Vehicle Model: ${driverModelCurrentInfo!.vehicleModel}");
      } else {
        print("❌ Driver data not found in Firebase");
      }
    }
  }

  void _checkDriverStatus() async {
    if (currentDriver != null) {
      DatabaseReference driverRef = FirebaseDatabase.instance
          .ref()
          .child("drivers")
          .child(currentDriver!.uid);

      driverRef.child("status").once().then((snapshot) {
        if (snapshot.snapshot.value != null) {
          setState(() {
            isDriverOnline = snapshot.snapshot.value == "online";
          });

          if (isDriverOnline) {
            _listenToRideRequests();
          }
        }
      });
    }
  }

  void _listenToRideRequests() {
    if (currentDriver == null) {
      print("❌ currentDriver is null");
      return;
    }

    if (driverModelCurrentInfo == null) {
      print("❌ driverModelCurrentInfo is null - driver data not loaded");
      return;
    }

    print("🚗 Driver is now listening for ride requests...");
    print("🚗 Looking for ${driverModelCurrentInfo!.vehicleType} requests");

    DatabaseReference rideRequestsRef = FirebaseDatabase.instance
        .ref()
        .child("rideRequests");

    _rideRequestsStream = rideRequestsRef.onChildAdded.listen((event) {
      print("📢 Firebase event received!");

      if (event.snapshot.value != null) {
        try {
          RideRequest rideRequest = RideRequest.fromSnapshot(event.snapshot);

          print("📋 Request details:");
          print("   Status: ${rideRequest.status}");
          print("   Vehicle Type: ${rideRequest.vehicleType}");
          print("   Driver Vehicle Type: ${driverModelCurrentInfo!.vehicleType}");

          // Check if request matches
          if (rideRequest.status == 'waiting' &&
              rideRequest.vehicleType == driverModelCurrentInfo!.vehicleType) {

            print("🔔 NEW RIDE REQUEST RECEIVED!");
            print("   From: ${rideRequest.pickupAddress}");
            print("   To: ${rideRequest.destinationAddress}");
            print("   Fare: ₹${rideRequest.fare}");

            _showRideRequestDialog(rideRequest);
          } else {
            print("⏭️  Request skipped (status: ${rideRequest.status}, type: ${rideRequest.vehicleType})");
          }
        } catch (e) {
          print("❌ Error parsing ride request: $e");
        }
      }
    }, onError: (error) {
      print("❌ Firebase listener error: $error");
    });
  }

  void _showRideRequestDialog(RideRequest rideRequest) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RideRequestDialog(
        rideRequest: rideRequest,
        onAccept: () {
          Navigator.pop(context);
          _acceptRideRequest(rideRequest);
        },
        onCancel: () {
          Navigator.pop(context);
          print("❌ Ride request declined");
        },
      ),
    );
  }

  Future<void> _acceptRideRequest(RideRequest rideRequest) async {
    if (currentDriver == null || driverModelCurrentInfo == null) return;

    print("✅ Accepting ride request...");

    try {
      // Update ride request with driver info
      DatabaseReference requestRef = FirebaseDatabase.instance
          .ref()
          .child("rideRequests")
          .child(rideRequest.rideRequestId!);

      await requestRef.update({
        'status': 'accepted',
        'driverId': currentDriver!.uid,
        'driverName': driverModelCurrentInfo!.name,
        'driverPhone': driverModelCurrentInfo!.phone,
        'vehicleModel': driverModelCurrentInfo!.vehicleModel,
        'vehicleNumber': driverModelCurrentInfo!.vehicleNumber,
      });

      // Set driver as unavailable
      DatabaseReference driverRef = FirebaseDatabase.instance
          .ref()
          .child("drivers")
          .child(currentDriver!.uid);

      await driverRef.update({
        'isAvailable': false,
      });

      print("✅ Ride request accepted successfully!");
      print("✅ Driver set to unavailable");

      if (mounted) {
        // Navigate to trip screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DriverTripScreen(rideRequest: rideRequest),
          ),
        );
      }
    } catch (e) {
      print("❌ Error accepting ride: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accepting ride: $e')),
        );
      }
    }
  }

  void toggleDriverStatus() {
    setState(() {
      isDriverOnline = !isDriverOnline;
    });

    DatabaseReference driverRef = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(currentDriver!.uid);

    if (isDriverOnline) {
      driverRef.update({
        "status": "online",
        "isAvailable": true,
      });
      print("✅ Driver went online");
      _listenToRideRequests();
    } else {
      driverRef.update({
        "status": "offline",
        "isAvailable": false,
      });
      driverRef.child("location").remove();
      _rideRequestsStream?.cancel();
      print("⏸️  Driver went offline");
    }
  }

  void _onItemTapped(int index) {
    if (!isDriverOnline && index != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please go online first to access other sections"),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool darkTheme =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeScreen(darkTheme),
          _buildPlaceholderScreen("Earnings", darkTheme),
          _buildPlaceholderScreen("Ratings", darkTheme),
          _buildPlaceholderScreen("Account", darkTheme),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: darkTheme ? Colors.amber.shade400 : Colors.blue,
        unselectedItemColor: Colors.grey,
        backgroundColor: darkTheme ? Colors.grey.shade900 : Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'Ratings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeScreen(bool darkTheme) {
    if (!isDriverOnline) {
      return Container(
        color: Colors.black87,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off,
                size: 80,
                color: Colors.grey.shade600,
              ),
              const SizedBox(height: 20),
              Text(
                "You are offline",
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Go online to start receiving ride requests",
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: toggleDriverStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade800,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 60,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  "GO ONLINE",
                  style: TextStyle(
                    color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        const DriverMapScreen(),
        Positioned(
          top: 50,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      "You are Online",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: toggleDriverStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  child: const Text(
                    "GO OFFLINE",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderScreen(String title, bool darkTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            title == "Earnings"
                ? Icons.account_balance_wallet
                : title == "Ratings"
                ? Icons.star
                : Icons.person,
            size: 80,
            color: darkTheme ? Colors.amber.shade400 : Colors.blue,
          ),
          const SizedBox(height: 20),
          Text(
            "$title Screen",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: darkTheme ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Coming soon...",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}