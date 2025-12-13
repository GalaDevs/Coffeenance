import 'package:supabase_flutter/supabase_flutter.dart';

/// Quick verification script to check team structure
/// Run with: dart run lib/scripts/verify_team_fix.dart
Future<void> main() async {
  print('🔍 Verifying Team-Based RLS Fix...\n');

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://tpejvjznleoinsanrgut.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRwZWp2anpubGVvaW5zYW5yZ3V0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ5NTc2OTIsImV4cCI6MjA4MDUzMzY5Mn0.JW4-JjGmUZ29m0jPyHBccM-kjechpsu5FCirU4buF9U',
  );

  final supabase = Supabase.instance.client;

  try {
    // Check 1: Verify policies exist
    print('📋 Check 1: RLS Policies');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    final policies = await supabase.rpc('check_policies');
    print('Policies found: ${policies.length}');
    print('');

    // Check 2: Show all users and their admin relationships
    print('👥 Check 2: User Structure');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    final users = await supabase
        .from('user_profiles')
        .select('id, email, role, admin_id')
        .order('role')
        .order('email');

    for (final user in users) {
      final email = user['email'];
      final role = user['role'];
      final adminId = user['admin_id'];
      
      String status;
      if (role == 'admin' && adminId == null) {
        status = '✅ Admin (correct)';
      } else if (role == 'manager' && adminId != null) {
        status = '✅ Manager (has admin)';
      } else if (role == 'staff' && adminId != null) {
        status = '✅ Staff (has admin)';
      } else if ((role == 'manager' || role == 'staff') && adminId == null) {
        status = '❌ Missing admin_id!';
      } else {
        status = '⚠️ Unusual state';
      }

      print('  $email ($role) - $status');
      if (adminId != null) {
        final adminEmail = users.firstWhere(
          (u) => u['id'] == adminId,
          orElse: () => {'email': 'Unknown'},
        )['email'];
        print('    └─ Admin: $adminEmail');
      }
    }
    print('');

    // Check 3: Show transaction counts by admin_id
    print('💰 Check 3: Transaction Distribution');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    final transactions = await supabase
        .from('transactions')
        .select('admin_id, owner_id');

    // Group by admin_id
    final Map<String, Map<String, dynamic>> adminStats = {};
    for (final tx in transactions) {
      final adminId = tx['admin_id'] as String?;
      if (adminId != null) {
        if (!adminStats.containsKey(adminId)) {
          adminStats[adminId] = {
            'count': 0,
            'owners': <String>{},
          };
        }
        adminStats[adminId]!['count'] = (adminStats[adminId]!['count'] as int) + 1;
        (adminStats[adminId]!['owners'] as Set<String>).add(tx['owner_id'] as String);
      }
    }

    for (final entry in adminStats.entries) {
      final adminEmail = users.firstWhere(
        (u) => u['id'] == entry.key,
        orElse: () => {'email': 'Unknown'},
      )['email'];
      final count = entry.value['count'];
      final owners = (entry.value['owners'] as Set<String>).length;
      
      print('  $adminEmail\'s team:');
      print('    └─ $count transactions from $owners team member(s)');
    }
    print('');

    // Check 4: Find orphaned staff/managers
    print('⚠️  Check 4: Orphaned Users');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    final orphaned = users.where((u) => 
      (u['role'] == 'manager' || u['role'] == 'staff') && u['admin_id'] == null
    ).toList();

    if (orphaned.isEmpty) {
      print('  ✅ No orphaned users found!');
    } else {
      print('  ❌ Found ${orphaned.length} orphaned user(s):');
      for (final user in orphaned) {
        print('    • ${user['email']} (${user['role']}) - Missing admin_id');
      }
    }
    print('');

    // Summary
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('✅ Verification Complete!');
    print('');
    print('Next steps:');
    print('1. If any users show "❌ Missing admin_id", update them in Supabase');
    print('2. Test in the app by logging in as staff/manager');
    print('3. They should now see all their admin\'s transactions');
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
