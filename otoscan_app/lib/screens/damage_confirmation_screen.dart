import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/inspection_model.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class DamageConfirmationModal extends StatefulWidget {
  final ScanAngle angle;

  const DamageConfirmationModal({super.key, required this.angle});

  @override
  State<DamageConfirmationModal> createState() => _DamageConfirmationModalState();
}

class _DamageConfirmationModalState extends State<DamageConfirmationModal> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final accentColor = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;

    return Consumer<AppState>(
      builder: (context, appState, child) {
        final record = appState.activeRecord;
        if (record == null) return const SizedBox.shrink();

        final capture = record.getAngleCapture(widget.angle);
        final damages = capture.damages;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(76),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Title Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withAlpha(51),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.verified_rounded, color: accentColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Confirm ${widget.angle.label} Side Damage',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${damages.length} AI findings detected',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Damage List
              if (damages.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 48, color: AppColors.success),
                        const SizedBox(height: 12),
                        const Text(
                          'No damage detected on this side!',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Vehicle is in good condition for the ${widget.angle.label} side',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: damages.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final damage = damages[index];

                      Color badgeColor = AppColors.warning;
                      if (damage.severity == DamageSeverity.berat) {
                        badgeColor = AppColors.danger;
                      } else if (damage.severity == DamageSeverity.ringan) {
                        badgeColor = AppColors.info;
                      }

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: damage.isConfirmed ? badgeColor.withAlpha(102) : Colors.grey.withAlpha(51),
                          ),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: damage.isConfirmed,
                              activeColor: primaryColor,
                              onChanged: (val) {
                                // Toggle damage confirmation state
                              },
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        damage.type,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: badgeColor.withAlpha(38),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: badgeColor, width: 1),
                                        ),
                                        child: Text(
                                          damage.severity.label,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: badgeColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    damage.description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 16),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check),
                  label: const Text('Confirm & Save Inspection Log'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
