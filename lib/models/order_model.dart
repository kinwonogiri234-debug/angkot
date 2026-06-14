class OrderModel {
  String id;
  String userId;
  String driverId;
  String pickupLocation;
  String dropoffLocation;
  LatLng pickupCoordinates;
  LatLng dropoffCoordinates;
  double distance;
  double price;
  String status; // pending, accepted, arrived, started, completed, cancelled
  DateTime orderTime;
  DateTime? pickupTime;
  DateTime? dropoffTime;
  String paymentMethod; // ewallet, bank_transfer, qris
  bool isPaid;

  OrderModel({
    required this.id,
    required this.userId,
    required this.driverId,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.pickupCoordinates,
    required this.dropoffCoordinates,
    required this.distance,
    required this.price,
    required this.status,
    required this.orderTime,
    this.pickupTime,
    this.dropoffTime,
    required this.paymentMethod,
    this.isPaid = false,
  });
}

class LatLng {
  final double latitude;
  final double longitude;
  
  LatLng(this.latitude, this.longitude);
}