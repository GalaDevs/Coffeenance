/// User Profile Model
/// Represents authenticated users with role-based access control
enum UserRole {
  admin,
  manager,
  staff;

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.manager:
        return 'Manager';
      case UserRole.staff:
        return 'Staff';
    }
  }

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'manager':
        return UserRole.manager;
      case 'staff':
        return UserRole.staff;
      default:
        return UserRole.staff;
    }
  }
}

class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? createdBy;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.createdBy,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Permissions based on role
  bool get canAccessSettings => role == UserRole.admin;
  bool get canAccessDashboard => role != UserRole.staff;
  bool get canAccessRevenue => role != UserRole.staff;
  bool get canAccessTransactions => true; // All roles
  bool get canManageUsers => role == UserRole.admin;
  bool get canManageInventory => role == UserRole.admin || role == UserRole.manager;
  bool get canManageStaff => role == UserRole.admin || role == UserRole.manager;
  bool get canDeleteTransactions => role == UserRole.admin;
  bool get canEditTransactions => role == UserRole.admin || role == UserRole.manager;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: UserRole.fromString(json['role'] as String),
      createdBy: json['created_by'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role.name,
      'created_by': createdBy,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    UserRole? role,
    String? createdBy,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
