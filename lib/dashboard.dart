import 'package:electroride/routes_page.dart';
import 'package:flutter/material.dart';
import 'package:electroride/auth/auth_service.dart';
import 'booking_history_page.dart';
import 'profile_card.dart';
import 'package:electroride/support_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final AuthService _authService = AuthService();

  bool isLoading = true;
  String userName = "Rider";
  double walletBalance = 0.0;
  int totalBookings = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }


  Future<void> _loadDashboardData() async {
    final user = _authService.currentUser;

    if (user == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    try {
      final profile = await _authService.getProfile();


      final List bookings = await Supabase.instance.client
          .from('bookings')
          .select('id')
          .eq('user_id', user.id);

      final int freshBookingCount = bookings.length;

      if (!mounted) return;

      if (profile != null) {
        setState(() {
          userName = profile['username'] ?? "Electro Rider";
          walletBalance =
              (profile['wallet_balance'] as num?)?.toDouble() ?? 0.0;
          totalBookings = freshBookingCount;
        });
      }
    } catch (e) {
      debugPrint("DASHBOARD LOAD ERROR: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        title: const Text("Dashboard"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 170,
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(26),
                  bottomRight: Radius.circular(26),
                ),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child:
                    Icon(Icons.person, size: 55, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Welcome, $userName",
                    style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    "Electro Ride",
                    style:
                    TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statCard(
                    "Balance",
                    "Rs. ${walletBalance.toStringAsFixed(2)}",
                    Icons.account_balance_wallet,
                  ),
                  _statCard(
                    "Bookings",
                    "$totalBookings",
                    Icons.confirmation_num,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _menuButton(
                    icon: Icons.directions_bus,
                    title: "View Timings",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => RoutesPage()),
                      );
                    },
                  ),
                  _menuButton(
                    icon: Icons.receipt_long,
                    title: "My Bookings",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                            const BookingHistoryPage()),
                      ).then((_) => _loadDashboardData());
                    },
                  ),
                  _menuButton(
                    icon: Icons.person,
                    title: "Profile",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ProfilePage()),
                      ).then((_) => _loadDashboardData());
                    },
                  ),
                  _menuButton(
                    icon: Icons.headset_mic,
                    title: "Support",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => SupportPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _statCard(String title, String value, IconData icon) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 30, color: const Color(0xFF0096FF)),
          const SizedBox(height: 10),
          Text(title,
              style:
              const TextStyle(fontSize: 14, color: Colors.black54)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
        ],
      ),
    );
  }


  Widget _menuButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, size: 28, color: const Color(0xFF00C853)),
            const SizedBox(width: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios,
                size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
