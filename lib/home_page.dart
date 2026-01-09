import 'package:electroride/profile_card.dart';
import 'package:electroride/routes_page.dart';
import 'package:electroride/support_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth/auth_service.dart';
import 'booking_history_page.dart';
import 'dashboard.dart';
import 'bus_results_page.dart';
import 'login_page.dart';
import 'notifications_page.dart';
import 'notification_helper.dart';

class home_page extends StatefulWidget {
  const home_page({super.key});
  @override
  State<home_page> createState() => _home_pageState();
}

class _home_pageState extends State<home_page> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService(); // Instance for notifications

  String? fromCity, toCity;
  DateTime? selectedDate;
  bool _isSearching = false;
  TextEditingController dateController = TextEditingController();
  List<String> cities = ["Sargodha", "Sahiwal", "Kotmomin", "SillanWali", "Bhera", "Bhalwal", "Shahpur"];
  Map<String, dynamic>? profile;
  bool isProfileLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _setupRealtimeNotifications();
  }


  void _setupRealtimeNotifications() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .listen((data) {
      if (data.isNotEmpty) {
        final latest = data.first;
        DateTime createdAt = DateTime.parse(latest['created_at']);

        // Only show pop-up if the notification was created in the last 10 seconds
        if (DateTime.now().difference(createdAt).inSeconds < 10) {
          _authService.pushImmediateNotification(
              latest['title'] ?? "Notification",
              latest['message'] ?? ""
          );
        }
      }
    });
  }

  Future<void> _loadProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      final data = await _supabase.from('profiles').select().eq('id', user.id).single();
      setState(() { profile = data; isProfileLoading = false; });
    } catch (e) { setState(() { isProfileLoading = false; }); }
  }

  Future<void> _searchBuses() async {
    if (fromCity == null || toCity == null || selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select all fields.")));
      return;
    }
    if (fromCity == toCity) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Origin and Destination cannot be the same.")));
      return;
    }
    setState(() => _isSearching = true);
    final dateString = selectedDate!.toIso8601String().split('T').first;
    try {
      final List<Map<String, dynamic>> rides = await _supabase.from('rides').select().eq('origin_city', fromCity!).eq('destination_city', toCity!).eq('date', dateString);
      if (mounted && rides.isNotEmpty) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => BusResultsPage(results: rides, origin: fromCity!, destination: toCity!, searchDate: selectedDate!)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No buses found."), backgroundColor: Colors.red));
      }
    } finally { setState(() => _isSearching = false); }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        drawer: Drawer(
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: Colors.green),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: isProfileLoading ? const CircularProgressIndicator() : Text(profile?['username']?[0].toUpperCase() ?? '?', style: const TextStyle(fontSize: 30, color: Colors.green, fontWeight: FontWeight.bold)),
                ),
                accountName: Text(isProfileLoading ? "Loading..." : profile?['username'] ?? "User", style: const TextStyle(fontWeight: FontWeight.bold)),
                accountEmail: Text(isProfileLoading ? "" : profile?['email'] ?? _supabase.auth.currentUser?.email ?? ""),
              ),
              ListTile(leading: const Icon(Icons.dashboard), title: const Text("Dashboard"), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => DashboardPage())); }),
              ListTile(leading: const Icon(Icons.book_online), title: const Text("My Bookings"), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => BookingHistoryPage())); }),
              ListTile(leading: const Icon(Icons.person), title: const Text("Profile"), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage())); }),
              ListTile(leading: const Icon(Icons.support_agent), title: const Text("Support"), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => SupportPage())); }),
              const Spacer(), const Divider(),
              ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text("Logout"), onTap: () async { await _supabase.auth.signOut(); if (!mounted) return; Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => login_page()), (r) => false); }),
            ],
          ),
        ),
        appBar: AppBar(
          backgroundColor: Colors.green, centerTitle: true,
          title: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.directions_bus_filled), SizedBox(width: 5), Text("Electro Ride", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))]),
          leading: Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer())),
          actions: [
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () async {
                    final user = _supabase.auth.currentUser;
                    if (user != null) { await _supabase.from('notifications').update({'is_read': true}).eq('user_id', user.id).eq('is_read', false); }
                    if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()));
                  },
                ),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _supabase.from('notifications').stream(primaryKey: ['id']).eq('user_id', _supabase.auth.currentUser?.id ?? ''),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final unread = snapshot.data!.where((n) => n['is_read'] == false).length;
                      if (unread > 0) {
                        return Positioned(right: 8, top: 8, child: Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)), constraints: const BoxConstraints(minWidth: 16, minHeight: 16), child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center)));
                      }
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                if (value == 'support') Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportPage()));
                else if (value == 'about') showAboutDialog(context: context, applicationName: "Electro Ride", applicationVersion: "1.0.0", applicationIcon: const Icon(Icons.directions_bus), children: const [Text("Electro Ride is a smart electric bus booking application.")]);
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'support', child: ListTile(leading: Icon(Icons.support_agent), title: Text("Help & Support"))),
                PopupMenuItem(value: 'about', child: ListTile(leading: Icon(Icons.info_outline), title: Text("About App"))),
              ],
            ),
          ],
          bottom: const TabBar(tabs: [Tab(icon: Icon(Icons.home), text: "Home"), Tab(icon: Icon(Icons.alt_route), text: "Routes"), Tab(icon: Icon(Icons.dashboard), text: "Dashboard")]),
        ),
        body: TabBarView(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 8, spreadRadius: 2, offset: const Offset(0, 3))]),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            DropdownButtonFormField(decoration: const InputDecoration(labelText: "From", border: OutlineInputBorder()), value: fromCity, items: cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => setState(() => fromCity = v as String?)),
                            const SizedBox(height: 15),
                            DropdownButtonFormField(decoration: const InputDecoration(labelText: "To", border: OutlineInputBorder()), value: toCity, items: cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => setState(() => toCity = v as String?)),
                            const SizedBox(height: 15),
                            TextFormField(controller: dateController, readOnly: true, decoration: const InputDecoration(labelText: "Date", border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)), onTap: () async {
                              DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                              if (picked != null) setState(() { selectedDate = picked; dateController.text = "${picked.day}-${picked.month}-${picked.year}"; });
                            }),
                            const SizedBox(height: 20),
                            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _isSearching ? null : _searchBuses, style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 14)), child: _isSearching ? const CircularProgressIndicator() : const Text("Search Buses", style: TextStyle(color: Colors.white)))),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Container(height: 240, decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), image: const DecorationImage(image: AssetImage("assets/images/Punjab-Electric-Bus-Project.webp"), fit: BoxFit.cover)))),
                ],
              ),
            ),
            RoutesPage(), DashboardPage(),
          ],
        ),
      ),
    );
  }
}