import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:trippo_mobile_app_driver/global/global.dart';
import 'package:trippo_mobile_app_driver/screens/main_screen.dart';

class CarInfoScreen extends StatefulWidget {
  const CarInfoScreen({super.key});

  @override
  State<CarInfoScreen> createState() => _CarInfoScreenState();
}

class _CarInfoScreenState extends State<CarInfoScreen> {
  final modelController = TextEditingController();
  final numberController = TextEditingController();
  final colorController = TextEditingController();
  String selectedVehicleType = "Car";

  final _formKey = GlobalKey<FormState>();

  void saveCarInfo() async {
    if (!_formKey.currentState!.validate()) {
      Fluttertoast.showToast(msg: "All fields are required");
      return;
    }
    Map<String, Object?> carData = {
      "vehicleModel": modelController.text.trim(),
      "vehicleNumber": numberController.text.trim(),
      "vehicleColor": colorController.text.trim(),
      "vehicleType": selectedVehicleType,
      "ratings": 5.0,
      "totalRatings": 0,
    };


    DatabaseReference driverRef = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(currentDriver!.uid);

    await driverRef.update(carData);

    Fluttertoast.showToast(msg: "Car Details Saved Successfully");

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (c) => MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool darkTheme =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Vehicle Details"),
        backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.blue,
      ),

      body: Padding(
        padding: const EdgeInsets.all(10),
        child: ListView(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Text(
                "Add Your Vehicle Details",
                style: TextStyle(
                  color: darkTheme ? Colors.amber.shade400 : Colors.blue,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 30),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  // VEHICLE MODEL
                  TextFormField(
                    controller: modelController,
                    inputFormatters: [LengthLimitingTextInputFormatter(50)],
                    decoration: InputDecoration(
                      hintText: 'Vehicle Model (Swift, Alto, Creta...)',
                      fillColor:
                      darkTheme ? Colors.grey[700] : Colors.grey[200],
                      filled: true,
                      prefixIcon: const Icon(Icons.directions_car),
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    validator: (text) {
                      if (text == null || text.trim().isEmpty) {
                        return "Enter vehicle model";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  // VEHICLE NUMBER
                  TextFormField(
                    controller: numberController,
                    inputFormatters: [LengthLimitingTextInputFormatter(20)],
                    decoration: InputDecoration(
                      hintText: 'Vehicle Number (KL07AB1234)',
                      fillColor:
                      darkTheme ? Colors.grey[700] : Colors.grey[200],
                      filled: true,
                      prefixIcon: const Icon(Icons.confirmation_number),
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    validator: (text) {
                      if (text == null || text.trim().isEmpty) {
                        return "Enter vehicle number";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  // VEHICLE COLOR
                  TextFormField(
                    controller: colorController,
                    inputFormatters: [LengthLimitingTextInputFormatter(30)],
                    decoration: InputDecoration(
                      hintText: 'Vehicle Color (White, Black...)',
                      fillColor:
                      darkTheme ? Colors.grey[700] : Colors.grey[200],
                      filled: true,
                      prefixIcon: const Icon(Icons.color_lens),
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    validator: (text) {
                      if (text == null || text.trim().isEmpty) {
                        return "Enter vehicle color";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  // VEHICLE TYPE DROPDOWN
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: darkTheme ? Colors.grey[700] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: selectedVehicleType,
                      decoration: const InputDecoration(border: InputBorder.none),
                      icon: const Icon(Icons.arrow_drop_down),
                      items: ["Car", "Bike", "CNG"].map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedVehicleType = value!;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 25),

                  // SUBMIT BUTTON
                  ElevatedButton(
                    onPressed: saveCarInfo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      darkTheme ? Colors.amber.shade400 : Colors.blue,
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    child: Text(
                      'Save Vehicle Info',
                      style: TextStyle(
                        color: darkTheme ? Colors.black : Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
