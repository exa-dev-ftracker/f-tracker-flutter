import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/app_haptics.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading || onPressed == null
          ? null
          : () {
              AppHaptics.light();
              onPressed!();
            },
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              )
            else ...[
              _buildGoogleIcon(),
              const SizedBox(width: 12),
              const Text(
                'Continue with Google',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleIcon() {
    return CustomPaint(
      size: const Size(20, 20),
      painter: _GoogleLogoPainter(),
    );
  }
}

class AppleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const AppleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading || onPressed == null
          ? null
          : () {
              AppHaptics.light();
              onPressed!();
            },
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
              )
            else ...[
              const Icon(Icons.apple, color: Colors.black, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Continue with Apple',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final paintBlue = Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.fill;
    final paintGreen = Paint()..color = const Color(0xFF34A853)..style = PaintingStyle.fill;
    final paintYellow = Paint()..color = const Color(0xFFFBBC05)..style = PaintingStyle.fill;
    final paintRed = Paint()..color = const Color(0xFFEA4335)..style = PaintingStyle.fill;

    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    // Red segment (top arc)
    final pathRed = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(Rect.fromCircle(center: center, radius: radius), -0.75 * 3.14159, 0.75 * 3.14159, false)
      ..close();
    canvas.drawPath(pathRed, paintRed);

    // Blue segment (right & horizontal crossbar)
    final pathBlue = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(Rect.fromCircle(center: center, radius: radius), 0, 0.5 * 3.14159, false)
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.drawPath(pathBlue, paintBlue);

    // Green segment (bottom arc)
    final pathGreen = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(Rect.fromCircle(center: center, radius: radius), 0.5 * 3.14159, 0.5 * 3.14159, false)
      ..close();
    canvas.drawPath(pathGreen, paintGreen);

    // Yellow segment (left arc)
    final pathYellow = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(Rect.fromCircle(center: center, radius: radius), 3.14159, 0.25 * 3.14159, false)
      ..close();
    canvas.drawPath(pathYellow, paintYellow);

    // Inner cutout circle
    final innerPaint = Paint()..color = AppColors.surface..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.58, innerPaint);

    // Blue horizontal crossbar
    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(center.dx - 1, center.dy - (radius * 0.22), radius + 1, radius * 0.44),
      const Radius.circular(2),
    );
    canvas.drawRRect(barRect, paintBlue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
