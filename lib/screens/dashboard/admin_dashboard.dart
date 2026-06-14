import 'package:angkot_app/screens/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const AdminHomeScreen(),
    const ManageUsersScreen(),
    const ManageDriversScreen(),
    const ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue.shade700,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_bus), label: 'Drivers'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reports'),
        ],
      ),
    );
  }

  void _signOut(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await Provider.of<AuthService>(context, listen: false).signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// Dashboard Home Screen
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue.shade50, Colors.white],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: () async {
          // Refresh data
          await Future.delayed(const Duration(seconds: 1));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Welcome Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.admin_panel_settings, size: 50, color: Colors.blue),
                    const SizedBox(height: 8),
                    Text(
                      'Welcome, Admin!',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your angkot business here',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Stats Grid
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatCard('Total Users', '1,234', Icons.people, Colors.blue, context),
                _buildStatCard('Total Drivers', '56', Icons.directions_bus, Colors.green, context),
                _buildStatCard('Total Orders', '8,901', Icons.shopping_cart, Colors.orange, context),
                _buildStatCard('Revenue', 'Rp 45.6M', Icons.attach_money, Colors.purple, context),
              ],
            ),
            const SizedBox(height: 24),
            
            // Recent Activities
            const Text('Recent Activities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  _buildActivityItem('New user registered', 'John Doe joined as driver', '5 min ago', Icons.person_add),
                  const Divider(height: 1),
                  _buildActivityItem('New order placed', 'Order #12345 from Jakarta', '1 hour ago', Icons.shopping_cart),
                  const Divider(height: 1),
                  _buildActivityItem('Payment received', 'Rp 25,000 from order #12344', '2 hours ago', Icons.payment),
                  const Divider(height: 1),
                  _buildActivityItem('Driver online', 'Budi Saputra is now online', '3 hours ago', Icons.directions_bus),
                  const Divider(height: 1),
                  _buildActivityItem('System update', 'App version 1.0.1 released', '1 day ago', Icons.system_update),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Showing $title details'), duration: const Duration(seconds: 1)),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, String time, IconData icon) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue.shade100,
        child: Icon(icon, size: 20, color: Colors.blue.shade700),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Text(time, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
    );
  }
}

// Manage Users Screen
class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({Key? key}) : super(key: key);

  // Sample user data
  final List<Map<String, dynamic>> _users = const [
    {'id': 1, 'name': 'Andi Wijaya', 'email': 'andi@email.com', 'phone': '08123456789', 'role': 'user', 'status': 'active'},
    {'id': 2, 'name': 'Siti Nurhaliza', 'email': 'siti@email.com', 'phone': '08123456788', 'role': 'user', 'status': 'active'},
    {'id': 3, 'name': 'Budi Santoso', 'email': 'budi@email.com', 'phone': '08123456787', 'role': 'user', 'status': 'inactive'},
    {'id': 4, 'name': 'Rina Amelia', 'email': 'rina@email.com', 'phone': '08123456786', 'role': 'user', 'status': 'active'},
    {'id': 5, 'name': 'Dedi Kurniawan', 'email': 'dedi@email.com', 'phone': '08123456785', 'role': 'user', 'status': 'active'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search feature coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddUserDialog(context),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Text(user['name'][0], style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
              ),
              title: Text(user['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['email']),
                  Text(user['phone'], style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue.shade700),
                    onPressed: () => _showEditUserDialog(context, user),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDeleteUser(context, user['name']),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(decoration: InputDecoration(labelText: 'Full Name')),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: 'Phone')),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: 'Password'), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User added successfully'), backgroundColor: Colors.green),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: const InputDecoration(labelText: 'Full Name'), controller: TextEditingController(text: user['name'])),
            const SizedBox(height: 12),
            TextField(decoration: const InputDecoration(labelText: 'Email'), controller: TextEditingController(text: user['email'])),
            const SizedBox(height: 12),
            TextField(decoration: const InputDecoration(labelText: 'Phone'), controller: TextEditingController(text: user['phone'])),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User updated successfully'), backgroundColor: Colors.green),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUser(BuildContext context, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete $userName?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User deleted successfully'), backgroundColor: Colors.red),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// Manage Drivers Screen
