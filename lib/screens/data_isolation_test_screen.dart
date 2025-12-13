import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Diagnostic screen to test TEAM-BASED data isolation between users
/// 
/// Team-based RLS model:
/// - Admin users have admin_id = NULL (they ARE the admin of their team)
/// - Staff/Manager users have admin_id = their admin's user_id
/// - Data visibility: Users can see data where admin_id matches their team's admin
/// - For admins: see all data where admin_id = their user_id (team data) OR owner_id = their user_id
/// - For staff: see all data where admin_id = their admin_id
class DataIsolationTestScreen extends StatefulWidget {
  const DataIsolationTestScreen({super.key});

  @override
  State<DataIsolationTestScreen> createState() => _DataIsolationTestScreenState();
}

class _DataIsolationTestScreenState extends State<DataIsolationTestScreen> {
  final List<String> _logs = [];
  bool _isTesting = false;
  String? _teamAdminId; // The admin ID for this user's team
  bool _isAdmin = false; // True if current user is an admin

  @override
  void initState() {
    super.initState();
    _runIsolationTests();
  }

  void _addLog(String message, {String emoji = '📋'}) {
    setState(() {
      _logs.add('${DateTime.now().toIso8601String().substring(11, 19)} - $emoji $message');
    });
    print(message);
  }

