import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'home_screen.dart';

import '../widgets/responsive_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  void _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isAuthenticated) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ResponsiveWrapper(
        child: Center(
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 3),
            // Redesigned Modern Icon
            TweenAnimationBuilder(
              duration: const Duration(seconds: 1),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: 0.8 + (0.2 * value),
                    child: child,
                  ),
                );
              },
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.primaryColor.withOpacity(0.2), width: 2),
                      ),
                    ),
                    const Icon(Icons.bolt_rounded, color: Color(0xFF1D9E75), size: 60),
                    // Achievement ticks
                    ...List.generate(8, (index) {
                      return Transform.rotate(
                        angle: (index * 45) * 3.14159 / 180,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            margin: const EdgeInsets.only(top: 15),
                            width: 2,
                            height: 10,
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            
            // "Trackify" Text
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Track',
                    style: GoogleFonts.outfit(
                      fontSize: 54,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -2,
                    ),
                  ),
                  TextSpan(
                    text: 'ify',
                    style: GoogleFonts.outfit(
                      fontSize: 54,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1D9E75),
                      letterSpacing: -2,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 10),
            
            Text(
              'A I   H A B I T   T R A C K E R',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
                letterSpacing: 6,
              ),
            ),
            
            const SizedBox(height: 40),
            
            const SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1D9E75)),
                minHeight: 2,
              ),
            ),
            
            const Spacer(flex: 4),
            
            Text(
              'v 2.0 // NEON SANCTUARY',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                color: theme.colorScheme.onSurface.withOpacity(0.2),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
  );
}
}
