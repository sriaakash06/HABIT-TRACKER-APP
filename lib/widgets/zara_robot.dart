import 'package:flutter/material.dart';
import 'dart:math' as math;

class ZaraRobot extends StatefulWidget {
  final VoidCallback? onTap;
  const ZaraRobot({super.key, this.onTap});

  @override
  State<ZaraRobot> createState() => _ZaraRobotState();
}

class _ZaraRobotState extends State<ZaraRobot>
    with TickerProviderStateMixin {
  late AnimationController _floatCtrl;
  late AnimationController _orbitCtrl;
  late AnimationController _blinkCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _tiltCtrl;

  late Animation<double> _floatAnim;
  late Animation<double> _orbitAnim;
  late Animation<double> _blinkAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _tiltAnim;

  bool _isHovered = false;

  @override
  void initState() {
    super.initState();

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _orbitAnim = Tween<double>(begin: 0, end: 2 * math.pi).animate(_orbitCtrl);

    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _blinkAnim = Tween<double>(begin: 1, end: 0.05).animate(
      CurvedAnimation(parent: _blinkCtrl, curve: Curves.easeInOut),
    );
    _startBlinkLoop();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 4, end: 7).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _tiltCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _tiltAnim = Tween<double>(begin: 0, end: 0.15).animate(
      CurvedAnimation(parent: _tiltCtrl, curve: Curves.easeOut),
    );
  }

  void _startBlinkLoop() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 4));
      if (!mounted) break;
      await _blinkCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) break;
      await _blinkCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _orbitCtrl.dispose();
    _blinkCtrl.dispose();
    _pulseCtrl.dispose();
    _tiltCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) {
        setState(() => _isHovered = true);
        _tiltCtrl.forward();
      },
      onTapUp: (_) {
        setState(() => _isHovered = false);
        _tiltCtrl.reverse();
      },
      onTapCancel: () {
        setState(() => _isHovered = false);
        _tiltCtrl.reverse();
      },
      child: SizedBox(
        width: 200,
        height: 260,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Orbit ring
            AnimatedBuilder(
              animation: _orbitAnim,
              builder: (_, __) {
                return SizedBox(
                  width: 240,
                  height: 240,
                  child: CustomPaint(
                    painter: _OrbitPainter(_orbitAnim.value),
                  ),
                );
              },
            ),
            // Robot body with float + tilt
            AnimatedBuilder(
              animation: Listenable.merge([_floatAnim, _tiltAnim, _blinkAnim, _pulseAnim]),
              builder: (_, __) {
                return Transform.translate(
                  offset: Offset(0, _floatAnim.value),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(_isHovered ? 0.25 : 0)
                      ..rotateX(_isHovered ? -0.08 : 0),
                    child: CustomPaint(
                      size: const Size(200, 260),
                      painter: _RobotPainter(
                        blinkScale: _blinkAnim.value,
                        pulseRadius: _pulseAnim.value,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  final double angle;
  _OrbitPainter(this.angle);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 4;

    final ringPaint = Paint()
      ..color = const Color(0xFF1D9E75).withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final List<double> dash = [6, 8];
    double dist = 0;
    bool draw = true;
    final path = Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    final metrics = path.computeMetrics().first;
    double start = 0;
    while (start < metrics.length) {
      final len = dash[draw ? 0 : 1];
      if (draw) {
        canvas.drawPath(
          metrics.extractPath(start, start + len),
          ringPaint,
        );
      }
      start += len;
      draw = !draw;
    }

    // Orbit dot
    final dx = cx + r * math.cos(angle - math.pi / 2);
    final dy = cy + r * math.sin(angle - math.pi / 2);
    canvas.drawCircle(
      Offset(dx, dy),
      5,
      Paint()..color = const Color(0xFF1D9E75).withOpacity(0.7),
    );
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => old.angle != angle;
}

class _RobotPainter extends CustomPainter {
  final double blinkScale;
  final double pulseRadius;

  _RobotPainter({required this.blinkScale, required this.pulseRadius});

  static const teal = Color(0xFF1D9E75);
  static const tealDark = Color(0xFF085041);
  static const body = Color(0xFF12121A);
  static const bodyInner = Color(0xFF0F1A16);
  static const border = Color(0xFF1D9E75);

  void _drawRoundRect(Canvas c, Paint p, double x, double y, double w, double h, double r) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)), p);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bodyFill = Paint()..color = body;
    final bodyInnerFill = Paint()..color = bodyInner;
    final tealFill = Paint()..color = teal;
    final tealDarkFill = Paint()..color = tealDark;
    final borderPaint = Paint()
      ..color = border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final connectorPaint = Paint()
      ..color = teal.withOpacity(0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // --- Antenna ---
    canvas.drawLine(const Offset(100, 16), const Offset(100, 36),
        Paint()..color = teal..strokeWidth = 3..strokeCap = StrokeCap.round);
    canvas.drawCircle(const Offset(100, 11), pulseRadius, tealFill);

    // --- Head ---
    _drawRoundRect(canvas, bodyFill, 62, 36, 76, 68, 18);
    _drawRoundRect(canvas, borderPaint, 62, 36, 76, 68, 18);
    _drawRoundRect(canvas, bodyInnerFill, 64, 38, 72, 64, 16);

    // Eye Left
    canvas.save();
    canvas.translate(85, 61);
    canvas.scale(1.0, blinkScale);
    canvas.translate(-85, -61);
    _drawRoundRect(canvas, tealFill, 76, 54, 18, 14, 7);
    canvas.drawCircle(const Offset(85, 61), 4, Paint()..color = const Color(0xFF04342C));
    canvas.drawCircle(const Offset(87, 59), 1.5, Paint()..color = const Color(0xFF5DCAA5));
    canvas.restore();

    // Eye Right
    canvas.save();
    canvas.translate(115, 61);
    canvas.scale(1.0, blinkScale);
    canvas.translate(-115, -61);
    _drawRoundRect(canvas, tealFill, 106, 54, 18, 14, 7);
    canvas.drawCircle(const Offset(115, 61), 4, Paint()..color = const Color(0xFF04342C));
    canvas.drawCircle(const Offset(117, 59), 1.5, Paint()..color = const Color(0xFF5DCAA5));
    canvas.restore();

    // Mouth / progress bar
    _drawRoundRect(canvas, Paint()..color = teal.withOpacity(0.3), 82, 80, 36, 8, 4);
    _drawRoundRect(canvas, Paint()..color = teal.withOpacity(0.8), 82, 80, 22, 8, 4);

    // --- Torso ---
    _drawRoundRect(canvas, bodyFill, 55, 112, 90, 80, 16);
    _drawRoundRect(canvas, borderPaint, 55, 112, 90, 80, 16);
    _drawRoundRect(canvas, bodyInnerFill, 57, 114, 86, 76, 14);

    // Screen lines
    _drawRoundRect(canvas, Paint()..color = teal.withOpacity(0.15), 70, 126, 60, 8, 4);
    _drawRoundRect(canvas, Paint()..color = teal.withOpacity(0.5), 70, 126, 38, 8, 4);
    _drawRoundRect(canvas, Paint()..color = teal.withOpacity(0.15), 70, 140, 60, 8, 4);
    _drawRoundRect(canvas, Paint()..color = teal.withOpacity(0.3), 70, 140, 50, 8, 4);
    _drawRoundRect(canvas, Paint()..color = teal.withOpacity(0.15), 70, 154, 60, 8, 4);
    _drawRoundRect(canvas, Paint()..color = teal.withOpacity(0.4), 70, 154, 28, 8, 4);
    _drawRoundRect(canvas, Paint()..color = teal.withOpacity(0.9), 83, 170, 34, 14, 7);

    // --- Arms ---
    _drawRoundRect(canvas, bodyFill, 28, 116, 24, 60, 12);
    _drawRoundRect(canvas, borderPaint, 28, 116, 24, 60, 12);
    _drawRoundRect(canvas, bodyInnerFill, 30, 118, 20, 56, 10);
    canvas.drawCircle(const Offset(40, 148), 6, Paint()..color = teal.withOpacity(0.4));

    _drawRoundRect(canvas, bodyFill, 148, 116, 24, 60, 12);
    _drawRoundRect(canvas, borderPaint, 148, 116, 24, 60, 12);
    _drawRoundRect(canvas, bodyInnerFill, 150, 118, 20, 56, 10);
    canvas.drawCircle(const Offset(160, 148), 6, Paint()..color = teal.withOpacity(0.4));

    // Arm connectors
    canvas.drawLine(const Offset(55, 126), const Offset(28, 130), connectorPaint);
    canvas.drawLine(const Offset(145, 126), const Offset(172, 130), connectorPaint);

    // --- Legs ---
    _drawRoundRect(canvas, bodyFill, 75, 192, 22, 48, 11);
    _drawRoundRect(canvas, borderPaint, 75, 192, 22, 48, 11);
    _drawRoundRect(canvas, bodyInnerFill, 77, 194, 18, 44, 9);
    canvas.drawCircle(const Offset(86, 232), 9, bodyFill);
    canvas.drawCircle(const Offset(86, 232), 9, borderPaint);

    _drawRoundRect(canvas, bodyFill, 103, 192, 22, 48, 11);
    _drawRoundRect(canvas, borderPaint, 103, 192, 22, 48, 11);
    _drawRoundRect(canvas, bodyInnerFill, 105, 194, 18, 44, 9);
    canvas.drawCircle(const Offset(114, 232), 9, bodyFill);
    canvas.drawCircle(const Offset(114, 232), 9, borderPaint);

    // Leg connectors
    canvas.drawLine(const Offset(75, 192), const Offset(86, 192), connectorPaint);
    canvas.drawLine(const Offset(125, 192), const Offset(114, 192), connectorPaint);
  }

  @override
  bool shouldRepaint(_RobotPainter old) =>
      old.blinkScale != blinkScale || old.pulseRadius != pulseRadius;
}
