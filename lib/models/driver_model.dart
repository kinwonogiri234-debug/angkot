class DriverModel {
  String id;
  String userId;
  String vehicleNumber;
  String routeName;
  List<String> routeCoordinates;
  bool isAvailable;
  double rating;
  int totalTrips;
  double currentLatitude;
  double currentLongitude;

  DriverModel({
    required this.id,
    required this.userId,
    required this.vehicleNumber,
    required this.routeName,
    required this.routeCoordinates,
    this.isAvailable = false,
    this.rating = 5.0,
    this.totalTrips = 0,
    required this.currentLatitude,
    required this.currentLongitude,
  });
}