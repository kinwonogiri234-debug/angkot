class UserModel {
  String id;
  String name;
  String email;
  String phone;
  String role; // user, driver, admin
  String? profileImage;
  bool isVerified;
  DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.profileImage,
    this.isVerified = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'profileImage': profileImage,
      'isVerified': isVerified,
      'createdAt': createdAt,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'user',
      profileImage: map['profileImage'],
      isVerified: map['isVerified'] ?? false,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
    );
  }
}