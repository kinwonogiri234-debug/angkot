import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class ManageDriversScreen extends StatefulWidget {
  const ManageDriversScreen({Key? key}) : super(key: key);

  @override
  State<ManageDriversScreen> createState() => _ManageDriversScreenState();
}

class _ManageDriversScreenState extends State<ManageDriversScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, active, inactive, pending
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Drivers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDriverDialog(),
            tooltip: 'Add Driver',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportDriversList(),
            tooltip: 'Export Data',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name, email, or vehicle number...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      _buildFilterChip('Active', 'active'),
                      _buildFilterChip('Inactive', 'inactive'),
                      _buildFilterChip('Pending', 'pending'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'driver')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var drivers = snapshot.data!.docs;
          
          // Apply filters
          drivers = drivers.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            var matchesSearch = _searchQuery.isEmpty ||
                data['name'].toLowerCase().contains(_searchQuery) ||
                data['email'].toLowerCase().contains(_searchQuery);
            
            var matchesStatus = _filterStatus == 'all';
            if (!matchesStatus) {
              // Get driver status from drivers collection
              // This would need additional query, for now using isVerified as status
              matchesStatus = _filterStatus == 'active' ? data['isVerified'] == true : 
                             _filterStatus == 'inactive' ? data['isVerified'] == false : true;
            }
            
            return matchesSearch && matchesStatus;
          }).toList();

          if (drivers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No drivers found',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'Try adjusting your search'
                        : 'Add your first driver',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                  if (_searchQuery.isEmpty) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showAddDriverDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Driver'),
                    ),
                  ],
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: drivers.length,
            itemBuilder: (context, index) {
              var driver = drivers[index].data() as Map<String, dynamic>;
              return _buildDriverCard(driver, drivers[index].id);
            },
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: _filterStatus == value,
        onSelected: (selected) {
          setState(() {
            _filterStatus = value;
          });
        },
        backgroundColor: Colors.grey.shade200,
        selectedColor: Colors.blue.shade100,
        checkmarkColor: Colors.blue.shade700,
      ),
    );
  }

  Widget _buildDriverCard(Map<String, dynamic> driver, String driverId) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: Colors.blue.shade100,
          child: Text(
            driver['name'][0].toUpperCase(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        ),
        title: Text(
          driver['name'],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(driver['email']),
            const SizedBox(height: 4),
            _buildStatusChip(driver['isVerified'] ?? false),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showEditDriverDialog(driver, driverId),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDeleteDriver(driverId, driver['name']),
              tooltip: 'Delete',
            ),
          ],
        ),
        children: [
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('drivers')
                .doc(driverId)
                .get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              
              var driverData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
              
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Driver details
                    _buildDetailRow(Icons.directions_bus, 'Vehicle Number', 
                        driverData['vehicleNumber'] ?? 'Not set'),
                    _buildDetailRow(Icons.route, 'Route Name', 
                        driverData['routeName'] ?? 'Not set'),
                    _buildDetailRow(Icons.star, 'Rating', 
                        '${driverData['rating']?.toStringAsFixed(1) ?? '0'} ★'),
                    _buildDetailRow(Icons.trip_origin, 'Total Trips', 
                        '${driverData['totalTrips'] ?? 0} trips'),
                    _buildDetailRow(Icons.calendar_today, 'Joined', 
                        (driver['createdAt'] as Timestamp?)?.toDate().toString().split(' ')[0] ?? 'N/A'),
                    
                    const Divider(height: 24),
                    
                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _viewDriverStats(driverId, driver['name']),
                            icon: const Icon(Icons.bar_chart),
                            label: const Text('View Stats'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _sendNotification(driverId, driver['name']),
                            icon: const Icon(Icons.notifications),
                            label: const Text('Notify'),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Toggle status
                    Card(
                      color: Colors.grey.shade50,
                      child: SwitchListTile(
                        title: const Text('Active Status'),
                        subtitle: Text(driverData['isAvailable'] == true 
                            ? 'Driver is currently online' 
                            : 'Driver is offline'),
                        secondary: Icon(
                          driverData['isAvailable'] == true 
                              ? Icons.check_circle 
                              : Icons.cancel,
                          color: driverData['isAvailable'] == true 
                              ? Colors.green 
                              : Colors.red,
                        ),
                        value: driverData['isAvailable'] ?? false,
                        onChanged: (value) => _toggleDriverStatus(driverId, value),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(bool isVerified) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isVerified ? Colors.green.shade100 : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isVerified ? 'Verified' : 'Pending',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isVerified ? Colors.green.shade800 : Colors.orange.shade800,
        ),
      ),
    );
  }

  void _showAddDriverDialog() {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _emailController = TextEditingController();
    final _phoneController = TextEditingController();
    final _vehicleController = TextEditingController();
    final _routeController = TextEditingController();
    final _passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Driver'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _vehicleController,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Number',
                    prefixIcon: Icon(Icons.directions_bus),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _routeController,
                  decoration: const InputDecoration(
                    labelText: 'Route Name',
                    prefixIcon: Icon(Icons.route),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Temporary Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.length < 6 ? 'Min 6 characters' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                await _addDriverToDatabase(
                  name: _nameController.text,
                  email: _emailController.text,
                  phone: _phoneController.text,
                  vehicle: _vehicleController.text,
                  route: _routeController.text,
                  password: _passwordController.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add Driver'),
          ),
        ],
      ),
    );
  }

  Future<void> _addDriverToDatabase({
    required String name,
    required String email,
    required String phone,
    required String vehicle,
    required String route,
    required String password,
  }) async {
    try {
      // This would integrate with AuthService
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showEditDriverDialog(Map<String, dynamic> driver, String driverId) {
    final _nameController = TextEditingController(text: driver['name']);
    final _emailController = TextEditingController(text: driver['email']);
    final _phoneController = TextEditingController(text: driver['phone']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Driver'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(driverId)
                  .update({
                'name': _nameController.text,
                'email': _emailController.text,
                'phone': _phoneController.text,
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Driver updated successfully')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteDriver(String driverId, String driverName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Driver'),
        content: Text('Are you sure you want to delete $driverName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(driverId)
                  .delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Driver deleted successfully')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _viewDriverStats(String driverId, String driverName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DriverStatsSheet(driverId: driverId, driverName: driverName),
    );
  }

  void _sendNotification(String driverId, String driverName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Send Notification to $driverName'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Enter notification message',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification sent successfully')),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleDriverStatus(String driverId, bool status) async {
    await FirebaseFirestore.instance.collection('drivers').doc(driverId).update({
      'isAvailable': status,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(status ? 'Driver is now active' : 'Driver is now inactive'),
        backgroundColor: status ? Colors.green : Colors.orange,
      ),
    );
  }

  void _exportDriversList() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting drivers list...')),
    );
    // Implement export to CSV/Excel
  }
}

// Driver Stats Bottom Sheet
class DriverStatsSheet extends StatelessWidget {
  final String driverId;
  final String driverName;

  const DriverStatsSheet({
    Key? key,
    required this.driverId,
    required this.driverName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 500,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Driver Statistics - $driverName',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('driverId', isEqualTo: driverId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var orders = snapshot.data!.docs;
                var completedOrders = orders.where((o) => o['status'] == 'completed').length;
                var totalEarnings = orders
                    .where((o) => o['status'] == 'completed')
                    .fold<double>(0, (sum, order) => sum + (order['price'] ?? 0));
                var averageRating = 4.8; // Would come from ratings collection

                return ListView(
                  children: [
                    _buildStatCard('Total Orders', orders.length.toString(), Icons.shopping_cart, Colors.blue),
                    _buildStatCard('Completed', completedOrders.toString(), Icons.check_circle, Colors.green),
                    _buildStatCard('Total Earnings', 'Rp ${totalEarnings.toStringAsFixed(0)}', Icons.attach_money, Colors.orange),
                    _buildStatCard('Average Rating', averageRating.toString(), Icons.star, Colors.purple),
                    const SizedBox(height: 20),
                    const Text(
                      'Recent Orders',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ...orders.take(5).map((order) {
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text((orders.indexOf(order) + 1).toString()),
                        ),
                        title: Text('Order #${order.id.substring(0, 8)}'),
                        subtitle: Text('Status: ${order['status']}'),
                        trailing: Text('Rp ${order['price']}'),
                      );
                    }).toList(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: Colors.grey.shade600)),
                  Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}