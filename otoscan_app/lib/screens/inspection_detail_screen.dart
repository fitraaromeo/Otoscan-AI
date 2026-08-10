import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/inspection_model.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_delete_dialog.dart';
import '../widgets/vehicle_painter.dart';
import 'vehicle_scan_screen.dart';

class InspectionDetailScreen extends StatelessWidget {
  final VehicleRecord record;

  const InspectionDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final accentColor = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;

    return Consumer<AppState>(
      builder: (context, appState, child) {
        final currentRecord = appState.records.firstWhere(
          (r) => r.id == record.id,
          orElse: () => record,
        );

        final allDamages = <DamageItem>[];
        for (var capture in currentRecord.angleCaptures.values) {
          allDamages.addAll(capture.damages.where((d) => d.isConfirmed));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Inspection Report: ${currentRecord.nopol}'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Vehicle Header Card
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primaryColor.withAlpha(38),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.directions_car, color: primaryColor, size: 32),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentRecord.nopol,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${currentRecord.merk} ${currentRecord.tipe} (${currentRecord.jenis})',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.neonCyan : AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Pemilik: ${currentRecord.ownerName}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.success.withAlpha(51),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.success),
                          ),
                          child: Text(
                            currentRecord.status.label,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Metrics Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetric(
                          context,
                          'Scan Angles',
                          '${currentRecord.capturedAnglesCount} / 4',
                          Icons.radar_rounded,
                          accentColor,
                        ),
                        Container(height: 30, width: 1, color: Colors.grey.withAlpha(76)),
                        _buildMetric(
                          context,
                          'Total Damages',
                          '${currentRecord.totalDamages}',
                          Icons.warning_amber_rounded,
                          currentRecord.totalDamages > 0 ? AppColors.danger : AppColors.success,
                        ),
                        Container(height: 30, width: 1, color: Colors.grey.withAlpha(76)),
                        _buildMetric(
                          context,
                          'Inspector',
                          currentRecord.inspectorName,
                          Icons.verified_user_outlined,
                          primaryColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 4 Angles Visual Gallery Section
            Text(
              '4-Side Vehicle Scan Results',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: ScanAngle.values.map((angle) {
                final capture = currentRecord.angleCaptures[angle]!;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${angle.label} Side',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            if (capture.isCaptured)
                              const Icon(Icons.check_circle, color: AppColors.success, size: 16)
                            else
                              const Icon(Icons.error_outline, color: Colors.grey, size: 16),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: (capture.annotatedImageUrl != null && capture.annotatedImageUrl!.isNotEmpty)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    capture.annotatedImageUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (ctx, err, stack) => (capture.rawImageUrl != null && capture.rawImageUrl!.isNotEmpty)
                                        ? Image.network(
                                            capture.rawImageUrl!,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            errorBuilder: (ctx2, err2, stack2) => VehiclePainterWidget(angle: angle, damages: capture.damages),
                                          )
                                        : VehiclePainterWidget(angle: angle, damages: capture.damages),
                                  ),
                                )
                              : (capture.rawImageUrl != null && capture.rawImageUrl!.isNotEmpty)
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        capture.rawImageUrl!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        errorBuilder: (ctx, err, stack) => VehiclePainterWidget(angle: angle, damages: capture.damages),
                                      ),
                                    )
                                  : VehiclePainterWidget(
                                      angle: angle,
                                      damages: capture.damages,
                                    ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${capture.damages.where((d) => d.isConfirmed).length} Damages',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: capture.damages.isNotEmpty ? AppColors.danger : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Damage Details Section
            Text(
              'Damage Findings Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (allDamages.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.verified, size: 48, color: AppColors.success),
                        const SizedBox(height: 8),
                        const Text(
                          'Clean Vehicle & Damage Free!',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const Text(
                          '4-Side scan results found no physical defects.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: allDamages.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final damage = allDamages[index];

                  Color badgeColor = AppColors.warning;
                  if (damage.severity == DamageSeverity.berat) {
                    badgeColor = AppColors.danger;
                  } else if (damage.severity == DamageSeverity.ringan) {
                    badgeColor = AppColors.info;
                  }

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: badgeColor.withAlpha(38),
                        child: Icon(Icons.build_outlined, color: badgeColor),
                      ),
                      title: Row(
                        children: [
                          Text(damage.type, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeColor.withAlpha(38),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: badgeColor),
                            ),
                            child: Text(
                              damage.severity.label,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text('${damage.angle.label} Side • ${damage.description}'),
                    ),
                  );
                },
              ),

            const SizedBox(height: 24),
            // Re-Scan Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  final appState = Provider.of<AppState>(context, listen: false);
                  appState.setActiveRecord(record);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => VehicleScanScreen(record: record),
                    ),
                  );
                },
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text(
                  'Re-Open 4-Side Scanner',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Large Prominent Delete Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AnimatedDeleteDialog(
                      inspectionId: record.id,
                      nopol: record.nopol,
                      onDeletedSuccess: () {
                        Navigator.of(context).pop(); // Return to dashboard
                      },
                    ),
                  );
                },
                icon: const Icon(Icons.delete_forever_rounded, size: 20),
                label: const Text(
                  'Hapus Data Inspeksi Ini',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.3,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: BorderSide(
                    color: AppColors.danger.withAlpha(180),
                    width: 1.5,
                  ),
                  shape: const StadiumBorder(),
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

  Widget _buildMetric(BuildContext context, String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
