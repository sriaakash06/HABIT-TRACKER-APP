import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'signup_screen.dart';
import 'home_screen.dart';

import '../widgets/responsive_wrapper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields da!')));
      return;
    }
    setState(() => _isLoading = true);
    final error = await Provider.of<AuthProvider>(context, listen: false)
        .login(_emailController.text, _passwordController.text);
    setState(() => _isLoading = false);

    if (error == null) {
      _navigateToHome();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  void _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    final error = await Provider.of<AuthProvider>(context, listen: false).signInWithGoogle();
    setState(() => _isLoading = false);

    if (error == null) {
      _navigateToHome();
    } else if (error != 'Google sign in aborted') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  // Directly get key from environment with fallback logic
  static String? get groqApiKey {
    final key = dotenv.env['GROQ_API_KEY'];
    if (key == null || key.isEmpty) {
      debugPrint("GROQ_API_KEY not found in session. Attempting reload...");
      return null;
    }
    return key;
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWrapper(
      maxWidth: 500, // Thinner for login
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D9E75).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.bolt_rounded, size: 40, color: Color(0xFF1D9E75)),
                ),
                const SizedBox(height: 32),
                Text(
                  'Trackify',
                  style: GoogleFonts.outfit(
                    fontSize: 48,
                    height: 1.0,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'The premium way to track your habits and build your future self.',
                  style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38), fontSize: 16),
                ),
                const SizedBox(height: 50),
                _buildTextField(_emailController, 'Email Address', Icons.email_outlined),
                const SizedBox(height: 16),
                _buildTextField(_passwordController, 'Password', Icons.lock_outline, obscure: true),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D9E75),
                    minimumSize: const Size(double.infinity, 64),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Login to Dashboard', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(height: 24),
                Center(
                  child: TextButton.icon(
                    onPressed: _isLoading ? null : _handleGoogleLogin,
                    icon: Icon(Icons.g_mobiledata_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38), size: 32),
                    label: Text('Sign in with Google', style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38))),
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("New user da?", style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3))),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignupScreen()),
                      ),
                      child: Text('Initialize Account', style: GoogleFonts.outfit(color: const Color(0xFF1D9E75), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.24)),
        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.24)),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      ),
    );
  }
}
