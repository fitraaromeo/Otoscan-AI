import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 1. Donut Ring Chart Widget (Inspired by Reference Image Top Section)
class DonutGaugeWidget extends StatelessWidget {
  final double percentage;
  final String label;
  final List<Color> gradientColors;

  const DonutGaugeWidget({
    super.key,
    required this.percentage,
    required this.label,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 70,
          height: 70,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(70, 70),
                painter: _DonutRingPainter(
                  percentage: percentage,
                  gradientColors: gradientColors,
                  isDark: isDark,
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text(
                    '${(percentage * 100).round()}%',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            letterSpacing: 0.8,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _DonutRingPainter extends CustomPainter {
  final double percentage;
  final List<Color> gradientColors;
  final bool isDark;

  _DonutRingPainter({
    required this.percentage,
    required this.gradientColors,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 10) / 2;
    const strokeWidth = 8.5;

    // Track Paint (Ring Background)
    final trackPaint = Paint()
      ..color = isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    // Active Arc Gradient Paint
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: 3 * math.pi / 2,
      colors: gradientColors,
    );

    final activePaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    final sweepAngle = 2 * math.pi * percentage;
    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, activePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 2. Neon Pill Bar Chart (Inspired by "FITNESS" & "STEPS" in Reference Image)
class PillBarChartWidget extends StatelessWidget {
  final List<double> values; // 0.0 to 1.0
  final List<String> labels;

  const PillBarChartWidget({
    super.key,
    required this.values,
    required this.labels,
  });

  static const List<List<Color>> _barGradients = [
    [Color(0xFFFF2A85), Color(0xFFFF7E5F)],
    [Color(0xFFA855F7), Color(0xFF6366F1)],
    [Color(0xFFFF8A00), Color(0xFFFFD600)],
    [Color(0xFF00E5FF), Color(0xFF0088FF)],
    [Color(0xFFFF2A85), Color(0xFFA855F7)],
    [Color(0xFF00E676), Color(0xFF00E5FF)],
    [Color(0xFFFF7E5F), Color(0xFFFF2A85)],
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AKTIVITAS SCANNING',
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              Text(
                '7 Hari Terakhir',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 105,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(values.length, (index) {
                final heightFactor = values[index].clamp(0.15, 1.0);
                final colors = _barGradients[index % _barGradients.length];

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: 12,
                          height: 85 * heightFactor,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: colors,
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colors.first.withAlpha(76),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels[index],
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// 3. Smooth Wave Area Chart (Inspired by "HEALTH STATUS" in Reference Image)
class SmoothWaveAreaChartWidget extends StatelessWidget {
  final String title;

  const SmoothWaveAreaChartWidget({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? AppColors.neonCyan : AppColors.lightPrimary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentColor.withAlpha(102)),
                ),
                child: Text(
                  '98.4% Akurat',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 85,
            width: double.infinity,
            child: CustomPaint(
              painter: _WaveChartPainter(isDark: isDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveChartPainter extends CustomPainter {
  final bool isDark;

  _WaveChartPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final primaryColor = isDark ? AppColors.neonCyan : AppColors.lightPrimary;
    final secondaryColor = isDark ? AppColors.neonPink : const Color(0xFFE11D48);

    // Primary Gradient Wave (Front Wave)
    final cyanPath = Path();
    cyanPath.moveTo(0, h * 0.7);
    cyanPath.cubicTo(w * 0.2, h * 0.2, w * 0.35, h * 0.95, w * 0.55, h * 0.3);
    cyanPath.cubicTo(w * 0.75, h * 0.05, w * 0.85, h * 0.6, w, h * 0.25);
    cyanPath.lineTo(w, h);
    cyanPath.lineTo(0, h);
    cyanPath.close();

    final cyanGradient = LinearGradient(
      colors: [
        primaryColor.withAlpha(128),
        primaryColor.withAlpha(0),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    final cyanPaint = Paint()
      ..shader = cyanGradient.createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(cyanPath, cyanPaint);

    final cyanLinePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final cyanStrokePath = Path();
    cyanStrokePath.moveTo(0, h * 0.7);
    cyanStrokePath.cubicTo(w * 0.2, h * 0.2, w * 0.35, h * 0.95, w * 0.55, h * 0.3);
    cyanStrokePath.cubicTo(w * 0.75, h * 0.05, w * 0.85, h * 0.6, w, h * 0.25);
    canvas.drawPath(cyanStrokePath, cyanLinePaint);

    // Secondary Wave (Layered Behind)
    final pinkPath = Path();
    pinkPath.moveTo(0, h * 0.9);
    pinkPath.cubicTo(w * 0.25, h * 0.4, w * 0.45, h * 0.8, w * 0.7, h * 0.15);
    pinkPath.cubicTo(w * 0.85, h * 0.45, w * 0.95, h * 0.3, w, h * 0.5);
    pinkPath.lineTo(w, h);
    pinkPath.lineTo(0, h);
    pinkPath.close();

    final pinkGradient = LinearGradient(
      colors: [
        secondaryColor.withAlpha(90),
        secondaryColor.withAlpha(0),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    final pinkPaint = Paint()
      ..shader = pinkGradient.createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(pinkPath, pinkPaint);

    final pinkLinePaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final pinkStrokePath = Path();
    pinkStrokePath.moveTo(0, h * 0.9);
    pinkStrokePath.cubicTo(w * 0.25, h * 0.4, w * 0.45, h * 0.8, w * 0.7, h * 0.15);
    pinkStrokePath.cubicTo(w * 0.85, h * 0.45, w * 0.95, h * 0.3, w, h * 0.5);
    canvas.drawPath(pinkStrokePath, pinkLinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 4. Circular Neon Gradient Action Badges (Inspired by lower circles in reference image)
class NeonCircleBadge extends StatelessWidget {
  final IconData icon;
  final String percentage;
  final String label;
  final List<Color> gradientColors;

  const NeonCircleBadge({
    super.key,
    required this.icon,
    required this.percentage,
    required this.label,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withAlpha(90),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          percentage,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            fontSize: 8.5,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
