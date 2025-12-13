/// User Profile Model
/// Represents authenticated users with role-based access control
enum UserRole {
  admin,
  manager,
  staff,
  developer;

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.manager:
        return 'Manager';
      case UserRole.staff:
        return 'Staff';
      case UserRole.developer:
        return 'Developer';
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
      case 'developer':
        return UserRole.developer;
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
  final String? adminId; // Multi-tenancy: NULL for admin, admin's ID for manager/staff
  final bool isActive;
  final String? profileImageUrl; // Profile image URL from Supabase Storage
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.createdBy,
    this.adminId,
    this.isActive = true,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Permissions based on role
  bool get canAccessSettings => role == UserRole.admin || role == UserRole.developer;
  bool get canAccessDashboard => role != UserRole.staff;
  bool get canAccessRevenue => role != UserRole.staff;
  bool get canAccessTransactions => true; // All roles
  bool get canManageUsers => role == UserRole.admin || role == UserRole.developer;
  bool get canManageInventory => role == UserRole.admin || role == UserRole.manager || role == UserRole.developer;
  bool get canManageStaff => role == UserRole.admin || role == UserRole.manager || role == UserRole.developer;
  bool get canDeleteTransactions => role == UserRole.admin || role == UserRole.developer;
  bool get canEditTransactions => role == UserRole.admin || role == UserRole.manager || role == UserRole.developer;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: UserRole.fromString(json['role'] as String),
      createdBy: json['created_by'] as String?,
      adminId: json['admin_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      profileImageUrl: json['profile_image_url'] as String?,
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
      'admin_id': adminId,
      'is_active': isActive,
      'profile_image_url': profileImageUrl,
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
    String? adminId,
    bool? isActive,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      createdBy: createdBy ?? this.createdBy,
      adminId: adminId ?? this.adminId,
      isActive: isActive ?? this.isActive,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