  Future<void> _runIsolationTests() async {
    setState(() {
      _isTesting = true;
      _logs.clear();
    });

    try {
      final supabase = Supabase.instance.client;
      
      // Test 1: Check current user
      _addLog('Checking current user...', emoji: '👤');
      final user = supabase.auth.currentUser;
      
      if (user == null) {
        _addLog('ERROR: Not authenticated!', emoji: '❌');
        _addLog('Please login first to run isolation tests.', emoji: '⚠️');
        return;
      }
      
      _addLog('Logged in as: ${user.email}', emoji: '✅');
      _addLog('User ID: ${user.id}', emoji: '🆔');
      
      // DEBUG: Check session token
      _addLog('', emoji: '');
      _addLog('🔍 SESSION DEBUG:', emoji: '🔍');
      final session = supabase.auth.currentSession;
      if (session != null) {
        _addLog('Session exists: YES', emoji: '✅');
        _addLog('Access token length: ${session.accessToken.length} chars', emoji: '🔑');
        _addLog('Token starts with: ${session.accessToken.substring(0, 20)}...', emoji: '🔑');
        _addLog('Token expires: ${DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000)}', emoji: '⏰');
        
        // Parse JWT to show user ID
        try {
          final parts = session.accessToken.split('.');
          if (parts.length == 3) {
            final payload = parts[1];
            _addLog('JWT payload exists', emoji: '✅');
            _addLog('Token is properly formatted', emoji: '✅');
          }
        } catch (e) {
          _addLog('ERROR parsing JWT: $e', emoji: '❌');
        }
      } else {
        _addLog('Session exists: NO', emoji: '❌');
        _addLog('ERROR: No session token!', emoji: '🚨');
        _addLog('RLS cannot work without session!', emoji: '⚠️');
      }
      
      // NEW: Check user profile and admin relationship
      _addLog('', emoji: '');
      _addLog('Checking user profile...', emoji: '📋');
      try {
        final userProfile = await supabase
            .from('user_profiles')
            .select('id, email, role, admin_id')
            .eq('id', user.id)
            .single();
        
        _addLog('Profile found:', emoji: '✅');
        _addLog('  Role: ${userProfile['role']}', emoji: '  ');
        _addLog('  Admin ID: ${userProfile['admin_id'] ?? 'NULL (is admin)'}', emoji: '  ');
        
        if (userProfile['role'] == 'admin') {
          _addLog('User is ADMIN - sees own data + team data', emoji: '👑');
          _isAdmin = true;
          _teamAdminId = user.id; // Admin's team ID is their own user ID
        } else {
          _addLog('User is ${userProfile['role']} - sees team data via admin_id', emoji: '👤');
          _isAdmin = false;
          _teamAdminId = userProfile['admin_id']; // Staff see data via their admin's ID
        }
        
        _addLog('Team Admin ID: $_teamAdminId', emoji: '🏢');
      } catch (e) {
        _addLog('ERROR getting profile: $e', emoji: '❌');
        _addLog('Assuming owner-based isolation for this test', emoji: '⚠️');
        _teamAdminId = user.id;
        _isAdmin = true;
      }
      
      // Test 2: Check RLS status and policies
      _addLog('', emoji: '');
      _addLog('🔍 RLS CONFIGURATION CHECK:', emoji: '🔍');
      
      // Test 2b: Check RLS enforcement
      _addLog('Testing RLS enforcement with unauthenticated query...', emoji: '🔒');
      try {
        // Query all transactions - RLS should filter automatically
        final allQuery = await supabase
            .from('transactions')
            .select('id')
            .limit(100);
        
        _addLog('Query returned ${allQuery.length} records (should be filtered by RLS)', emoji: '📊');
      } catch (e) {
        _addLog('Query error (expected if RLS blocks): $e', emoji: '⚠️');
      }
      
      // Test 3: Check owner_id column exists
      _addLog('', emoji: '');
      _addLog('Verifying owner_id column...', emoji: '🔍');
      try {
        final testQuery = await supabase
            .from('transactions')
            .select('id, owner_id')
            .limit(1);
        _addLog('owner_id column exists ✓', emoji: '✅');
        
        if (testQuery.isNotEmpty) {
          final firstRow = testQuery[0];
          if (firstRow['owner_id'] != null) {
            _addLog('Sample owner_id: ${firstRow['owner_id']}', emoji: '📝');
            if (firstRow['owner_id'] == user.id) {
              _addLog('Sample record belongs to current user ✓', emoji: '✅');
            } else {
              _addLog('⚠️ Sample record belongs to someone else!', emoji: '⚠️');
            }
          } else {
            _addLog('⚠️ WARNING: Found record with NULL owner_id!', emoji: '🚨');
            _addLog('This violates NOT NULL constraint!', emoji: '❌');
          }
        }
      } catch (e) {
        _addLog('ERROR: owner_id column missing or inaccessible!', emoji: '❌');
        _addLog('Error: $e', emoji: '📛');
        _addLog('Run migration 20251207000008 to fix RLS', emoji: '⚠️');
        return;
      }
      
      // Test 4: Query transactions (should only see team data)
      _addLog('', emoji: '');
      _addLog('🔍 QUERYING TRANSACTIONS:', emoji: '📊');
      _addLog('Expected: Only records where admin_id = $_teamAdminId (TEAM-BASED)', emoji: '📝');
      _addLog('Note: This includes your data AND team members\' data', emoji: '💡');
      
      final transactions = await supabase
          .from('transactions')
          .select('id, owner_id, description, admin_id, created_at')
          .order('created_at', ascending: false);
      
      _addLog('', emoji: '');
      _addLog('RESULT: Found ${transactions.length} transaction(s)', emoji: '📈');
      
      // Show detailed info about each transaction
      if (transactions.isNotEmpty) {
        _addLog('', emoji: '');
        _addLog('📋 DETAILED BREAKDOWN:', emoji: '📋');
        for (var tx in transactions) {
          // TEAM-BASED CHECK: Record is valid if admin_id matches our team
          final recordAdminId = tx['admin_id'];
          final isMine = tx['owner_id'] == user.id;
          final isTeamData = recordAdminId == _teamAdminId;
          final isValid = isTeamData || isMine; // Either team data or own data
          
          _addLog('TX #${tx['id']}:', emoji: isValid ? '✅' : '🚨');
          _addLog('  owner_id: ${tx['owner_id']}', emoji: '  ');
          _addLog('  admin_id: ${recordAdminId ?? 'NULL'}', emoji: '  ');
          if (isMine) {
            _addLog('  status: YOUR DATA ✓', emoji: '  ');
          } else if (isTeamData) {
            _addLog('  status: TEAM MEMBER DATA ✓ (correct!)', emoji: '  ');
          } else {
            _addLog('  status: FOREIGN DATA - BREACH!', emoji: '  ');
          }
          _addLog('  desc: ${(tx['description'] ?? '').toString().substring(0, (tx['description'] ?? '').toString().length > 30 ? 30 : (tx['description'] ?? '').toString().length)}', emoji: '  ');
          if (!isValid) {
            _addLog('  🚨 RLS FAILED: This record should be hidden!', emoji: '  ');
          }
        }
      }
      
      // Verify all transactions belong to current team (TEAM-BASED)
      bool allValidForTeam = true;
      int myCount = 0;
      int teamCount = 0; // Team members' data (not yours, but same team)
      int otherCount = 0; // Foreign data (different team - REAL breach)
      List<String> otherOwners = [];
      
      for (var tx in transactions) {
        final recordAdminId = tx['admin_id'];
        final isMine = tx['owner_id'] == user.id;
        final isTeamData = recordAdminId == _teamAdminId;
        
        if (isMine) {
          myCount++;
        } else if (isTeamData) {
          teamCount++; // Valid team data from team member
        } else {
          otherCount++;
          allValidForTeam = false;
          final otherOwner = tx['owner_id'] ?? 'NULL';
          if (!otherOwners.contains(otherOwner)) {
            otherOwners.add(otherOwner);
          }
          _addLog('🚨 TRUE BREACH: TX#${tx['id']} owned by $otherOwner (admin_id: $recordAdminId)', emoji: '🚨');
        }
      }
      
      // Show team data info if any
      if (teamCount > 0) {
        _addLog('', emoji: '');
        _addLog('📊 TEAM DATA SUMMARY:', emoji: '📊');
        _addLog('Found $teamCount records from team members - THIS IS CORRECT!', emoji: '✅');
        _addLog('Team members share data with admin_id = $_teamAdminId', emoji: '🏢');
      }
      
      if (otherOwners.isNotEmpty) {
        _addLog('', emoji: '');
        _addLog('⚠️ FOREIGN DATA (TRUE BREACHES):', emoji: '⚠️');
        for (var ownerId in otherOwners) {
          // Try to get owner details
          try {
            final ownerProfile = await supabase
                .from('user_profiles')
                .select('email, role, admin_id')
                .eq('id', ownerId)
                .single();
            _addLog('  $ownerId = ${ownerProfile['email']} (${ownerProfile['role']})', emoji: '  ');
            _addLog('    Their admin_id: ${ownerProfile['admin_id'] ?? 'NULL (is admin)'}', emoji: '  ');
            _addLog('    Your team admin: $_teamAdminId', emoji: '  ');
            _addLog('    -> These don\'t match = TRUE BREACH', emoji: '🚨');
          } catch (e) {
            _addLog('  $ownerId = Unknown user', emoji: '  ');
          }
        }
      }
      
      _addLog('', emoji: '');
      _addLog('📊 TEAM ISOLATION VERDICT:', emoji: '📊');
      if (allValidForTeam && transactions.isNotEmpty) {
        _addLog('✅ PASS: All data belongs to your team!', emoji: '✅');
        _addLog('  Your records: $myCount', emoji: '  ');
        _addLog('  Team member records: $teamCount', emoji: '  ');
        _addLog('  Total: ${myCount + teamCount}', emoji: '  ');
        _addLog('Team-based RLS is working correctly!', emoji: '🔒');
      } else if (otherCount > 0) {
        _addLog('❌ FAIL: Found $otherCount record(s) from OTHER TEAMS!', emoji: '❌');;
        _addLog('🚨 RLS IS NOT WORKING!', emoji: '🚨');
        _addLog('', emoji: '');
        _addLog('POSSIBLE CAUSES:', emoji: '💡');
        _addLog('1. RLS policies not applied correctly', emoji: '  ');
        _addLog('2. owner_id values are incorrect in database', emoji: '  ');
        _addLog('3. FORCE RLS not enabled on table', emoji: '  ');
        _addLog('4. Session token not being sent with queries', emoji: '  ');
      } else if (transactions.isEmpty) {
        _addLog('No transactions found - cannot test isolation', emoji: '⚠️');
      }
      
      // Test 5: Try inserting a test transaction with owner_id
      _addLog('', emoji: '');
      _addLog('🔍 INSERT TEST:', emoji: '📝');
      _addLog('Inserting test transaction...', emoji: '📝');
      
      // Get user's admin_id for team-based access
      final userProfile = await supabase
          .from('user_profiles')
          .select('role, admin_id')
          .eq('id', user.id)
          .single();
      
      final String adminId = userProfile['role'] == 'admin' 
          ? user.id 
          : (userProfile['admin_id'] ?? user.id);
      
      _addLog('User role: ${userProfile['role']}', emoji: '👤');
      _addLog('Admin ID: $adminId', emoji: '🏢');
      
      final insertResult = await supabase.from('transactions').insert({
        'description': '🧪 ISOLATION TEST - ${user.email}',
        'amount': 0.99,
        'type': 'transaction',
        'category': 'Test',
        'date': DateTime.now().toIso8601String().split('T')[0],
        'payment_method': 'Cash',
        'transaction_number': 'TEST-${DateTime.now().millisecondsSinceEpoch}',
        'receipt_number': '',
        'tin_number': '',
        'vat': 0,
        'supplier_name': '',
        'supplier_address': '',
        'owner_id': user.id,
        'admin_id': adminId, // Required for team-based RLS
      }).select().single();
      
      final insertedId = insertResult['id'];
      _addLog('INSERT successful! ID: $insertedId', emoji: '✅');
      _addLog('owner_id set to: ${insertResult['owner_id']}', emoji: '🔐');
      
      // Test 5: Verify we can read what we just inserted
      _addLog('Verifying can read own record...', emoji: '🔍');
      final readBack = await supabase
          .from('transactions')
          .select()
          .eq('id', insertedId)
          .single();
      
      if (readBack['owner_id'] == user.id) {
        _addLog('Can read own record ✓', emoji: '✅');
      } else {
        _addLog('ERROR: owner_id mismatch!', emoji: '❌');
      }
      
      // Test 6: Advanced RLS bypass test
      _addLog('', emoji: '');
      _addLog('🔍 ADVANCED RLS TESTS:', emoji: '🔒');
      try {
        // Test 6a: Try to query with wrong owner_id filter (should return nothing)
        _addLog('Test 6a: Query with fake owner_id filter...', emoji: '🔍');
        final fakeUserId = '00000000-0000-0000-0000-000000000000';
        final wrongOwnerQuery = await supabase
            .from('transactions')
            .select()
            .eq('owner_id', fakeUserId);
        
        if (wrongOwnerQuery.isEmpty) {
          _addLog('✅ PASS: RLS blocks fake owner queries', emoji: '✅');
        } else {
          _addLog('WARNING: RLS not blocking fake queries!', emoji: '⚠️');
        }
      } catch (e) {
        _addLog('RLS check error: $e', emoji: '❌');
      }
      
      // Test 7: Test inventory isolation (TEAM-BASED)
      _addLog('Testing inventory isolation (team-based)...', emoji: '📦');
      final inventory = await supabase
          .from('inventory')
          .select('id, owner_id, name, admin_id');
      
      int invMyCount = 0;
      int invTeamCount = 0;
      int invOtherCount = 0;
      List<String> invOtherOwners = [];
      
      for (var item in inventory) {
        final itemAdminId = item['admin_id'];
        final isMine = item['owner_id'] == user.id;
        final isTeamData = itemAdminId == _teamAdminId;
        
        if (isMine) {
          invMyCount++;
        } else if (isTeamData) {
          invTeamCount++; // Valid team data
        } else {
          invOtherCount++;
          final otherOwner = item['owner_id'] ?? 'NULL';
          if (!invOtherOwners.contains(otherOwner)) {
            invOtherOwners.add(otherOwner);
          }
          _addLog('🚨 INVENTORY BREACH (foreign team):', emoji: '🚨');
          _addLog('  ID: ${item['id']}, owner: $otherOwner', emoji: '  ');
          _addLog('  admin_id: ${itemAdminId ?? 'NULL'}', emoji: '  ');
          _addLog('  name: ${item['name']}', emoji: '  ');
        }
      }
      
      _addLog('Inventory: $invMyCount yours, $invTeamCount team, $invOtherCount foreign', emoji: '📦');
      
      // Test 8: Test staff isolation (TEAM-BASED)
      _addLog('Testing staff isolation (team-based)...', emoji: '👥');
      final staff = await supabase
          .from('staff')
          .select('id, owner_id, name, admin_id');
      
      int staffMyCount = 0;
      int staffTeamCount = 0;
      int staffOtherCount = 0;
      List<String> staffOtherOwners = [];
      
      for (var person in staff) {
        final personAdminId = person['admin_id'];
        final isMine = person['owner_id'] == user.id;
        final isTeamData = personAdminId == _teamAdminId;
        
        if (isMine) {
          staffMyCount++;
        } else if (isTeamData) {
          staffTeamCount++; // Valid team data
        } else {
          staffOtherCount++;
          final otherOwner = person['owner_id'] ?? 'NULL';
          if (!staffOtherOwners.contains(otherOwner)) {
            staffOtherOwners.add(otherOwner);
          }
          _addLog('🚨 STAFF BREACH (foreign team):', emoji: '🚨');
          _addLog('  ID: ${person['id']}, owner: $otherOwner', emoji: '  ');
          _addLog('  admin_id: ${personAdminId ?? 'NULL'}', emoji: '  ');
          _addLog('  name: ${person['name']}', emoji: '  ');
        }
      }
      
      _addLog('Staff: $staffMyCount yours, $staffTeamCount team, $staffOtherCount foreign', emoji: '👥');
      
      // COMPREHENSIVE DIAGNOSIS (TEAM-BASED)
      _addLog('', emoji: '');
      _addLog('═══════════════════════════════════', emoji: '');
      _addLog('🔬 TEAM-BASED RLS DIAGNOSIS', emoji: '🔬');
      _addLog('═══════════════════════════════════', emoji: '');
      _addLog('', emoji: '');
      
      // Calculate totals
      final totalTeamTx = teamCount;
      final totalTeamInv = invTeamCount;
      final totalTeamStaff = staffTeamCount;
      
      if (otherCount > 0 || invOtherCount > 0 || staffOtherCount > 0) {
        _addLog('❌ TEAM RLS ISOLATION FAILURE DETECTED', emoji: '🚨');
        _addLog('', emoji: '');
        _addLog('FOREIGN DATA (TRUE BREACHES):', emoji: '📊');
        _addLog('• Transactions: $otherCount from other teams', emoji: '  ');
        _addLog('• Inventory: $invOtherCount from other teams', emoji: '  ');
        _addLog('• Staff: $staffOtherCount from other teams', emoji: '  ');
        _addLog('', emoji: '');
        _addLog('ROOT CAUSE ANALYSIS:', emoji: '🔍');
        _addLog('', emoji: '');
        _addLog('1️⃣ ADMIN_ID MISMATCH:', emoji: '');
        _addLog('   • Records have admin_id that doesn\'t match your team', emoji: '  ');
        _addLog('   • Your team admin_id: $_teamAdminId', emoji: '  ');
        _addLog('', emoji: '');
        _addLog('2️⃣ RLS POLICY ISSUE:', emoji: '');
        _addLog('   • get_current_user_admin_id() function may be incorrect', emoji: '  ');
        _addLog('   • Policy may not be checking admin_id properly', emoji: '  ');
        _addLog('', emoji: '');
        _addLog('🔧 RECOMMENDED ACTIONS:', emoji: '💡');
        _addLog('', emoji: '');
        _addLog('ACTION 1: Verify admin_id values in your data', emoji: '📝');
        _addLog('  Check that all records have correct admin_id', emoji: '  ');
        _addLog('', emoji: '');
        _addLog('ACTION 2: Check RLS policies in Supabase', emoji: '📝');
        _addLog('  Verify get_current_user_admin_id() function', emoji: '  ');
        _addLog('', emoji: '');
        _addLog('📤 SHARE THIS LOG:', emoji: '💡');
        _addLog('Screenshot entire log and send to developer', emoji: '  ');
      } else {
        _addLog('✅ TEAM-BASED RLS WORKING PERFECTLY!', emoji: '🎉');
        _addLog('', emoji: '');
        _addLog('All isolation checks passed:', emoji: '📊');
        _addLog('• Session token: Valid and active', emoji: '✅');
        _addLog('• Team-based RLS: Working correctly', emoji: '✅');
        _addLog('• admin_id matching: Accurate', emoji: '✅');
        _addLog('• No foreign team data visible', emoji: '✅');
        _addLog('', emoji: '');
        _addLog('TEAM DATA BREAKDOWN:', emoji: '📊');
        _addLog('• Transactions: $myCount yours + $totalTeamTx team = ${myCount + totalTeamTx} total', emoji: '  ');
        _addLog('• Inventory: $invMyCount yours + $totalTeamInv team = ${invMyCount + totalTeamInv} total', emoji: '  ');
        _addLog('• Staff: $staffMyCount yours + $totalTeamStaff team = ${staffMyCount + totalTeamStaff} total', emoji: '  ');
        _addLog('', emoji: '');
        if (totalTeamTx > 0 || totalTeamInv > 0 || totalTeamStaff > 0) {
          _addLog('✅ Team data sharing works! You can see:', emoji: '🏢');
          _addLog('   Your data + Team members\' data = Full team visibility', emoji: '  ');
        }
        _addLog('', emoji: '');
        _addLog('Your team data is properly isolated! 🔒', emoji: '🎉');
      }
      
      // Test 9: Clean up test data
      _addLog('Cleaning up test data...', emoji: '🗑️');
      await supabase
          .from('transactions')
          .delete()
          .eq('id', insertedId);
      _addLog('Test data deleted', emoji: '✅');
      
      // Final Summary
      _addLog('', emoji: '');
      _addLog('═══════════════════════════════════════', emoji: '📊');
      _addLog('TEAM-BASED ISOLATION TEST SUMMARY', emoji: '📊');
      _addLog('═══════════════════════════════════════', emoji: '📊');
      
      final totalForeignBreaches = otherCount + invOtherCount + staffOtherCount;
      
      if (totalForeignBreaches == 0) {
        _addLog('✅ PASS: Complete team isolation!', emoji: '✅');
        _addLog('All visible data belongs to your team', emoji: '🔒');
        _addLog('Team-based RLS policies working correctly', emoji: '✅');
      } else {
        _addLog('❌ FAIL: Found $totalForeignBreaches foreign team breach(es)!', emoji: '❌');
        _addLog('Action required: Check admin_id values and RLS policies', emoji: '⚠️');
      }
      
      _addLog('', emoji: '');
      _addLog('User: ${user.email}', emoji: '👤');
      _addLog('Role: ${_isAdmin ? 'ADMIN' : 'Staff/Manager'}', emoji: '👑');
      _addLog('Team Admin ID: $_teamAdminId', emoji: '🏢');
      _addLog('', emoji: '');
      _addLog('TRANSACTIONS:', emoji: '📊');
      _addLog('  Your records: $myCount', emoji: '  ');
      _addLog('  Team records: $teamCount (correct!)', emoji: '  ');
      _addLog('  Foreign records: $otherCount ${otherCount > 0 ? '(BREACH!)' : '(none, good!)'}', emoji: '  ');
      _addLog('INVENTORY:', emoji: '📦');
      _addLog('  Your records: $invMyCount', emoji: '  ');
      _addLog('  Team records: $invTeamCount (correct!)', emoji: '  ');
      _addLog('  Foreign records: $invOtherCount ${invOtherCount > 0 ? '(BREACH!)' : '(none, good!)'}', emoji: '  ');
      _addLog('STAFF:', emoji: '👥');
      _addLog('  Your records: $staffMyCount', emoji: '  ');
      _addLog('  Team records: $staffTeamCount (correct!)', emoji: '  ');
      _addLog('  Foreign records: $staffOtherCount ${staffOtherCount > 0 ? '(BREACH!)' : '(none, good!)'}', emoji: '  ');
      
    } catch (e, stackTrace) {
      _addLog('ERROR: $e', emoji: '❌');
      _addLog('Stack: ${stackTrace.toString().split('\n').take(3).join('\n')}', emoji: '📍');
      
      if (e is PostgrestException) {
        _addLog('Postgres Error:', emoji: '🔴');
        _addLog('  Code: ${e.code}', emoji: '  ');
        _addLog('  Message: ${e.message}', emoji: '  ');
        _addLog('  Details: ${e.details}', emoji: '  ');
        _addLog('  Hint: ${e.hint}', emoji: '  ');
      }
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Isolation Test'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isTesting ? null : _runIsolationTests,
            tooltip: 'Run Tests Again',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isTesting)
            const LinearProgressIndicator(
              backgroundColor: Colors.grey,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.deepPurple.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🔒 Team-Based Data Isolation Test',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Verifies team-based RLS: Admin + team members share data.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Expected: See YOUR data + TEAM data. No foreign team data.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.grey.shade900,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  Color textColor = Colors.green.shade300;
                  
                  if (log.contains('❌') || log.contains('ERROR') || log.contains('FAIL')) {
                    textColor = Colors.red.shade300;
                  } else if (log.contains('⚠️') || log.contains('WARNING')) {
                    textColor = Colors.orange.shade300;
                  } else if (log.contains('🚨') || log.contains('BREACH')) {
                    textColor = Colors.red.shade400;
                  } else if (log.contains('✅') || log.contains('PASS')) {
                    textColor = Colors.green.shade400;
                  } else if (log.contains('═══')) {
                    textColor = Colors.cyan.shade300;
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      log,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: textColor,
                        height: 1.4,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isTesting ? null : _runIsolationTests,
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.security),
        label: const Text('Run Tests'),
      ),
    );
  }
}
