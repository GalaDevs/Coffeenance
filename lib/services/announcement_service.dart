import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/announcement.dart';
import '../models/user_profile.dart';

/// Service for managing announcements
/// Only developers can create/update/delete, all users can view
class AnnouncementService {
  final SupabaseClient _client;

  AnnouncementService(this._client);

  /// Get all active announcements
  Future<List<Announcement>> getActiveAnnouncements() async {
    try {
      final response = await _client
          .from('announcements')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Announcement.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching announcements: $e');
      return [];
    }
  }

  /// Get all announcements (including inactive) - for developer management
  Future<List<Announcement>> getAllAnnouncements() async {
    try {
      final response = await _client
          .from('announcements')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Announcement.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching all announcements: $e');
      return [];
    }
  }

  /// Create a new announcement (developer only)
  Future<Announcement?> createAnnouncement({
    required String title,
    required String description,
    String? downloadLink,
    required String createdBy,
  }) async {
    try {
      final data = {
        'title': title,
        'description': description,
        'created_by': createdBy,
        'is_active': true,
      };
      
      if (downloadLink != null && downloadLink.isNotEmpty) {
        data['download_link'] = downloadLink;
      }
      
      final response = await _client.from('announcements').insert(data).select().single();

      return Announcement.fromJson(response);
    } catch (e) {
      print('Error creating announcement: $e');
      return null;
    }
  }

  /// Update an announcement (developer only)
  Future<Announcement?> updateAnnouncement({
    required String id,
    String? title,
    String? description,
    String? downloadLink,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (downloadLink != null) updates['download_link'] = downloadLink;
      if (isActive != null) updates['is_active'] = isActive;

      final response = await _client
          .from('announcements')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return Announcement.fromJson(response);
    } catch (e) {
      print('Error updating announcement: $e');
      return null;
    }
  }

  /// Delete an announcement (developer only)
  Future<bool> deleteAnnouncement(String id) async {
    try {
      await _client.from('announcements').delete().eq('id', id);
      return true;
    } catch (e) {
      print('Error deleting announcement: $e');
      return false;
    }
  }

  /// Toggle announcement active status
  Future<bool> toggleAnnouncementStatus(String id, bool isActive) async {
    try {
      await _client.from('announcements').update({
        'is_active': isActive,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
      return true;
    } catch (e) {
      print('Error toggling announcement status: $e');
      return false;
    }
  }

  /// Announce to all users (create notifications and send emails)
  Future<bool> announceToAllUsers({
    required String announcementId,
    required String title,
    required String description,
    String? downloadLink,
    required String adminId,
  }) async {
    try {
      print('📢 Starting announcement to all users...');
      print('📢 Admin ID: $adminId');
      
      // 1. Mark announcement as announced
      await _client.from('announcements').update({
        'announced_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', announcementId);

      print('📢 Announcement marked as announced');

      // 2. Get all users in the same organization (admin and their team)
      final usersResponse = await _client
          .from('user_profiles')
          .select('id, email, role, admin_id')
          .or('id.eq.$adminId,admin_id.eq.$adminId');

      final users = (usersResponse as List);
      print('📢 Found ${users.length} users to notify');

      // 3. Create notifications for each user
      final notifications = users.map((user) {
        final data = {
          'announcement_id': announcementId,
        };
        if (downloadLink != null && downloadLink.isNotEmpty) {
          data['download_link'] = downloadLink;
        }
        
        return {
          'user_id': user['id'],
          'admin_id': user['admin_id'] ?? user['id'],
          'type': 'announcement',
          'title': title,
          'message': description,
          'data': data,
          'is_read': false,
          'created_by': adminId,
        };
      }).toList();

      print('📢 Created ${notifications.length} notification objects');

      if (notifications.isNotEmpty) {
        await _client.from('notifications').insert(notifications);
        print('📢 Notifications inserted successfully');
      }

      // 4. Send emails to all users
      for (final user in users) {
        final email = user['email'] as String?;
        if (email != null) {
          try {
            await _sendAnnouncementEmail(
              email: email,
              title: title,
              description: description,
            );
          } catch (e) {
            print('Error sending email to $email: $e');
            // Continue even if email fails
          }
        }
      }

      print('📢 Announcement process completed successfully');
      return true;
    } catch (e) {
      print('Error announcing to all users: $e');
      return false;
    }
  }

  /// Send announcement email using Supabase Edge Function
  Future<void> _sendAnnouncementEmail({
    required String email,
    required String title,
    required String description,
  }) async {
    try {
      // Using Supabase's built-in email service (if configured)
      // Or you can call an edge function
      await _client.functions.invoke(
        'send-announcement-email',
        body: {
          'to': email,
          'subject': '📢 New Announcement: $title',
          'title': title,
          'description': description,
        },
      );
    } catch (e) {
      print('Email service not configured or error: $e');
      // Silent fail - emails are optional
    }
  }
}

