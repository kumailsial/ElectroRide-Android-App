import 'package:electroride/Signup_page.dart';
import 'package:electroride/home_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth/auth_service.dart';

class login_page extends StatefulWidget {
  const login_page({super.key});

  @override
  State<login_page> createState() => _login_pageState();
}

class _login_pageState extends State<login_page> {
  bool rememberMe = false;
  bool hidePass = true;
  bool isLoading = false;
  String errorMessage = '';

  TextEditingController emailEditingController = TextEditingController();
  TextEditingController passEditingController = TextEditingController();

  final formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  getUserValues() async {
    final prefs = await SharedPreferences.getInstance();
    String email = prefs.getString("email") ?? '';
    String password = prefs.getString("password") ?? '';
    bool rem = prefs.getBool("rem") ?? false;

    setState(() {
      emailEditingController.text = email;
      passEditingController.text = password;
      rememberMe = rem;
    });
  }

  @override
  void initState() {
    super.initState();
    getUserValues();
  }

  Future<void> _handleForgotPassword() async {
    final email = emailEditingController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        errorMessage = 'Please enter your email address first to reset password';
      });
      return;
    }

    setState(() { isLoading = true; errorMessage = ''; });

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Password reset link sent to $email")),
        );
      }
    } catch (e) {
      setState(() { errorMessage = "Error: ${e.toString()}"; });
    } finally {
      setState(() { isLoading = false; });
    }
  }

  Future<void> _login() async {
    if (!formKey.currentState!.validate()) return;
    setState(() { isLoading = true; errorMessage = ''; });
    try {
      final user = await _authService.signIn(
        email: emailEditingController.text.trim(),
        password: passEditingController.text,
      );
      if (user == null) {
        setState(() { errorMessage = 'Invalid login credentials'; isLoading = false; });
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      if (rememberMe) {
        await prefs.setString("email", emailEditingController.text);
        await prefs.setString("password", passEditingController.text);
        await prefs.setBool("rem", rememberMe);
      } else {
        await prefs.clear();
      }
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => home_page()));
    } catch (e) {
      setState(() { errorMessage = _getErrorMessage(e.toString()); });
    } finally {
      setState(() { isLoading = false; });
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('Invalid login credentials')) return 'Invalid email or password';
    if (error.contains('Network')) return 'Network error. Check connection';
    return 'Login failed. Please try again';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF439D35),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Form(
              key: formKey,
              child: Container(
                padding: const EdgeInsets.all(20),
                width: 350,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4FFE6),
                  border: Border.all(color: Colors.green.shade800, width: 4),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(child: Icon(Icons.directions_bus_filled, size: 50, color: Colors.black)),
                    const SizedBox(height: 5),
                    const Center(child: Text("Welcome Back", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20))),
                    const SizedBox(height: 16),
                    if (errorMessage.isNotEmpty)
                      Text(errorMessage, style: const TextStyle(color: Colors.red, fontSize: 13)),
                    const Text("Email", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: emailEditingController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        hintText: "Enter your email",
                        prefixIcon: const Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text("Password", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: passEditingController,
                      obscureText: hidePass,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        hintText: "Enter your password",
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                            onPressed: () => setState(() => hidePass = !hidePass),
                            icon: Icon(hidePass ? Icons.visibility_off : Icons.visibility)
                        ),
                      ),
                    ),


                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 310,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(value: rememberMe, onChanged: (v) => setState(() => rememberMe = v!)),
                                const Text("Remember me", style: TextStyle(fontSize: 14)),
                              ],
                            ),
                            TextButton(
                              onPressed: _handleForgotPassword,
                              child: const Text("Forgot Password?", style: TextStyle(color: Colors.black, fontSize: 14)),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 5),
                    const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("or continue with")), Expanded(child: Divider())]),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(onPressed: () => _authService.signInWithSocial(OAuthProvider.facebook), icon: Icon(Icons.facebook, color: Colors.blue.shade400)),
                          IconButton(onPressed: () => _authService.signInWithSocial(OAuthProvider.google), icon: Icon(Icons.g_mobiledata, color: Colors.green.shade700, size: 50)),
                          IconButton(onPressed: () => _authService.signInWithSocial(OAuthProvider.apple), icon: const Icon(Icons.apple, color: Colors.blueGrey)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: SizedBox(
                        width: 120, height: 40,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.lightGreen),
                          onPressed: isLoading ? null : _login,
                          child: isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text("Login", style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have account?"),
                        GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const Signup_page())),
                            child: Text(" Sign Up", style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold))
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}