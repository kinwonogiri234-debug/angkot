import 'package:angkot_app/screens/services/auth_service.dart';
import 'package:angkot_app/services/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';


class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'all';
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.userId;
    
    if (userId != 0) {
      // TODO: Implement getOrdersByUserId in DatabaseHelper
      // For now, using empty list
      _orders = await _dbHelper.getOrdersByUserId(userId);
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userId = authService.userId;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        backgroundColor: Colors.blue.shade700,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Aktif'),
            Tab(text: 'Selesai'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: userId == 0
          ? const Center(child: Text('Silakan login terlebih dahulu'))
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildOrderList(),
    );
  }

  Widget _buildOrderList() {
    var filteredOrders = _orders.where((order) {
      final status = order['status'] as String? ?? '';
      switch (_tabController.index) {
        case 0: // Semua
          return _selectedFilter == 'all' || status == _selectedFilter;
        case 1: // Aktif
          return status == 'pending' || status == 'accepted' || status == 'started';
        case 2: // Selesai
          return status == 'completed';
        default:
          return true;
      }
    }).toList();

    if (filteredOrders.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        return _buildOrderCard(filteredOrders[index]);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Belum ada order',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Riwayat order Anda akan muncul di sini',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/order');
            },
            icon: const Icon(Icons.add),
            label: const Text('Order Sekarang'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderTime = DateTime.parse(order['order_time'] ?? DateTime.now().toIso8601String());
    final status = order['status'] ?? 'pending';
    final price = (order['price'] as num?)?.toDouble() ?? 0;
    final pickupLocation = order['pickup_location'] ?? 'Lokasi tidak tersedia';
    final dropoffLocation = order['dropoff_location'] ?? 'Tujuan tidak tersedia';
    final distance = (order['distance'] as num?)?.toDouble() ?? 0;
    final orderId = order['id'].toString();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Order #${orderId.substring(0, orderId.length > 8 ? 8 : orderId.length)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(status),
                          size: 16,
                          color: _getStatusColor(status),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusText(status),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(status),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Pickup & Dropoff
              _buildLocationRow(Icons.location_on, pickupLocation, Colors.green),
              const SizedBox(height: 8),
              _buildLocationRow(Icons.flag, dropoffLocation, Colors.red),
              const SizedBox(height: 12),
              
              const Divider(),
              const SizedBox(height: 12),
              
              // Bottom row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('dd MMM yyyy, HH:mm').format(orderTime),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Jarak: ${distance.toStringAsFixed(1)} km',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        'Rp ${NumberFormat('#,###').format(price)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Action buttons for active orders
              if (status == 'pending' || status == 'accepted' || status == 'started') ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (status == 'pending')
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _cancelOrder(order['id']),
                          icon: const Icon(Icons.cancel, size: 18),
                          label: const Text('Batalkan'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    if (status == 'accepted' || status == 'started')
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _trackOrder(order['id'].toString()),
                          icon: const Icon(Icons.location_on),
                          label: const Text('Lacak'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showOrderDetails(order),
                        icon: const Icon(Icons.remove_red_eye, size: 18),
                        label: const Text('Detail'),
                      ),
                    ),
                  ],
                ),
              ],
              
              // Rating button for completed orders
              if (status == 'completed' && (order['is_rated'] == null || order['is_rated'] == 0))
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: OutlinedButton.icon(
                    onPressed: () => _showRatingDialog(order['id']),
                    icon: const Icon(Icons.star, color: Colors.amber),
                    label: const Text('Beri Rating'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.amber),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, String location, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            location,
            style: const TextStyle(fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
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
        return 'Menunggu';
      case 'accepted':
        return 'Diterima';
      case 'started':
        return 'Perjalanan';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile(
              title: const Text('Semua Order'),
              value: 'all',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() => _selectedFilter = value as String);
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: const Text('Menunggu'),
              value: 'pending',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() => _selectedFilter = value as String);
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: const Text('Selesai'),
              value: 'completed',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() => _selectedFilter = value as String);
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: const Text('Dibatalkan'),
              value: 'cancelled',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() => _selectedFilter = value as String);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => OrderDetailSheet(order: order),
    );
  }

  Future<void> _cancelOrder(int orderId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Order'),
        content: const Text('Apakah Anda yakin ingin membatalkan order ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _dbHelper.updateOrderStatus(orderId, 'cancelled');
              await _loadOrders();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order berhasil dibatalkan'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }

  void _trackOrder(String orderId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur tracking sedang dalam pengembangan')),
    );
  }

  void _showRatingDialog(int orderId) {
    double rating = 5.0;
    final TextEditingController reviewController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Beri Rating'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Bagaimana pengalaman Anda?'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 40,
                    ),
                    onPressed: () => setState(() => rating = index + 1),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reviewController,
                decoration: const InputDecoration(
                  hintText: 'Tulis review (opsional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Lewati'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _dbHelper.updateOrderRating(orderId, rating, reviewController.text);
                await _loadOrders();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Terima kasih atas rating ${rating.round()} ★'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Kirim'),
            ),
          ],
        ),
      ),
    );
  }
}

// Order Detail Bottom Sheet
class OrderDetailSheet extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailSheet({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final orderTime = DateTime.parse(order['order_time'] ?? DateTime.now().toIso8601String());
    final pickupTime = order['pickup_time'] != null 
        ? DateTime.parse(order['pickup_time']) 
        : null;
    final dropoffTime = order['dropoff_time'] != null 
        ? DateTime.parse(order['dropoff_time']) 
        : null;
    
    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.7,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Detail Order',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(order['status']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusText(order['status']),
                  style: TextStyle(
                    color: _getStatusColor(order['status']),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Order #${order['id']}',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                _buildDetailItem('Status', _getStatusText(order['status'])),
                _buildDetailItem('Metode Pembayaran', order['payment_method'] ?? 'Belum dipilih'),
                _buildDetailItem('Status Pembayaran', order['is_paid'] == 1 ? 'Lunas' : 'Belum Dibayar'),
                _buildDetailItem('Waktu Order', DateFormat('dd MMM yyyy, HH:mm').format(orderTime)),
                if (pickupTime != null)
                  _buildDetailItem('Waktu Jemput', DateFormat('dd MMM yyyy, HH:mm').format(pickupTime)),
                if (dropoffTime != null)
                  _buildDetailItem('Waktu Selesai', DateFormat('dd MMM yyyy, HH:mm').format(dropoffTime)),
                _buildDetailItem('Jarak Tempuh', '${(order['distance'] as num?)?.toStringAsFixed(1) ?? 0} km'),
                _buildDetailItem('Total Harga', 'Rp ${NumberFormat('#,###').format(order['price'] ?? 0)}'),
                const Divider(height: 32),
                const Text('Rute Perjalanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                _buildDetailItem('Dari', order['pickup_location'] ?? 'Tidak tersedia'),
                _buildDetailItem('Ke', order['dropoff_location'] ?? 'Tidak tersedia'),
                if (order['rating'] != null && order['rating'] > 0) ...[
                  const Divider(height: 32),
                  const Text('Rating & Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < (order['rating'] as num).round() ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 20,
                        );
                      }),
                      const SizedBox(width: 8),
                      Text('${order['rating']} ★'),
                    ],
                  ),
                  if (order['review'] != null && order['review'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('"${order['review']}"'),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
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

  String _getStatusText(String? status) {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'accepted':
        return 'Diterima';
      case 'started':
        return 'Perjalanan';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status ?? 'Unknown';
    }
  }
}