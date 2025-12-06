import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Simple test screen to verify Supabase connection
class SupabaseTestScreen extends StatefulWidget {
  const SupabaseTestScreen({super.key});

  @override
  State<SupabaseTestScreen> createState() => _SupabaseTestScreenState();
}

class _SupabaseTestScreenState extends State<SupabaseTestScreen> {
  String _status = 'Testing connection...';
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _testConnection();
  }

  Future<void> _testConnection() async {
    final supabase = Supabase.instance.client;
    
    setState(() {
      _logs.add('📡 Testing Supabase connection...');
      _logs.add('URL: https://tpejvjznleoinsanrgut.supabase.co');
    });

    try {
      // Test 1: Check if client is initialized
      setState(() {
        _logs.add('✅ Supabase client initialized');
      });

      // Test 2: Try to fetch from transactions table
      setState(() {
        _logs.add('📊 Fetching transactions...');
      });

      final response = await supabase
          .from('transactions')
          .select()
          .limit(5);

      setState(() {
        _logs.add('✅ Successfully connected to Supabase!');
        _logs.add('📦 Found ${(response as List).length} transactions');
        _status = 'SUCCESS ✅';
      });
    } catch (e) {
      setState(() {
        _logs.add('❌ ERROR: $e');
        _status = 'FAILED ❌';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Connection Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status: $_status',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Connection Logs:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        _logs[index],
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _logs.clear();
                    _status = 'Testing connection...';
                  });
                  _testConnection();
                },
                child: const Text('Test Again'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
