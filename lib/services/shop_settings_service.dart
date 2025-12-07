import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shop_settings.dart';

/// Service for managing shop settings in Supabase
class ShopSettingsService {
  final SupabaseClient _supabase;

  ShopSettingsService(this._supabase);

  /// Get shop settings for the current user's admin
  Future<ShopSettings?> getShopSettings(String adminId) async {
    try {
      final response = await _supabase
          .from('shop_settings')
          .select()
          .eq('admin_id', adminId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return ShopSettings.fromJson(response);
    } catch (e) {
      print('Error fetching shop settings: $e');
      rethrow;
    }
  }

  /// Create or update shop settings
  Future<ShopSettings> upsertShopSettings({
    required String adminId,
    required String shopName,
    String? locationAddress,
    double? locationLatitude,
    double? locationLongitude,
  }) async {
    try {
      final data = {
        'admin_id': adminId,
        'shop_name': shopName,
        'location_address': locationAddress,
        'location_latitude': locationLatitude,
        'location_longitude': locationLongitude,
      };

      final response = await _supabase
          .from('shop_settings')
          .upsert(data)
          .select()
          .single();

      return ShopSettings.fromJson(response);
    } catch (e) {
      print('Error upserting shop settings: $e');
      rethrow;
    }
  }

  /// Update only shop name
  Future<ShopSettings> updateShopName({
    required String adminId,
    required String shopName,
  }) async {
    try {
      final response = await _supabase
          .from('shop_settings')
          .update({'shop_name': shopName})
          .eq('admin_id', adminId)
          .select()
          .single();

      return ShopSettings.fromJson(response);
    } catch (e) {
      print('Error updating shop name: $e');
      rethrow;
    }
  }

  /// Update location information
  Future<ShopSettings> updateLocation({
    required String adminId,
    String? locationAddress,
    double? locationLatitude,
    double? locationLongitude,
  }) async {
    try {
      final data = {
        'location_address': locationAddress,
        'location_latitude': locationLatitude,
        'location_longitude': locationLongitude,
      };

      final response = await _supabase
          .from('shop_settings')
          .update(data)
          .eq('admin_id', adminId)
          .select()
          .single();

      return ShopSettings.fromJson(response);
    } catch (e) {
      print('Error updating location: $e');
      rethrow;
    }
  }

  /// Initialize default settings for a new admin
  Future<ShopSettings> initializeSettings(String adminId) async {
    try {
      final data = {
        'admin_id': adminId,
        'shop_name': 'CoffeeFlow Coffee Shop',
      };

      final response = await _supabase
          .from('shop_settings')
          .insert(data)
          .select()
          .single();

      return ShopSettings.fromJson(response);
    } catch (e) {
      print('Error initializing shop settings: $e');
      rethrow;
    }
  }
}
