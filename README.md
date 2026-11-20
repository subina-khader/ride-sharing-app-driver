
# 🚖 Trippo – Driver App

Trippo Driver is a Flutter-based driver application developed as part of the Trippo ride-booking platform.

It allows registered drivers to manage their availability, receive ride requests in real time, accept bookings, navigate to passenger pickup and destination locations, and complete trips while sharing their live location.

The application uses Firebase Realtime Database for real-time communication between riders and drivers, and OpenStreetMap with OSRM for map visualization and route calculation.

## ✨ Features

### 🔐 Driver Authentication
- Driver registration with name, email, phone number, and address.
- Login using email and password.
- Forgot password functionality with email reset link.
- Driver account verification through Firebase Realtime Database.
- Prevents rider accounts from accessing the driver application.

### 🚗 Vehicle Registration
- Enter vehicle model.
- Enter vehicle registration number.
- Select vehicle color.
- Select vehicle type (Car, Bike, or CNG).
- Store vehicle information in Firebase Realtime Database.

### 🟢 Driver Availability
- Toggle between Online and Offline modes.
- Update driver availability status in Firebase.
- Remove live location data when going offline.
- Receive ride requests when online.

### 📩 Ride Request Management
- Listen for new ride requests using Firebase Realtime Database child events.
- Receive ride requests matching the driver's vehicle type.
- Display incoming ride request details.
- Accept available ride requests.
- Update ride status and driver details in Firebase.
- Navigate to the trip screen after accepting a request.

### 📍 Live Location Tracking
- Track the driver's current GPS location.
- Stream location updates using Geolocator.
- Update latitude, longitude, and timestamp in Firebase Realtime Database.
- Display the driver's current position on OpenStreetMap.
- Recenter the map to the current location.

### 🛣️ Trip Management
- Navigate to passenger pickup location.
- Update ride status to Arrived.
- Start the journey.
- Navigate to the passenger's destination.
- Complete the ride.
- Restore driver availability after completing a trip.
- Listen to ride status changes in real time.

### 💰 Fare Summary
- Calculate ride distance and duration.
- Display fare after completing a trip.
- Show passenger name and trip information in the fare summary dialog.

### 📊 Driver Dashboard
- Home tab with driver map and availability controls.
- Earnings tab (coming soon).
- Ratings tab (coming soon).
- Account tab (coming soon).

## 🛠️ Tech Stack

| Technology | Purpose |
|---|---|
| Flutter & Dart | Cross-platform application development |
| Firebase Core | Firebase initialization |
| Firebase Authentication | Driver authentication |
| Firebase Realtime Database | Driver profiles, ride management, and live location updates |
| Firebase Storage | Cloud storage integration |
| Firebase Cloud Messaging | Push notification integration |
| Flutter Map | Interactive map visualization |
| OpenStreetMap | Map tiles |
| Nominatim | Location search and geocoding |
| OSRM | Driving route calculation |
| Geolocator | GPS tracking and location updates |
| Geocoding | Address and coordinate conversion |
| HTTP | API communication |


## 🔥 Firebase Database Structure

The application uses Firebase Realtime Database to manage driver profiles, availability, location, and ride information.

```text
drivers/
  └── driverId/
      ├── id
      ├── name
      ├── email
      ├── phone
      ├── address
      ├── vehicleModel
      ├── vehicleNumber
      ├── vehicleColor
      ├── vehicleType
      ├── ratings
      ├── totalRatings
      ├── status
      ├── isAvailable
      └── location/
          ├── latitude
          ├── longitude
          └── timestamp

rideRequests/
  └── rideRequestId/
      ├── userId
      ├── userName
      ├── userPhone
      ├── pickupAddress
      ├── destinationAddress
      ├── pickupLatitude
      ├── pickupLongitude
      ├── destinationLatitude
      ├── destinationLongitude
      ├── vehicleType
      ├── fare
      ├── distance
      ├── duration
      ├── status
      ├── driverId
      ├── driverName
      ├── driverPhone
      ├── vehicleModel
      ├── vehicleNumber
      └── requestTime
```

## 🔄 Ride Lifecycle

A ride progresses through the following statuses:

1. **Waiting:** Rider creates a new ride request.
2. **Accepted:** Driver accepts the ride request.
3. **Arrived:** Driver reaches the passenger's pickup location.
4. **Started:** Driver starts the journey.
5. **Completed:** Driver reaches the destination and completes the ride.
6. **Cancelled:** Ride is cancelled.

## 📍 Live Location Tracking Workflow

1. Driver switches to Online mode.
2. The application requests location permissions.
3. Geolocator retrieves the driver's current GPS position.
4. Location updates are streamed using `getPositionStream()`.
5. The latest latitude, longitude, and timestamp are stored in Firebase.
6. The driver's current position is displayed on the map.
7. Location tracking continues during the trip.

## 🌐 External APIs & Services

- **OpenStreetMap:** Provides map tiles for map visualization.
- **Nominatim:** Searches locations and returns geographic coordinates.
- **OSRM:** Calculates driving routes, distance, and estimated travel duration.

## 🚀 Getting Started

### Prerequisites
- Flutter SDK
- Dart SDK
- Android Studio or VS Code
- Firebase project

### Installation

1. Clone the repository:

```bash
git clone https://github.com/subina-khader/ride-sharing-app-driver
```

2. Navigate to the project directory:

```bash
cd ride-sharing-app-driver
```

3. Install dependencies:

```bash
flutter pub get
```

4. Configure Firebase for your Android/iOS application.

5. Add the required Firebase configuration files.

6. Enable Firebase Authentication and Realtime Database.

7. Run the application:

```bash
flutter run
```

## 📌 Project Information

- **Project Name:** Trippo Driver App
- **Package Name:** trippo_mobile_app_driver
- **Version:** 1.0.0+1
- **Dart SDK:** ^3.8.1

---

**Trippo – Drive Your Journey! 🚖**
