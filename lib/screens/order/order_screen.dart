import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


class OrderScreen extends StatefulWidget {
  const OrderScreen({Key? key}) : super(key: key);

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final LocationService _locationService = LocationService();
  final PaymentService _paymentService = PaymentService();
  
  LatLng? _currentLocation;
  LatLng? _pickupLocation;
  LatLng? _dropoffLocation;
  
  String _pickupAddress = '';
  String _dropoffAddress = '';
  double _distance = 0;
  double _price = 0;
  String _selectedPaymentMethod = 'qris';
  
  bool _isLoading = false;
  
  final List<Map<String, dynamic>> _paymentMethods = [
    {'name': 'QRIS', 'value': 'qris', 'icon': Icons.qr_code},
    {'name': 'E-Wallet', 'value': 'ewallet', 'icon': Icons.account_balance_wallet},
    {'name': 'Bank Transfer', 'value': 'bank_transfer', 'icon': Icons.account_balance},
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    var location = await _locationService.getCurrentLocation();
    setState(() {
      _currentLocation = LatLng(location.latitude, location.longitude);
      _pickupLocation = _currentLocation;
    });
  }

  void _calculatePrice() {
    // Price calculation: Rp 2,000 per km + base fare Rp 5,000
    _price = 5000 + (_distance * 2000);
    setState(() {});
  }

  Future<void> _placeOrder() async {
    if (_pickupLocation == null || _dropoffLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select pickup and dropoff locations')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Create payment
    var paymentResult = await _paymentService.createPayment(
      orderId: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: _price,
      customerName: 'User Name',
      customerEmail: 'user@email.com',
      paymentMethod: _selectedPaymentMethod,
    );

    setState(() => _isLoading = false);

    if (paymentResult['success']) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Order Placed!'),
          content: Text('Your order has been placed successfully.\nTotal: Rp ${_price.toStringAsFixed(0)}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Angkot')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    height: 200,
                    color: Colors.grey.shade300,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map, size: 50, color: Colors.grey.shade600),
                          const SizedBox(height: 8),
                          Text('Map View', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLocationCard(
                          icon: Icons.my_location,
                          color: Colors.green,
                          title: 'Pickup Location',
                          address: _pickupAddress.isEmpty ? 'Select pickup location' : _pickupAddress,
                          onTap: _selectPickupLocation,
                        ),
                        const SizedBox(height: 16),
                        _buildLocationCard(
                          icon: Icons.location_on,
                          color: Colors.red,
                          title: 'Dropoff Location',
                          address: _dropoffAddress.isEmpty ? 'Select destination' : _dropoffAddress,
                          onTap: _selectDropoffLocation,
                        ),
                        const SizedBox(height: 24),
                        if (_distance > 0) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Distance', style: TextStyle(color: Colors.grey)),
                                    Text('${_distance.toStringAsFixed(1)} km', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Estimated Price', style: TextStyle(color: Colors.grey)),
                                    Text('Rp ${_price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        const Text('Payment Method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ..._paymentMethods.map((method) => RadioListTile(
                          title: Text(method['name']),
                          secondary: Icon(method['icon']),
                          value: method['value'],
                          groupValue: _selectedPaymentMethod,
                          onChanged: (value) => setState(() => _selectedPaymentMethod = value as String),
                          contentPadding: EdgeInsets.zero,
                        )).toList(),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _placeOrder,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Order Now', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLocationCard({
    required IconData icon,
    required Color color,
    required String title,
    required String address,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color, child: Icon(icon, color: Colors.white)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(address, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _selectPickupLocation() {
    // Implement location picker
    setState(() {
      _pickupAddress = 'Jl. Example Street No. 123';
      _distance = 5.5;
      _calculatePrice();
    });
  }

  void _selectDropoffLocation() {
    // Implement location picker
    setState(() {
      _dropoffAddress = 'Jl. Destination Street No. 456';
      _distance = 5.5;
      _calculatePrice();
    });
  }
}

class PaymentService {
  Future<dynamic> createPayment({required String orderId, required double amount, required String customerName, required String customerEmail, required String paymentMethod}) async {}
}

class LocationService {
  Future<dynamic> getCurrentLocation() async {}
}