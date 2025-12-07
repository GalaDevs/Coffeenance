import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Debug screen to diagnose Supabase connection issues
class ConnectionDebugScreen extends StatefulWidget {
  const ConnectionDebugScreen({super.key});

  @override
  State<ConnectionDebugScreen> createState() => _ConnectionDebugScreenState();
}

class _ConnectionDebugScreenState extends State<ConnectionDebugScreen> {
  final List<String> _logs = [];
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toIso8601String().substring(11, 19)} - $message');
    });
    print(message);
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isTesting = true;
      _logs.clear();
    });

    try {
      final supabase = Supabase.instance.client;
      
      // Test 1: Check initialization
      _addLog('✅ Supabase client initialized');
      _addLog('📡 URL: https://tpejvjznleoinsanrgut.supabase.co');
      
      // Test 2: Check auth state
      final user = supabase.auth.currentUser;
      _addLog('👤 Auth: ${user == null ? "Anonymous (OK)" : "Logged in as ${user.email}"}');
      
      // Test 3: Simple SELECT query
      _addLog('🔍 Testing database connection...');
      final response = await supabase
          .from('transactions')
          .select('id')
          .limit(1);
      
      _addLog('✅ Database query successful!');
      _addLog('📊 Response type: ${response.runtimeType}');
      _addLog('📊 Response: $response');
      
      // Test 4: Try to fetch all transactions
      _addLog('📥 Fetching all transactions...');
      final allTransactions = await supabase
          .from('transactions')
          .select()
          .order('created_at', ascending: false);
      
      _addLog('✅ Found ${(allTransactions as List).length} transactions in cloud');
      
      // Test 5: Try to insert a test transaction
      _addLog('💾 Testing INSERT operation...');
      
      // Get current user ID for owner_id
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        _addLog('⚠️ Skipping INSERT test - user not authenticated');
      } else {
        final insertResponse = await supabase.from('transactions').insert({
          'date': DateTime.now().toIso8601String().split('T')[0],
          'type': 'revenue',
          'category': 'Cash',
          'description': 'CONNECTION TEST - DELETE ME',
          'amount': 0.01,
          'payment_method': 'test',
          'owner_id': currentUserId, // Required for RLS
        }).select().single();
        
        _addLog('✅ INSERT successful! ID: ${insertResponse['id']}');
        
        // Test 6: Delete the test transaction
        _addLog('🗑️ Cleaning up test data...');
        await supabase
            .from('transactions')
            .delete()
            .eq('id', insertResponse['id']);
        
        _addLog('✅ DELETE successful!');
      }
      
      _addLog('');
      _addLog('🎉 ALL TESTS PASSED! Cloud connection working!');
      
    } catch (e, stackTrace) {
      _addLog('❌ ERROR: $e');
      _addLog('📍 Stack: ${stackTrace.toString().split('\n').take(3).join('\n')}');
      
      // Additional error details
      if (e is PostgrestException) {
        _addLog('🔴 Postgres Error:');
        _addLog('   Code: ${e.code}');
        _addLog('   Message: ${e.message}');
        _addLog('   Details: ${e.details}');
        _addLog('   Hint: ${e.hint}');
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
        title: const Text('Connection Diagnostics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isTesting ? null : _runDiagnostics,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isTesting)
            const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                Color textColor = Colors.black87;
                
                if (log.contains('❌') || log.contains('ERROR')) {
                  textColor = Colors.red;
                } else if (log.contains('✅')) {
                  textColor = Colors.green;
                } else if (log.contains('⚠️')) {
                  textColor = Colors.orange;
                }
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    log,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: textColor,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isTesting ? null : _runDiagnostics,
        child: const Icon(Icons.play_arrow),
      ),
    );
  }
}
