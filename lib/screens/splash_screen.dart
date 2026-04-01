import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
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
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D15),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 3),
            // Custom Logo matching the image
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFF11181A),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                   // Outer faint circle with top ticks
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF34D399).withOpacity(0.2), width: 1),
                    ),
                  ),
                  // Middle faint circle
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF34D399).withOpacity(0.3), width: 1),
                    ),
                  ),
                  // Inner solid circle for clock center
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF34D399).withOpacity(0.2),
                    ),
                  ),
                  // Clock hands
                  const Icon(Icons.access_time_filled, color: Color(0xFF34D399), size: 45),
                  // Top little antennas/lines
                  Positioned(
                    top: 15,
                    child: Row(
                      children: [
                        Container(width: 1, height: 10, color: const Color(0xFF34D399).withOpacity(0.5)),
                        const SizedBox(width: 40),
                        Container(width: 1, height: 10, color: const Color(0xFF34D399).withOpacity(0.5)),
                      ],
                    ),
                  ),
                  // Bottom left bar chart
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Left bar
                        Container(width: 8, height: 15, decoration: BoxDecoration(color: const Color(0xFF34D399), borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 4),
                        // Middle bar
                        Container(width: 8, height: 25, decoration: BoxDecoration(color: const Color(0xFF34D399), borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 4),
                        // Right bar
                        Container(width: 8, height: 20, decoration: BoxDecoration(color: const Color(0xFF34D399), borderRadius: BorderRadius.circular(2))),
                      ],
                    ),
                  ),
                  // Bottom right bar chart
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Left bar
                        Container(width: 8, height: 20, decoration: BoxDecoration(color: const Color(0xFF34D399), borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 4),
                        // Middle bar
                        Container(width: 8, height: 15, decoration: BoxDecoration(color: const Color(0xFF34D399), borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 4),
                        // Right bar
                        Container(width: 8, height: 25, decoration: BoxDecoration(color: const Color(0xFF34D399), borderRadius: BorderRadius.circular(2))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            // "Trackify" Text (Track is white, ify is green)
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Track',
                    style: GoogleFonts.outfit(
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      color: Colors.white, // Matches the image where "Track" is invisible against white bg
                      letterSpacing: -2,
                    ),
                  ),
                  TextSpan(
                    text: 'ify',
                    style: GoogleFonts.outfit(
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF34D399),
                      letterSpacing: -2,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 5),
            
            // HABIT TRACKER Subtitle
            Text(
              'H A B I T   T R A C K E R',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF34D399).withOpacity(0.6),
                letterSpacing: 4,
              ),
            ),
            
            const SizedBox(height: 25),
            
            // Thin horizontal line
            Container(
              width: 320,
              height: 1,
              color: const Color(0xFF34D399).withOpacity(0.2),
            ),
            
            const SizedBox(height: 25),
            
            // 3 Badges row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildBadge(Icons.check, 'Build habits'),
                const SizedBox(width: 15),
                _buildBadge(Icons.access_time_rounded, 'Track streaks'),
                const SizedBox(width: 15),
                _buildBadge(Icons.trending_up_rounded, 'Grow daily'),
              ],
            ),
            const Spacer(flex: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF34D399).withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 12, color: const Color(0xFF34D399)),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF34D399).withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}
