import 'dart:convert';
import 'package:electroride/payment_methods.dart';
import 'package:electroride/setting_page.dart';
import 'package:electroride/support_page.dart';
import 'package:electroride/booking_history_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:electroride/auth/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import 'package:electroride/login_page.dart';
import 'editprofilepage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();


  http.Client? _uploadClient;

  String userName = "";
  String userEmail = "";
  String phone = "";
  String? avatarUrl;

  double walletBalance = 0.0;
  int totalBookings = 0;
  int rewardPoints = 0;

  bool isLoading = true;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  @override
  void dispose() {
    _uploadClient?.close();
    super.dispose();
  }


  Future<void> _pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() => isUploading = true);
    _uploadClient = http.Client();

    try {
      // TODO: REPLACE THESE WITH YOUR CLOUDINARY CREDENTIALS
      const String cloudName = "dozbmgl6j";
      const String uploadPreset = "AsadAbbas";

      final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

      final request = http.MultipartRequest("POST", url);
      request.fields['upload_preset'] = uploadPreset;

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: image.name,
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath('file', image.path));
      }


      final response = await _uploadClient!.send(request);
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonResponse = jsonDecode(responseString);

      if (response.statusCode == 200) {
        final String newImageUrl = jsonResponse['secure_url'];

        final user = _authService.currentUser;
        if (user != null) {
          await Supabase.instance.client
              .from('profiles')
              .update({'avatar_url': newImageUrl})
              .eq('id', user.id);

          setState(() => avatarUrl = newImageUrl);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Profile picture updated!"))
            );
          }
        }
      } else {
        throw Exception(jsonResponse['error']['message']);
      }
    } catch (e) {
      if (e.toString().contains('closed')) {
        debugPrint("Upload was canceled by user.");
      } else {
        debugPrint("UPLOAD ERROR: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Upload failed: $e"))
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
          _uploadClient = null;
        });
      }
    }
  }

  void _cancelUpload() {
    _uploadClient?.close();
    setState(() {
      isUploading = false;
      _uploadClient = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Upload canceled"))
    );
  }

  Future<void> loadUserData() async {
    if (!mounted) return;
    final user = _authService.currentUser;

    if (user == null) {
      setState(() {isLoading = false;});
      return;
    }

    try {
      final profile = await _authService.getProfile();
      final List<Map<String, dynamic>> response = await Supabase.instance.client
          .from('bookings')
          .select()
          .eq('user_id', user.id);

      final int freshBookingCount = response.length;

      if (!mounted) return;

      if (profile != null) {
        setState(() {
          userName = profile['username'] ?? "Electro Rider";
          userEmail = user.email ?? profile['email'] ?? "Email Not Available";
          phone = profile['phone'] ?? "";
          avatarUrl = profile['avatar_url'];
          walletBalance = (profile['wallet_balance'] as num?)?.toDouble() ?? 0.0;
          totalBookings = freshBookingCount;
          rewardPoints = profile['points'] as int? ?? 0;
        });
      }

    } catch (e) {
      debugPrint("GET PROFILE/COUNT ERROR → $e");
    } finally {
      if(mounted) setState(() => isLoading = false);
    }
  }

  void _editProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfilePage()),
    ).then((_) => loadUserData());
  }

  void _navigateToPaymentMethods() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PaymentMethodsPage()),
    );
    loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green.shade700,
        centerTitle: true,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.only(top: 10, bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildProfileCard(),
            ),


            if (isUploading)
              TextButton.icon(
                onPressed: _cancelUpload,
                icon: const Icon(Icons.cancel, color: Colors.red),
                label: const Text("Cancel Upload", style: TextStyle(color: Colors.red)),
              ),

            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildStatsCard(),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _menuItem(
                      Icons.book_online,
                      "My Bookings",
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const BookingHistoryPage()),
                        ).then((_) => loadUserData());
                      }
                  ),
                  _menuItem(Icons.payment, "Payment Methods", _navigateToPaymentMethods),
                  _menuItem(Icons.settings, "Settings", (){
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsPage()),
                    );
                  }),
                  _menuItem(Icons.headset_mic, "Support", (){
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SupportPage()),
                    );
                  }),
                  _menuItem(
                    Icons.logout,
                    "Logout",
                        () async {
                      await _authService.signOut();
                      if (mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const login_page()),
                              (Route<dynamic> route) => false,
                        );
                      }
                    },
                    isLogout: true,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.green.shade100,
                backgroundImage: avatarUrl != null
                    ? NetworkImage(avatarUrl!) as ImageProvider
                    : null,
                child: (avatarUrl == null && !isUploading)
                    ? Icon(Icons.person, size: 60, color: Colors.green.shade700)
                    : isUploading
                    ? const CircularProgressIndicator(color: Colors.green)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: isUploading ? null : _pickAndUploadImage,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),


          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(userName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo.shade900)),
              IconButton(
                onPressed: _editProfile,
                icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
              )
            ],
          ),

          Text(userEmail, style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          if (phone.isNotEmpty)
            Text(phone, style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          const Text("Member since 2024", style: TextStyle(fontSize: 14, color: Colors.grey, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.local_shipping, "$totalBookings", "Bookings"),
          Container(width: 1.5, height: 40, color: Colors.white38),
          _buildStatItem(Icons.account_balance_wallet, "Rs. ${walletBalance.toStringAsFixed(2)}", "Balance"),
          Container(width: 1.5, height: 40, color: Colors.white38),
          _buildStatItem(Icons.stars, "$rewardPoints", "Points"),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 30),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap, {bool isLogout = false}) {
    Color iconColor = isLogout ? Colors.red.shade600 : Colors.green.shade700!;
    Color titleColor = isLogout ? Colors.red.shade600 : Colors.indigo.shade900!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: titleColor)),
        trailing: isLogout ? null : Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
        onTap: onTap,
      ),
    );
  }
}