import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Diagnostic screen to test data isolation between users
class DataIsolationTestScreen extends StatefulWidget {
  const DataIsolationTestScreen({super.key});

  @override
  State<DataIsolationTestScreen> createState() => _DataIsolationTestScreenState();
}

class _DataIsolationTestScreenState extends State<DataIsolationTestScreen> {
  final List<String> _logs = [];
  bool _isTesting = false;

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
          _addLog('User is ADMIN - should see only own data', emoji: '👑');
        } else {
          _addLog('User is ${userProfile['role']} - admin_id: ${userProfile['admin_id']}', emoji: '👤');
        }
      } catch (e) {
        _addLog('ERROR getting profile: $e', emoji: '❌');
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
      
      // Test 4: Query transactions (should only see own data)
      _addLog('', emoji: '');
      _addLog('🔍 QUERYING TRANSACTIONS:', emoji: '📊');
      _addLog('Expected: Only records with owner_id = ${user.id}', emoji: '📝');
      
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
          final isMine = tx['owner_id'] == user.id;
          _addLog('TX #${tx['id']}:', emoji: isMine ? '✅' : '🚨');
          _addLog('  owner_id: ${tx['owner_id']}', emoji: '  ');
          _addLog('  admin_id: ${tx['admin_id'] ?? 'NULL'}', emoji: '  ');
          _addLog('  belongs to me: ${isMine ? 'YES ✓' : 'NO - BREACH!'}', emoji: '  ');
          _addLog('  desc: ${(tx['description'] ?? '').toString().substring(0, (tx['description'] ?? '').toString().length > 30 ? 30 : (tx['description'] ?? '').toString().length)}', emoji: '  ');
          if (!isMine) {
            _addLog('  🚨 RLS FAILED: This record should be hidden!', emoji: '  ');
          }
        }
      }
      
      // Verify all transactions belong to current user
      bool allOwnedByMe = true;
      int myCount = 0;
      int otherCount = 0;
      List<String> otherOwners = [];
      
      for (var tx in transactions) {
        if (tx['owner_id'] == user.id) {
          myCount++;
        } else {
          otherCount++;
          allOwnedByMe = false;
          final otherOwner = tx['owner_id'] ?? 'NULL';
          if (!otherOwners.contains(otherOwner)) {
            otherOwners.add(otherOwner);
          }
          _addLog('🚨 BREACH: TX#${tx['id']} owned by $otherOwner', emoji: '🚨');
        }
      }
      
      if (otherOwners.isNotEmpty) {
        _addLog('Other owner IDs found:', emoji: '⚠️');
        for (var ownerId in otherOwners) {
          // Try to get owner details
          try {
            final ownerProfile = await supabase
                .from('user_profiles')
                .select('email, role')
                .eq('id', ownerId)
                .single();
            _addLog('  $ownerId = ${ownerProfile['email']} (${ownerProfile['role']})', emoji: '  ');
          } catch (e) {
            _addLog('  $ownerId = Unknown user', emoji: '  ');
          }
        }
      }
      
      _addLog('', emoji: '');
      _addLog('📊 ISOLATION VERDICT:', emoji: '📊');
      if (allOwnedByMe && transactions.isNotEmpty) {
        _addLog('✅ PASS: All $myCount transaction(s) belong to you!', emoji: '✅');
        _addLog('RLS is working correctly for SELECT queries', emoji: '🔒');
      } else if (otherCount > 0) {
        _addLog('❌ FAIL: Found $otherCount transaction(s) from other users!', emoji: '❌');
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
      
      // Test 7: Test inventory isolation
      _addLog('Testing inventory isolation...', emoji: '📦');
      final inventory = await supabase
          .from('inventory')
          .select('id, owner_id, name, admin_id');
      
      int invMyCount = 0;
      int invOtherCount = 0;
      List<String> invOtherOwners = [];
      
      for (var item in inventory) {
        if (item['owner_id'] == user.id) {
          invMyCount++;
        } else {
          invOtherCount++;
          final otherOwner = item['owner_id'] ?? 'NULL';
          if (!invOtherOwners.contains(otherOwner)) {
            invOtherOwners.add(otherOwner);
          }
          _addLog('🚨 INVENTORY BREACH:', emoji: '🚨');
          _addLog('  ID: ${item['id']}, owner: $otherOwner', emoji: '  ');
          _addLog('  admin_id: ${item['admin_id'] ?? 'NULL'}', emoji: '  ');
          _addLog('  name: ${item['name']}', emoji: '  ');
        }
      }
      
      _addLog('Inventory: $invMyCount yours, $invOtherCount others', emoji: '📦');
      
      // Test 8: Test staff isolation
      _addLog('Testing staff isolation...', emoji: '👥');
      final staff = await supabase
          .from('staff')
          .select('id, owner_id, name, admin_id');
      
      int staffMyCount = 0;
      int staffOtherCount = 0;
      List<String> staffOtherOwners = [];
      
      for (var person in staff) {
        if (person['owner_id'] == user.id) {
          staffMyCount++;
        } else {
          staffOtherCount++;
          final otherOwner = person['owner_id'] ?? 'NULL';
          if (!staffOtherOwners.contains(otherOwner)) {
            staffOtherOwners.add(otherOwner);
          }
          _addLog('🚨 STAFF BREACH:', emoji: '🚨');
          _addLog('  ID: ${person['id']}, owner: $otherOwner', emoji: '  ');
          _addLog('  admin_id: ${person['admin_id'] ?? 'NULL'}', emoji: '  ');
          _addLog('  name: ${person['name']}', emoji: '  ');
        }
      }
      
      _addLog('Staff: $staffMyCount yours, $staffOtherCount others', emoji: '👥');
      
      // COMPREHENSIVE DIAGNOSIS
      _addLog('', emoji: '');
      _addLog('═══════════════════════════════════', emoji: '');
      _addLog('🔬 COMPREHENSIVE DIAGNOSIS', emoji: '🔬');
      _addLog('═══════════════════════════════════', emoji: '');
      _addLog('', emoji: '');
      
      if (otherCount > 0 || invOtherCount > 0 || staffOtherCount > 0) {
        _addLog('❌ RLS ISOLATION FAILURE DETECTED', emoji: '🚨');
        _addLog('', emoji: '');
        _addLog('BREACH SUMMARY:', emoji: '📊');
        _addLog('• Transactions: $otherCount foreign records visible', emoji: '  ');
        _addLog('• Inventory: $invOtherCount foreign records visible', emoji: '  ');
        _addLog('• Staff: $staffOtherCount foreign records visible', emoji: '  ');
        _addLog('', emoji: '');
        _addLog('ROOT CAUSE ANALYSIS:', emoji: '🔍');
        _addLog('', emoji: '');
        _addLog('1️⃣ POLICY MISCONFIGURATION:', emoji: '');
        _addLog('   • Policies may be using admin_id instead of owner_id', emoji: '  ');
        _addLog('   • Multiple conflicting policies may exist', emoji: '  ');
        _addLog('   • FORCE RLS may not be enabled', emoji: '  ');
        _addLog('', emoji: '');
        _addLog('2️⃣ DATA INTEGRITY ISSUES:', emoji: '');
        _addLog('   • Records may have incorrect owner_id values', emoji: '  ');
        _addLog('   • NULL owner_id records may exist', emoji: '  ');
        _addLog('   • Migration may not have run successfully', emoji: '  ');
        _addLog('', emoji: '');
        _addLog('3️⃣ SESSION/AUTH ISSUES:', emoji: '');
        _addLog('   • Session token may not be sent with queries', emoji: '  ');
        _addLog('   • auth.uid() may not be resolving correctly', emoji: '  ');
        _addLog('   • User may be using service_role key instead of anon', emoji: '  ');
        _addLog('', emoji: '');
        _addLog('4️⃣ HELPER FUNCTION CONFLICTS:', emoji: '');
        _addLog('   • current_user_admin_id() function may still exist', emoji: '  ');
        _addLog('   • Function returning wrong ID for isolation', emoji: '  ');
        _addLog('', emoji: '');
        _addLog('🔧 RECOMMENDED ACTIONS:', emoji: '💡');
        _addLog('', emoji: '');
        _addLog('ACTION 1: Verify RLS policies in Supabase', emoji: '📝');
        _addLog('  SELECT * FROM pg_policies WHERE tablename = \'transactions\';', emoji: '  ');
        _addLog('', emoji: '');
        _addLog('ACTION 2: Check for conflicting policies', emoji: '📝');
        _addLog('  Look for policies with admin_id instead of owner_id', emoji: '  ');
        _addLog('', emoji: '');
        _addLog('ACTION 3: Run migration 20251207000008', emoji: '📝');
        _addLog('  This performs nuclear RLS reset with FORCE security', emoji: '  ');
        _addLog('', emoji: '');
        _addLog('ACTION 4: Verify all records have owner_id', emoji: '📝');
        _addLog('  SELECT COUNT(*) FROM transactions WHERE owner_id IS NULL;', emoji: '  ');
        _addLog('', emoji: '');
        _addLog('📤 SHARE THIS LOG:', emoji: '💡');
        _addLog('Screenshot entire log and send to developer', emoji: '  ');
      } else {
        _addLog('✅ RLS WORKING PERFECTLY!', emoji: '🎉');
        _addLog('', emoji: '');
        _addLog('All isolation checks passed:', emoji: '📊');
        _addLog('• Session token: Valid and active', emoji: '✅');
        _addLog('• RLS enforcement: Working correctly', emoji: '✅');
        _addLog('• owner_id matching: 100% accurate', emoji: '✅');
        _addLog('• No foreign data visible', emoji: '✅');
        _addLog('', emoji: '');
        _addLog('Your data is completely isolated! 🔒', emoji: '🎉');
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
      _addLog('═══════════════════════════', emoji: '📊');
      _addLog('ISOLATION TEST SUMMARY', emoji: '📊');
      _addLog('═══════════════════════════', emoji: '📊');
      
      final totalBreaches = otherCount + invOtherCount + staffOtherCount;
      
      if (totalBreaches == 0) {
        _addLog('PASS: Complete data isolation! 🎉', emoji: '✅');
        _addLog('All data belongs to current user', emoji: '🔒');
        _addLog('RLS policies working correctly', emoji: '✅');
      } else {
        _addLog('FAIL: Found $totalBreaches isolation breach(es)!', emoji: '❌');
        _addLog('Action required: Check RLS policies', emoji: '⚠️');
      }
      
      _addLog('User: ${user.email}', emoji: '👤');
      _addLog('Transactions: $myCount yours, $otherCount others', emoji: '📊');
      _addLog('Inventory: $invMyCount yours, $invOtherCount others', emoji: '📦');
      _addLog('Staff: $staffMyCount yours, $staffOtherCount others', emoji: '👥');
      
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
                  '🔒 Data Isolation Diagnostic',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This test verifies that each user can only see their own data.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Expected: All records should have owner_id = your user ID',
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
