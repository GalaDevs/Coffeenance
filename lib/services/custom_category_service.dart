import 'package:supabase_flutter/supabase_flutter.dart';

class CustomCategoryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch custom categories for a specific admin circle
  Future<List<String>> getCustomCategories(String userId) async {
    try {
      // First, get the user's admin_id (or use their own id if they are admin)
      final userProfile = await _supabase
          .from('user_profiles')
          .select('admin_id, id')
          .eq('id', userId)
          .single();

      final adminId = userProfile['admin_id'] ?? userProfile['id'];

      final response = await _supabase
          .from('custom_categories')
          .select('category_name')
          .eq('admin_id', adminId)
          .order('category_name');

      if (response == null) {
        return [];
      }

      return (response as List)
          .map((item) => item['category_name'] as String)
          .toList();
    } catch (e) {
      print('❌ Error fetching custom categories: $e');
      return [];
    }
  }

  /// Save a new custom category under the admin's account
  Future<bool> saveCustomCategory(String userId, String categoryName) async {
    try {
      // Get the user's admin_id (or use their own id if they are admin)
      final userProfile = await _supabase
          .from('user_profiles')
          .select('admin_id, id')
          .eq('id', userId)
          .single();

      final adminId = userProfile['admin_id'] ?? userProfile['id'];

      // Check if category already exists for this admin
      final existing = await _supabase
          .from('custom_categories')
          .select('id')
          .eq('admin_id', adminId)
          .eq('category_name', categoryName)
          .maybeSingle();

      if (existing != null) {
        // Category already exists, no need to add
        return true;
      }

      // Insert new custom category under the admin's id
      await _supabase.from('custom_categories').insert({
        'admin_id': adminId,
        'category_name': categoryName,
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Custom category "$categoryName" saved for admin $adminId');
      return true;
    } catch (e) {
      print('❌ Error saving custom category: $e');
      return false;
    }
  }

  /// Delete a custom category
  Future<bool> deleteCustomCategory(String adminId, String categoryName) async {
    try {
      await _supabase
          .from('custom_categories')
          .delete()
          .eq('admin_id', adminId)
          .eq('category_name', categoryName);

      print('✅ Custom category "$categoryName" deleted');
      return true;
    } catch (e) {
      print('❌ Error deleting custom category: $e');
      return false;
    }
  }
}
