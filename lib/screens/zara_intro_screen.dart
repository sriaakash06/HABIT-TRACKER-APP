import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'zara_chat_screen.dart';
import '../widgets/zara_robot.dart';

class ZaraIntroScreen extends StatefulWidget {
  const ZaraIntroScreen({super.key});

  @override
  State<ZaraIntroScreen> createState() => _ZaraIntroScreenState();
}

class _ZaraIntroScreenState extends State<ZaraIntroScreen>
    with TickerProviderStateMixin {
  late AnimationController _bubbleCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _bubbleScale;
  late Animation<double> _fadeAnim;

  int _msgIndex = 0;
  bool _showBubble = false;
  bool _isTyping = false;
  String _displayedText = '';
  String _fullText = '';

  final List<String> _messages = [
    "Hi da! I'm Zara 👋",
    "Enna habit track pannureenga?",
    "3 habits pending today! 🔥",
    "Let's crush it together! 💪",
    "Talk to me anytime da! 😊",
  ];

  @override
  void initState() {
    super.initState();

    _bubbleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bubbleScale = CurvedAnimation(
      parent: _bubbleCtrl,
      curve: Curves.elasticOut,
    );

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();

    // Auto trigger first greeting
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _triggerGreeting();
    });
  }

  void _triggerGreeting() async {
    if (_isTyping) return;
    _isTyping = true;

    setState(() {
      _showBubble = false;
      _displayedText = '';
    });

    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    _fullText = _messages[_msgIndex % _messages.length];
    setState(() => _showBubble = true);
    _bubbleCtrl.forward(from: 0);

    await Future.delayed(const Duration(milliseconds: 200));
    _typeText();
  }

  void _typeText() async {
    for (int i = 0; i <= _fullText.length; i++) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 45));
      if (!mounted) return;
      setState(() => _displayedText = _fullText.substring(0, i));
    }
    _isTyping = false;
    _msgIndex++;
  }

  @override
  void dispose() {
    _bubbleCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Top label
                Text(
                  'TRACKIFY · AI ASSISTANT',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryColor.withOpacity(0.8),
                    letterSpacing: 3,
                  ),
                ),

                const Spacer(),

                // Robot with Glow
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow
                    Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            theme.primaryColor.withOpacity(0.12),
                            theme.primaryColor.withOpacity(0.02),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    // Inner subtle glow
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryColor.withOpacity(0.1),
                            blurRadius: 60,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    const ZaraRobot(),
                  ],
                ),

                const SizedBox(height: 40),

                // Name & Subtitle
                Text(
                  'Zara',
                  style: GoogleFonts.outfit(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  '// your habit companion',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 48),

                // Mock Input (from image)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: theme.cardColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.primaryColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _displayedText.isEmpty ? "Hi! I'm Zara da!" : _displayedText + "|",
                          style: GoogleFonts.outfit(
                            color: theme.colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Chat button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, a1, a2) => const ZaraChatScreen(),
                          transitionsBuilder: (_, anim, __, child) =>
                              FadeTransition(opacity: anim, child: child),
                          transitionDuration: const Duration(milliseconds: 300),
                        ),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline_rounded,
                          size: 20, color: Colors.white),
                      label: Text(
                        'Chat with Zara',
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50)),
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 0),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),


              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Maybe later',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
