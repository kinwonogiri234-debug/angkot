import 'package:angkot_app/screens/services/auth_service.dart';
import 'package:angkot_app/services/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class DriverDashboard extends StatefulWidget {
  const DriverDashboard({Key? key}) : super(key: key);

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  int _selectedIndex = 0;
  bool _isOnline = false;

  final List<Widget> _screens = [
    const DriverHomeScreen(),
    const DriverOrdersScreen(),

  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        actions: [
          Switch(
            value: _isOnline,
            onChanged: (value) {
              setState(() => _isOnline = value);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(value ? 'You are now online' : 'You are now offline')),
              );
            },
            activeColor: Colors.green,
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}


// Tambahkan class ini di dalam file driver_dashboard.dart
class DriverOrdersScreen extends StatefulWidget {
  const DriverOrdersScreen({Key? key}) : super(key: key);

  @override
  State<DriverOrdersScreen> createState() => _DriverOrdersScreenState();
}

class _DriverOrdersScreenState extends State<DriverOrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final driverId = authService.userId;
    
    if (driverId != 0) {
      // Get orders assigned to this driver
      _orders = await _dbHelper.getOrdersByDriverId(driverId);
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No orders yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    return _buildOrderCard(_orders[index]);
                  },
                ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'pending';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(status),
          child: Icon(_getStatusIcon(status), color: Colors.white),
        ),
        title: Text(
          'Order #${order['id']}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Status: ${_getStatusText(status)}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.person, 'Customer', order['customer_name'] ?? 'Unknown'),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.location_on, 'Pickup', order['pickup_location'] ?? 'Unknown'),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.flag, 'Dropoff', order['dropoff_location'] ?? 'Unknown'),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.attach_money, 'Price', 'Rp ${order['price'] ?? 0}'),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.access_time, 'Time', order['order_time'] ?? 'Unknown'),
                const SizedBox(height: 16),
                
                if (status == 'pending')
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _acceptOrder(order['id']),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          child: const Text('Accept'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _rejectOrder(order['id']),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Reject'),
                        ),
                      ),
                    ],
                  ),
                
                if (status == 'accepted')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _startTrip(order['id']),
                      child: const Text('Start Trip'),
                    ),
                  ),
                
                if (status == 'started')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _completeTrip(order['id']),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('Complete Trip'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value)),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'started':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'accepted':
        return Icons.check_circle;
      case 'started':
        return Icons.directions_bus;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'started':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Future<void> _acceptOrder(int orderId) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.updateOrderStatus(orderId, 'accepted');
    
    final authService = Provider.of<AuthService>(context, listen: false);
    await dbHelper.assignDriverToOrder(orderId, authService.userId);
    
    await _loadOrders();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order accepted!')),
    );
  }

  Future<void> _rejectOrder(int orderId) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.updateOrderStatus(orderId, 'cancelled');
    await _loadOrders();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order rejected')),
    );
  }

  Future<void> _startTrip(int orderId) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.updateOrderStatus(orderId, 'started');
    await dbHelper.updatePickupTime(orderId, DateTime.now().toIso8601String());
    await _loadOrders();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trip started!')),
    );
  }

  Future<void> _completeTrip(int orderId) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.updateOrderStatus(orderId, 'completed');
    await dbHelper.updateDropoffTime(orderId, DateTime.now().toIso8601String());
    await dbHelper.updatePaymentStatus(orderId, true);
    await _loadOrders();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trip completed! Payment received')),
    );
  }
}
class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.orange.shade50, Colors.white],
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
              ],
            ),
            child: Column(
              children: [
                const Text('Today\'s Stats', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(Icons.trip_origin, 'Trips', '12'),
                    _buildStatCard(Icons.attach_money, 'Earnings', 'Rp 150K'),
                    _buildStatCard(Icons.star, 'Rating', '4.8'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Recent Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildOrderCard('Order #12345', 'Jl. Pickup Street', 'Jl. Dropoff Street', '2.5 km', 'Pending'),
                _buildOrderCard('Order #12346', 'Jl. Another Street', 'Jl. Destination', '3.2 km', 'In Progress'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Colors.orange.shade700),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildOrderCard(String orderId, String pickup, String dropoff, String distance, String status) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: status == 'Pending' ? Colors.orange : Colors.blue,
          child: Icon(Icons.directions_bus, color: Colors.white),
        ),
        title: Text(orderId, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pickup: $pickup'),
            Text('Dropoff: $dropoff'),
            Text('Distance: $distance'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: status == 'Pending' ? Colors.orange.shade100 : Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 4),
            ElevatedButton(
              onPressed: () {},
              child: const Text('View'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(60, 30)),
            ),
          ],
        ),
      ),
    );
  }
}