/// Shop Settings Model
/// Represents the coffee shop's business information
class ShopSettings {
  final String id;
  final String adminId;
  final String shopName;
  final String? locationAddress;
  final double? locationLatitude;
  final double? locationLongitude;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShopSettings({
    required this.id,
    required this.adminId,
    required this.shopName,
    this.locationAddress,
    this.locationLatitude,
    this.locationLongitude,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasLocation =>
      locationLatitude != null && locationLongitude != null;

  String get displayLocation {
    if (locationAddress != null && locationAddress!.isNotEmpty) {
      return locationAddress!;
    }
    if (hasLocation) {
      return '${locationLatitude!.toStringAsFixed(6)}, ${locationLongitude!.toStringAsFixed(6)}';
    }
    return 'Not set';
  }

  factory ShopSettings.fromJson(Map<String, dynamic> json) {
    return ShopSettings(
      id: json['id'] as String,
      adminId: json['admin_id'] as String,
      shopName: json['shop_name'] as String,
      locationAddress: json['location_address'] as String?,
      locationLatitude: json['location_latitude'] != null
          ? (json['location_latitude'] as num).toDouble()
          : null,
      locationLongitude: json['location_longitude'] != null
          ? (json['location_longitude'] as num).toDouble()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'admin_id': adminId,
      'shop_name': shopName,
      'location_address': locationAddress,
      'location_latitude': locationLatitude,
      'location_longitude': locationLongitude,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ShopSettings copyWith({
    String? id,
    String? adminId,
    String? shopName,
    String? locationAddress,
    double? locationLatitude,
    double? locationLongitude,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShopSettings(
      id: id ?? this.id,
      adminId: adminId ?? this.adminId,
      shopName: shopName ?? this.shopName,
      locationAddress: locationAddress ?? this.locationAddress,
      locationLatitude: locationLatitude ?? this.locationLatitude,
      locationLongitude: locationLongitude ?? this.locationLongitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
