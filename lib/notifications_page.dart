import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'auth/auth_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();


  Future<void> _clearAll() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        await _supabase.from('notifications').delete().eq('user_id', user.id); // Fixed
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("All notifications cleared")));
      } catch (e) {
        print("Error clearing: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [

          TextButton(
            onPressed: () {

              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Clear All"),
                  content: const Text("Are you sure you want to delete all notification history?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                    TextButton(
                      onPressed: () {
                        _clearAll();
                        Navigator.pop(context);
                      },
                      child: const Text("Clear", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
            child: const Text("Clear All", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase.from('notifications').stream(primaryKey: ['id']).eq('user_id', _supabase.auth.currentUser?.id ?? '').order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.green));
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("No notifications yet."));

          final notifications = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final n = notifications[index];
              return Card(
                elevation: 2, margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: n['is_read'] ? Colors.grey.shade200 : Colors.green.shade100, child: Icon(Icons.notifications, color: n['is_read'] ? Colors.grey : Colors.green)),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(n['title'] ?? "", style: TextStyle(fontWeight: n['is_read'] ? FontWeight.normal : FontWeight.bold)),
                      Text(n['created_at'] != null ? DateFormat('jm').format(DateTime.parse(n['created_at']).toLocal()) : "", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  subtitle: Text(n['message'] ?? ""),
                  onTap: () => _authService.markNotificationRead(n['id'].toString()),
                ),
              );
            },
          );
        },
      ),
    );
  }
}