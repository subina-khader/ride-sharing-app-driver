import 'package:firebase_database/firebase_database.dart';

class DriverModel {
  String? phone;
  String? name;
  String? id;
  String? email;
  String? address;

  // Vehicle details
  String? vehicleModel;
  String? vehicleNumber;
  String? vehicleColor;
  String? vehicleType; // car / bike / CNG

  // Rating details
  double? ratings; // ex: 4.8
  int? totalRatings; // number of users who rated

  DriverModel({
    this.name,
    this.phone,
    this.email,
    this.id,
    this.address,
    this.vehicleModel,
    this.vehicleNumber,
    this.vehicleColor,
    this.vehicleType,
    this.ratings,
    this.totalRatings,
  });

  DriverModel.fromSnapshot(DataSnapshot snap) {
    phone = (snap.value as dynamic)["phone"];
    name = (snap.value as dynamic)["name"];
    id = snap.key;
    email = (snap.value as dynamic)["email"];
    address = (snap.value as dynamic)["address"];

    vehicleModel = (snap.value as dynamic)["vehicleModel"];
    vehicleNumber = (snap.value as dynamic)["vehicleNumber"];
    vehicleColor = (snap.value as dynamic)["vehicleColor"];
    vehicleType = (snap.value as dynamic)["vehicleType"];

    ratings = (snap.value as dynamic)["ratings"]?.toDouble();
    totalRatings = (snap.value as dynamic)["totalRatings"];
  }
}
