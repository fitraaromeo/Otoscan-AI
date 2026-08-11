import 'package:flutter/material.dart';

import '../models/inspection_model.dart';
import '../theme/app_theme.dart';

class VehiclePainterWidget extends StatelessWidget {
  final ScanAngle angle;
  final List<DamageItem> damages;
  final bool isScanning;
  final double scanProgress;
  final Function(double xRatio, double yRatio)? onTapCanvas;

  const VehiclePainterWidget({
    super.key,
    required this.angle,
    required this.damages,
    this.isScanning = false,
    this.scanProgress = 0.0,
    this.onTapCanvas,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapUp: (details) {
            if (onTapCanvas != null) {
              final RenderBox box = context.findRenderObject() as RenderBox;
              final localOffset = box.globalToLocal(details.globalPosition);
              final xRatio = localOffset.dx / constraints.maxWidth;
              final yRatio = localOffset.dy / constraints.maxHeight;
              onTapCanvas!(xRatio, yRatio);
            }
          },
          child: Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.darkSecondary.withAlpha(76) : AppColors.lightPrimary.withAlpha(51),
                width: 1.5,
              ),
            ),
            child: Stack(
              children: [
                // Custom Painter for Vehicle Wireframe & Grid
                CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: VehicleWireframePainter(
                    angle: angle,
                    isDark: isDark,
                    scanProgress: scanProgress,
                    isScanning: isScanning,
                  ),
                ),

                // Render High-Tech YOLO Rectangular Bounding Boxes
                ...damages.where((d) => d.isConfirmed).map((damage) {
                  final rectWidth = (damage.widthRatio * constraints.maxWidth).clamp(30.0, constraints.maxWidth * 0.92);
                  final rectHeight = (damage.heightRatio * constraints.maxHeight).clamp(24.0, constraints.maxHeight * 0.92);
                  final posX = (damage.xRatio * constraints.maxWidth) - (rectWidth / 2);
                  final posY = (damage.yRatio * constraints.maxHeight) - (rectHeight / 2);

                  Color boxColor = AppColors.warning;
                  if (damage.severity == DamageSeverity.berat) {
                    boxColor = AppColors.danger;
                  } else if (damage.severity == DamageSeverity.ringan) {
                    boxColor = AppColors.neonCyan;
                  }

                  return Positioned(
                    left: posX.clamp(4.0, constraints.maxWidth - rectWidth - 4.0),
                    top: posY.clamp(4.0, constraints.maxHeight - rectHeight - 4.0),
                    child: Tooltip(
                      message: '${damage.type} (${(damage.confidence * 100).toStringAsFixed(1)}%)',
                      child: Container(
                        width: rectWidth,
                        height: rectHeight,
                        decoration: BoxDecoration(
                          color: boxColor.withAlpha(35),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: boxColor, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: boxColor.withAlpha(90),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Label Badge at top-left of Bounding Box
                            Positioned(
                              top: -18,
                              left: -2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(230),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: boxColor, width: 1),
                                ),
                                child: Text(
                                  '${damage.type.split(' ').first} ${(damage.confidence * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: boxColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                            // Center Icon Indicator
                            Center(
                              child: Icon(
                                Icons.center_focus_weak_rounded,
                                size: 18,
                                color: boxColor.withAlpha(200),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                // Scanning Bar overlay
                if (isScanning)
                  Positioned(
                    top: scanProgress * constraints.maxHeight,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? AppColors.darkSecondary : AppColors.lightSecondary,
                            blurRadius: 10,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),

                // Angle Badge Label at Bottom Left
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withAlpha(230),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getAngleIcon(angle),
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'SISI: ${angle.label.toUpperCase()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getAngleIcon(ScanAngle angle) {
    switch (angle) {
      case ScanAngle.kanan:
        return Icons.directions_car_rounded;
      case ScanAngle.kiri:
        return Icons.directions_car_filled_outlined;
      case ScanAngle.depan:
        return Icons.directions_car_outlined;
      case ScanAngle.belakang:
        return Icons.minor_crash_rounded;
    }
  }
}

class VehicleWireframePainter extends CustomPainter {
  final ScanAngle angle;
  final bool isDark;
  final double scanProgress;
  final bool isScanning;

  VehicleWireframePainter({
    required this.angle,
    required this.isDark,
    required this.scanProgress,
    required this.isScanning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withAlpha(10)
      ..strokeWidth = 1.0;

    // Draw background grid lines
    const gridSpacing = 24.0;
    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Camera viewfinder HUD corner brackets
    _drawHUDCorners(canvas, size, isDark ? AppColors.darkSecondary : AppColors.lightSecondary);
  }

  void _drawHUDCorners(Canvas canvas, Size size, Color color) {
    final hudPaint = Paint()
      ..color = color.withAlpha(204)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    const cornerSize = 20.0;
    const padding = 16.0;

    // Top-Left
    canvas.drawPath(
      Path()
        ..moveTo(padding, padding + cornerSize)
        ..lineTo(padding, padding)
        ..lineTo(padding + cornerSize, padding),
      hudPaint,
    );
    // Top-Right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - padding - cornerSize, padding)
        ..lineTo(size.width - padding, padding)
        ..lineTo(size.width - padding, padding + cornerSize),
      hudPaint,
    );
    // Bottom-Left
    canvas.drawPath(
      Path()
        ..moveTo(padding, size.height - padding - cornerSize)
        ..lineTo(padding, size.height - padding)
        ..lineTo(padding + cornerSize, size.height - padding),
      hudPaint,
    );
    // Bottom-Right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - padding - cornerSize, size.height - padding)
        ..lineTo(size.width - padding, size.height - padding)
        ..lineTo(size.width - padding, size.height - padding - cornerSize),
      hudPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
