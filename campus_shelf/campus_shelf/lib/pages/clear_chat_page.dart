import 'package:flutter/material.dart';
import '../services/clear_chat_service.dart';

class ClearChatPage extends StatefulWidget {
  const ClearChatPage({super.key});

  @override
  State<ClearChatPage> createState() => _ClearChatPageState();
}

class _ClearChatPageState extends State<ClearChatPage> {
  bool _clearing = false;

  Future<void> _clearDSAMessages() async {
    setState(() => _clearing = true);
    try {
      await ClearChatService.clearDSAMessages();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('DSA messages cleared!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _clearing = false);
    }
  }

  Future<void> _clearCalculatorMessages() async {
    setState(() => _clearing = true);
    try {
      await ClearChatService.clearCalculatorMessages();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Calculator messages cleared!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _clearing = false);
    }
  }

  Future<void> _clearAllMessages() async {
    setState(() => _clearing = true);
    try {
      await ClearChatService.clearAllMessages();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All messages cleared!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _clearing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1E1E1E) 
            : const Color(0xFF212121),
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        title: const Text('Clear Chat Data'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Clear Chat Data',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Use this to clear all existing chat messages and start fresh.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Clear Specific Item Messages:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _clearing ? null : _clearDSAMessages,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: _clearing
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Clear DSA Book Messages', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _clearing ? null : _clearCalculatorMessages,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: _clearing
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Clear Calculator Messages', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Clear All Messages:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '⚠️ This will delete ALL messages from ALL items!',
                      style: TextStyle(fontSize: 14, color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _clearing ? null : _clearAllMessages,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: _clearing
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Clear ALL Messages', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
