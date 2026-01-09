import 'package:flutter/material.dart';
import 'package:electroride/auth/auth_service.dart';
import 'login_page.dart';

class Signup_page extends StatefulWidget {
  const Signup_page({super.key});

  @override
  State<Signup_page> createState() => _Signup_pageState();
}

class _Signup_pageState extends State<Signup_page> {
  bool hidePass = true;
  bool hideConfirmPass = true;
  bool isLoading = false;
  String errorMessage = '';

  final TextEditingController usernameEditingController = TextEditingController();
  final TextEditingController emailEditingController = TextEditingController();
  final TextEditingController passEditingController = TextEditingController();
  final TextEditingController confirmPassEditingController = TextEditingController();

  final formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  Future<void> _signup() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final user = await _authService.signUp(
        username: usernameEditingController.text.trim(),
        email: emailEditingController.text.trim(),
        password: passEditingController.text,
      );

      if (user != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signup successful! Please log in.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const login_page()),
        );
      } else {
        setState(() => errorMessage = 'Signup failed. Please try again.');
      }
    } catch (e) {
      setState(() {
        errorMessage = _getErrorMessage(e.toString());
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }


  String _getErrorMessage(String error) {
    debugPrint("Signup Error: $error");
    if (error.contains('User already registered')) return 'This email is already registered.';
    if (error.contains('profiles_username_key') || error.contains('duplicate key')) {
      return 'This username is already taken.';
    }
    return 'Signup failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF439D35),
      body: Form(
        key: formKey,
        child: Center(
          child: SingleChildScrollView(
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
                children: [
                  const Icon(Icons.directions_bus_filled, size: 50, color: Colors.black),
                  const SizedBox(height: 5),
                  const Text("Create New Account", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  const SizedBox(height: 16),

                  if (errorMessage.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(child: Text(errorMessage, style: const TextStyle(color: Colors.red))),
                        ],
                      ),
                    ),

                  buildLabel("Username"),
                  buildTextField(
                    controller: usernameEditingController,
                    icon: Icons.person,
                    hint: "Choose a username",
                    validator: (v) => v!.isEmpty ? "Enter a username" : null,
                  ),
                  const SizedBox(height: 10),

                  buildLabel("Email"),
                  buildTextField(
                    controller: emailEditingController,
                    icon: Icons.email,
                    hint: "Enter your email",
                    validator: (v) {
                      if (v!.isEmpty) return "Enter your email";
                      if (!v.contains("@")) return "Enter a valid email";
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  buildLabel("Password"),
                  buildTextField(
                    controller: passEditingController,
                    icon: Icons.lock,
                    hint: "Enter your password",
                    obscure: hidePass,
                    suffix: GestureDetector(
                      onTap: () => setState(() => hidePass = !hidePass),
                      child: Icon(hidePass ? Icons.visibility_off : Icons.visibility),
                    ),
                    validator: (v) {
                      if (v!.isEmpty) return "Enter your password";
                      if (v.length < 6) return "Minimum 6 characters";
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  buildLabel("Confirm Password"),
                  buildTextField(
                    controller: confirmPassEditingController,
                    icon: Icons.lock_reset,
                    hint: "Confirm your password",
                    obscure: hideConfirmPass,
                    suffix: GestureDetector(
                      onTap: () => setState(() => hideConfirmPass = !hideConfirmPass),
                      child: Icon(hideConfirmPass ? Icons.visibility_off : Icons.visibility),
                    ),
                    validator: (v) {
                      if (v!.isEmpty) return "Confirm your password";
                      if (v != passEditingController.text) return "Passwords do not match";
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: 150,
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: isLoading ? null : _signup,
                      child: isLoading
                          ? const CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white))
                          : const Text("Sign Up", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account?"),
                      const SizedBox(width: 5),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const login_page())),
                        child: Text("Login", style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.w700)),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildLabel(String text) => Align(
    alignment: Alignment.centerLeft,
    child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
  );

  Widget buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    String? Function(String?)? validator,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}