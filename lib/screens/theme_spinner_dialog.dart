import 'dart:math';
import 'package:flutter/material.dart';

class ThemeWheel extends StatefulWidget {
  const ThemeWheel({super.key});

  @override
  State<ThemeWheel> createState() => _ThemeWheelState();
}

class _ThemeWheelState extends State<ThemeWheel> with SingleTickerProviderStateMixin {
  static final List<ThemeSlice> _slices = [
    ThemeSlice('🍇', 'Purple Passion', Colors.purple),
    ThemeSlice('🌊', 'Ocean Breeze', Colors.blue),
    ThemeSlice('🌅', 'Sunset Glow', Colors.orange),
    ThemeSlice('🍁', 'Autumn Whisper', Colors.brown),
    ThemeSlice('❄️', 'Winter Frost', Colors.white),
    ThemeSlice('🌿', 'Spring Meadow', Colors.green),
  ];

  late AnimationController _rotationController;
  Animation<double>? _spinAnimation;
  int _selectedSliceIndex = 0;
  bool _isSpinning = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
  }

  void _spinWheel() {
    if (_isSpinning) return;

    setState(() {
      _isSpinning = true;
    });

    final randomSpin = Random().nextDouble() * 2 * pi + 3 * pi;

    _rotationController.reset();
    _spinAnimation = Tween<double>(
      begin: 0,
      end: randomSpin,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.decelerate,
    ));

    _rotationController.forward().then((_) {
      setState(() {
        _selectedSliceIndex = ((_slices.length - (randomSpin / (2 * pi / _slices.length)).floor() - 1) % _slices.length);
        _isSpinning = false;
      });
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Theme Spinner 🎲'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              _buildRotatingWheel(),
              _buildSpinnerArrow(),
            ],
          ),
          const SizedBox(height: 16),
          _buildSelectedThemeDisplay(),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isSpinning ? null : _spinWheel,
            child: Text(_isSpinning ? 'Spinning...' : 'Spin Wheel'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildRotatingWheel() {
    return SizedBox(
      width: 250,
      height: 250,
      child: AnimatedBuilder(
        animation: _spinAnimation ?? const AlwaysStoppedAnimation(0),
        builder: (context, child) {
          return Transform.rotate(
            angle: _spinAnimation?.value ?? 0,
            child: CustomPaint(
              painter: ThemeWheelPainter(_slices),
              child: const SizedBox(
                width: 250,
                height: 250,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpinnerArrow() {
    return Positioned(
      top: 0,
      child: CustomPaint(
        painter: TrianglePainter(),
        child: const SizedBox(
          width: 30,
          height: 30,
        ),
      ),
    );
  }

  Widget _buildSelectedThemeDisplay() {
    final selectedSlice = _slices[_selectedSliceIndex];
    return Text(
      '${selectedSlice.emoji} ${selectedSlice.name}',
      style: Theme.of(context).textTheme.titleLarge,
    );
  }
}

class ThemeSlice {
  final String emoji;
  final String name;
  final Color color;

  const ThemeSlice(this.emoji, this.name, this.color);
}

class ThemeWheelPainter extends CustomPainter {
  final List<ThemeSlice> slices;

  const ThemeWheelPainter(this.slices);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sliceAngle = 2 * pi / slices.length;

    for (int index = 0; index < slices.length; index++) {
      _drawSlice(canvas, center, radius, index, sliceAngle);
      _drawEmoji(canvas, center, radius, index, sliceAngle);
    }
  }

  void _drawSlice(Canvas canvas, Offset center, double radius, int index, double sliceAngle) {
    final startAngle = index * sliceAngle - pi / 2;
    final paint = Paint()
      ..color = slices[index].color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sliceAngle,
        false,
      )
      ..close();

    canvas.drawPath(path, paint);
  }

  void _drawEmoji(Canvas canvas, Offset center, double radius, int index, double sliceAngle) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: slices[index].emoji,
        style: const TextStyle(fontSize: 24),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final angle = index * sliceAngle + sliceAngle / 2 - pi / 2;
    final emojiOffset = Offset(
      center.dx + (radius * 0.6) * cos(angle),
      center.dy + (radius * 0.6) * sin(angle),
    );

    textPainter.paint(
      canvas,
      emojiOffset - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 