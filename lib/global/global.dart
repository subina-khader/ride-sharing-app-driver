import 'package:firebase_auth/firebase_auth.dart';
import 'package:trippo_mobile_app_driver/models/driver_model.dart';

final FirebaseAuth firebaseAuth =FirebaseAuth.instance;
User? currentDriver;

DriverModel? driverModelCurrentInfo;