class ManageDriversScreen extends StatelessWidget {
  const ManageDriversScreen({Key? key}) : super(key: key);

  // Sample driver data
  final List<Map<String, dynamic>> _drivers = const [
    {'id': 1, 'name': 'Budi Supriyanto', 'email': 'budi@driver.com', 'phone': '08123456780', 'vehicle': 'B 1234 CD', 'route': 'Terminal - Pasar', 'status': 'online'},
    {'id': 2, 'name': 'Agus Setiawan', 'email': 'agus@driver.com', 'phone': '08123456781', 'vehicle': 'B 5678 EF', 'route': 'Kampus - Mall', 'status': 'online'},
    {'id': 3, 'name': 'Diana Putri', 'email': 'diana@driver.com', 'phone': '08123456782', 'vehicle': 'B 9012 GH', 'route': 'Perumahan - Kota', 'status': 'offline'},
    {'id': 4, 'name': 'Eko Prasetyo', 'email': 'eko@driver.com', 'phone': '08123456783', 'vehicle': 'B 3456 IJ', 'route': 'Terminal - Bandara', 'status': 'online'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Drivers'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDriverDialog(context),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _drivers.length,
        itemBuilder: (context, index) {
          final driver = _drivers[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: driver['status'] == 'online' ? Colors.green.shade100 : Colors.grey.shade200,
                child: Text(driver['name'][0], style: TextStyle(color: driver['status'] == 'online' ? Colors.green : Colors.grey)),
              ),
              title: Text(driver['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(driver['vehicle']),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: driver['status'] == 'online' ? Colors.green.shade100 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  driver['status'],
                  style: TextStyle(
                    color: driver['status'] == 'online' ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(Icons.email, 'Email', driver['email']),
                      const SizedBox(height: 8),
                      _buildDetailRow(Icons.phone, 'Phone', driver['phone']),
                      const SizedBox(height: 8),
                      _buildDetailRow(Icons.route, 'Route', driver['route']),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {},
                              icon: Icon(driver['status'] == 'online' ? Icons.pause : Icons.play_arrow),
                              label: Text(driver['status'] == 'online' ? 'Offline' : 'Online'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: driver['status'] == 'online' ? Colors.red : Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        SizedBox(width: 50, child: Text(label, style: TextStyle(color: Colors.grey.shade600))),
        Expanded(child: Text(value)),
      ],
    );
  }

  void _showAddDriverDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Driver'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(decoration: InputDecoration(labelText: 'Full Name')),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: 'Phone')),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: 'Vehicle Number')),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: 'Route Name')),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: 'Password'), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Driver added successfully'), backgroundColor: Colors.green),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

// Reports Screen
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Icon(Icons.today, color: Colors.blue.shade700),
              title: const Text('Daily Report'),
              subtitle: const Text('View daily transactions and orders'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showReportDialog(context, 'Daily Report'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Icon(Icons.calendar_month, color: Colors.blue.shade700),
              title: const Text('Monthly Report'),
              subtitle: const Text('View monthly performance summary'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showReportDialog(context, 'Monthly Report'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Icon(Icons.attach_money, color: Colors.blue.shade700),
              title: const Text('Financial Report'),
              subtitle: const Text('Revenue and expense summary'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showReportDialog(context, 'Financial Report'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Icon(Icons.people, color: Colors.blue.shade700),
              title: const Text('Driver Performance'),
              subtitle: const Text('Top performing drivers'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showReportDialog(context, 'Driver Performance'),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context, String reportType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(reportType),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bar_chart, size: 50, color: Colors.blue),
            const SizedBox(height: 16),
            Text('$reportType is under development', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('This feature will be available soon.', style: TextStyle(color: Colors.grey.shade600), textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}