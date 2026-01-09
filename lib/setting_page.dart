import 'package:flutter/material.dart';
import 'auth/auth_service.dart';
import 'editprofilepage.dart';
import 'support_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool darkMode = false;
  bool rideNotifications = true;
  bool promoNotifications = true;
  final AuthService _auth = AuthService();


  void _showAlert(String title, String msg) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(msg),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("OK"))
            ]));
  }


  Future<void> _handlePasswordReset() async {
    final email = _auth.currentUser?.email;
    if (email != null) {
      try {
        await Supabase.instance.client.auth.resetPasswordForEmail(email);
        _showAlert("Success", "Password reset link sent to $email");
      } catch (e) {
        _showAlert("Error", e.toString());
      }
    }
  }


  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text("Are you sure? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await _auth.deleteAccount();
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.green,
          title: const Text("Settings", style: TextStyle(color: Colors.white)),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context))),
      body: ListView(
        children: [
          _sectionTitle("Account Settings"),
          _settingsTile(
              title: "Edit Profile",
              icon: Icons.person,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditProfilePage()),
                );
              }),
          _settingsTile(
              title: "Change Password",
              icon: Icons.lock,
              onTap: _handlePasswordReset),
          _settingsTile(
              title: "Delete Account",
              icon: Icons.delete_forever,
              onTap: _confirmDelete),
          _sectionTitle("Notifications"),
          _switchTile(
              title: "Ride Updates",
              value: rideNotifications,
              onChanged: (v) => setState(() => rideNotifications = v)),
          _switchTile(
              title: "Promotional Messages",
              value: promoNotifications,
              onChanged: (v) => setState(() => promoNotifications = v)),
          _sectionTitle("Appearance"),
          _switchTile(
              title: "Dark Mode",
              value: darkMode,
              onChanged: (v) => setState(() => darkMode = v)),
          _sectionTitle("Language"),
          _settingsTile(
              title: "Select Language",
              icon: Icons.language,
              onTap: () => _showAlert("Language", "English is currently active.")),
          _sectionTitle("Privacy & Security"),
          _settingsTile(
              title: "Privacy Policy",
              icon: Icons.privacy_tip,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SupportPage()),
                );
              }),
          _settingsTile(
              title: "Terms & Conditions",
              icon: Icons.description,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SupportPage()),
                );
              }),
          _sectionTitle("About App"),
          _settingsTile(title: "Version 1.0.0", icon: Icons.info, onTap: () {}),
          _settingsTile(
              title: "Developer Info",
              icon: Icons.developer_mode,
              onTap: () => _showAlert("Developer", "Built by ElectroRide Dev Team.")),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(text,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800)));
  }

  Widget _settingsTile(
      {required String title,
        required IconData icon,
        required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(blurRadius: 4, offset: Offset(0, 2), color: Colors.black12)
          ]),
      child: ListTile(
          leading: Icon(icon, color: Colors.green),
          title: Text(title),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap),
    );
  }

  Widget _switchTile(
      {required String title,
        required bool value,
        required Function(bool) onChanged}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(blurRadius: 4, offset: Offset(0, 2), color: Colors.black12)
          ]),
      child: SwitchListTile(
          title: Text(title),
          value: value,
          activeColor: Colors.green,
          onChanged: onChanged),
    );
  }
}