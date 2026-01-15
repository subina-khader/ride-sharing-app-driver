import 'package:firebase_database/firebase_database.dart';
import 'package:trippo_mobile_app_driver/global/global.dart';
import 'package:trippo_mobile_app_driver/models/driver_model.dart';
import 'package:trippo_mobile_app_driver/global/global.dart';
import 'package:firebase_database/firebase_database.dart';

class AssistantMethods{
  static void readCurrentOnlineUserInfo(){
    currentDriver  =firebaseAuth.currentUser;
    DatabaseReference driverRef = FirebaseDatabase.instance.ref().child("drivers").child(currentDriver!.uid);
    driverRef.once().then((snap){
      if(snap.snapshot.value!=null){
        driverModelCurrentInfo = DriverModel.fromSnapshot(snap.snapshot);
      }
    });
  }












































}