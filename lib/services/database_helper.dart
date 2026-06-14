import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'angkot_app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabel users
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        role TEXT NOT NULL,
        profile_image TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Tabel drivers (untuk data tambahan driver)
    await db.execute('''
      CREATE TABLE drivers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        vehicle_number TEXT,
        route_name TEXT,
        is_available INTEGER DEFAULT 0,
        rating REAL DEFAULT 5.0,
        total_trips INTEGER DEFAULT 0,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Insert data awal
    await _insertInitialData(db);
  }

  Future<void> _insertInitialData(Database db) async {
    // Admin user
    await db.insert('users', {
      'email': 'admin@angkot.com',
      'password': 'admin123',
      'name': 'Admin Angkot',
      'phone': '081234567890',
      'role': 'admin',
      'profile_image': null,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Driver user
    await db.insert('users', {
      'email': 'driver@angkot.com',
      'password': 'driver123',
      'name': 'Budi Driver',
      'phone': '081234567891',
      'role': 'driver',
      'profile_image': null,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Regular user
    await db.insert('users', {
      'email': 'user@angkot.com',
      'password': 'user123',
      'name': 'Andi User',
      'phone': '081234567892',
      'role': 'user',
      'profile_image': null,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Get driver user id
    List<Map<String, dynamic>> driverUser = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: ['driver@angkot.com'],
    );

    if (driverUser.isNotEmpty) {
      await db.insert('drivers', {
        'user_id': driverUser.first['id'],
        'vehicle_number': 'B 1234 CD',
        'route_name': 'Terminal - Pasar - Kampus',
        'is_available': 1,
        'rating': 4.8,
        'total_trips': 150,
      });
    }
  }

  // User operations
  Future<Map<String, dynamic>?> login(String email, String password) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<int> registerUser(Map<String, dynamic> userData) async {
    final db = await database;
    return await db.insert('users', userData);
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<int> updateUser(int userId, Map<String, dynamic> updates) async {
    final db = await database;
    // Remove id from updates if exists
    updates.remove('id');
    return await db.update(
      'users',
      updates,
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Driver operations
  Future<Map<String, dynamic>?> getDriverByUserId(int userId) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'drivers',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<int> insertDriver(Map<String, dynamic> driverData) async {
    final db = await database;
    return await db.insert('drivers', driverData);
  }

  Future<int> updateDriverStatus(int userId, bool isAvailable) async {
    final db = await database;
    return await db.update(
      'drivers',
      {'is_available': isAvailable ? 1 : 0},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> updateDriver(int driverId, Map<String, dynamic> updates) async {
    final db = await database;
    updates.remove('id');
    updates.remove('user_id');
    return await db.update(
      'drivers',
      updates,
      where: 'id = ?',
      whereArgs: [driverId],
    );
  }

  // Delete user (admin only)
  Future<int> deleteUser(int userId) async {
    final db = await database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Get all users (admin only)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return await db.query('users', orderBy: 'created_at DESC');
  }

  // Get all drivers (admin only)
  Future<List<Map<String, dynamic>>> getAllDrivers() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT u.*, d.vehicle_number, d.route_name, d.is_available, d.rating, d.total_trips
      FROM users u
      INNER JOIN drivers d ON u.id = d.user_id
      WHERE u.role = 'driver'
      ORDER BY u.created_at DESC
    ''');
  }

  // Order operations
  Future<List<Map<String, dynamic>>> getOrdersByUserId(int userId) async {
    final db = await database;
    return await db.query(
      'orders',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'order_time DESC',
    );
  }

  Future<int> updateOrderStatus(int orderId, String status) async {
    final db = await database;
    return await db.update(
      'orders',
      {'status': status},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  Future<int> updateOrderRating(int orderId, double rating, String review) async {
    final db = await database;
    return await db.update(
      'orders',
      {
        'rating': rating,
        'review': review,
        'is_rated': 1,
      },
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  // Driver order methods
  Future<List<Map<String, dynamic>>> getOrdersByDriverId(int driverId) async {
    final db = await database;
    return await db.query(
      'orders',
      where: 'driver_id = ?',
      whereArgs: [driverId],
      orderBy: 'order_time DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getPendingOrders() async {
    final db = await database;
    return await db.query(
      'orders',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'order_time ASC',
    );
  }

  Future<int> assignDriverToOrder(int orderId, int driverId) async {
    final db = await database;
    return await db.update(
      'orders',
      {'driver_id': driverId},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  Future<int> updatePickupTime(int orderId, String pickupTime) async {
    final db = await database;
    return await db.update(
      'orders',
      {'pickup_time': pickupTime},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  Future<int> updateDropoffTime(int orderId, String dropoffTime) async {
    final db = await database;
    return await db.update(
      'orders',
      {'dropoff_time': dropoffTime},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  Future<int> updatePaymentStatus(int orderId, bool isPaid) async {
    final db = await database;
    return await db.update(
      'orders',
      {'is_paid': isPaid ? 1 : 0},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

}