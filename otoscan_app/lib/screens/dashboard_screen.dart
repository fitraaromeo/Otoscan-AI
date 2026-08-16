import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/inspection_model.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'inspection_detail_screen.dart';
import 'vehicle_entry_dialog.dart';
import 'vehicle_scan_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshData();
    });
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        refreshData();
      }
    });
  }

  Future<void> refreshData() async {
    if (!mounted) return;
    await Provider.of<AppState>(
      context,
      listen: false,
    ).fetchInspectionsFromApi();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _openNewInspectionDialog(BuildContext context) async {
    final newRecord = await showDialog<VehicleRecord>(
      context: context,
      builder: (context) => const VehicleEntryDialog(),
    );

    if (newRecord != null && context.mounted) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.addRecord(newRecord);

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VehicleScanScreen(record: newRecord),
        ),
      );

      if (context.mounted) {
        appState.fetchInspectionsFromApi();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = true; // Dark mode only
    final textPrimary = AppColors.darkTextPrimary;
    final textSecondary = AppColors.darkTextSecondary;
    final cardBg = AppColors.darkSurfaceCard;
    final borderColor = AppColors.darkBorderDivider;

    return Consumer<AppState>(
      builder: (context, appState, child) {
        final records = appState.records
            .where((r) => r.nopol.trim().isNotEmpty)
            .toList();
        final totalInspections = records.length;

        final filteredRecords = records.where((r) {
          if (_searchQuery.trim().isEmpty) return true;
          final q = _searchQuery.trim().toLowerCase();
          return r.nopol.toLowerCase().contains(q) ||
              r.merk.toLowerCase().contains(q) ||
              r.tipe.toLowerCase().contains(q) ||
              r.ownerName.toLowerCase().contains(q) ||
              r.id.toLowerCase().contains(q) ||
              r.inspectorName.toLowerCase().contains(q);
        }).toList();

        int cleanCount = 0;
        int damageCount = 0;
        for (var r in records) {
          if (r.totalDamages == 0) {
            cleanCount++;
          } else {
            damageCount++;
          }
        }

        return Scaffold(
          backgroundColor: AppColors.darkBackground,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            titleSpacing: 20,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.neonCyan.withAlpha(35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.document_scanner_rounded,
                    color: AppColors.neonCyan,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'OtoScan AI',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Inspection System',
                        style: TextStyle(
                          fontSize: 10,
                          color: textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: const [
              SizedBox(width: 8),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: 40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Start Scan Container (Admin Only)
                  if (appState.isAdmin) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B1F2D),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(60),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(30),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.center_focus_strong_rounded,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Start Vehicle Inspection',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Click below to begin AI vehicle damage detection',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: () => _openNewInspectionDialog(context),
                              icon: const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                              label: const Text(
                                'New Inspection',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                elevation: 6,
                                shadowColor: AppColors.primary.withAlpha(120),
                                shape: const StadiumBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Statistics Summary Row
                  Row(
                    children: [
                      Expanded(
                        child: _StatMiniCard(
                          title: 'Total Inspections',
                          value: '$totalInspections',
                          icon: Icons.assignment_turned_in_rounded,
                          color: AppColors.primary,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatMiniCard(
                          title: 'Clean',
                          value: '$cleanCount',
                          icon: Icons.check_circle_outline_rounded,
                          color: AppColors.success,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatMiniCard(
                          title: 'Damaged',
                          value: '$damageCount',
                          icon: Icons.warning_amber_rounded,
                          color: AppColors.danger,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Inspection History Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Inspection History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        _searchQuery.isNotEmpty
                            ? '${filteredRecords.length} of ${records.length} Vehicles'
                            : '${records.length} Vehicles',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Live Search Input Bar
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: textPrimary, fontSize: 13),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search plate, make, model, owner, or ID...',
                        hintStyle: TextStyle(
                          color: textSecondary,
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.neonCyan,
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  color: textSecondary,
                                  size: 18,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                            color: AppColors.neonCyan,
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: AppColors.darkSurface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),

                  // Inspection Records List
                  if (filteredRecords.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _searchQuery.isNotEmpty
                                ? Icons.search_off_rounded
                                : Icons.inbox_rounded,
                            size: 48,
                            color: textSecondary.withAlpha(100),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No inspections matching "$_searchQuery"'
                                : 'No inspection history yet',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_searchQuery.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Reset Search'),
                            ),
                          ],
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredRecords.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final record = filteredRecords[index];
                        final hasDamage = record.totalDamages > 0;

                        return Container(
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(30),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(28),
                              onTap: () async {
                                appState.setActiveRecord(record);
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        InspectionDetailScreen(record: record),
                                  ),
                                );
                                if (context.mounted) {
                                  await appState.fetchInspectionsFromApi();
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color:
                                            (hasDamage
                                                    ? AppColors.danger
                                                    : AppColors.success)
                                                .withAlpha(25),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        hasDamage
                                            ? Icons.minor_crash_rounded
                                            : Icons.verified_rounded,
                                        color: hasDamage
                                            ? AppColors.danger
                                            : AppColors.success,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                record.nopol,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: textPrimary,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      (hasDamage
                                                              ? AppColors.danger
                                                              : AppColors
                                                                    .success)
                                                          .withAlpha(20),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  hasDamage
                                                      ? '${record.totalDamages} Damages'
                                                      : 'Clean',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: hasDamage
                                                        ? AppColors.danger
                                                        : AppColors.success,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${record.merk} ${record.tipe} • Owner: ${record.ownerName}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.access_time_rounded,
                                                size: 12,
                                                color: textSecondary.withAlpha(150),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formatDate(record.createdAt),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: textSecondary.withAlpha(180),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: textSecondary.withAlpha(120),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatMiniCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(15)
              : Colors.black.withAlpha(10),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime dt) {
  final localDt = dt.toLocal();
  final day = localDt.day.toString().padLeft(2, '0');
  const monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  final month = monthNames[localDt.month - 1];
  final year = localDt.year;
  final hour = localDt.hour.toString().padLeft(2, '0');
  final min = localDt.minute.toString().padLeft(2, '0');
  return '$day $month $year • $hour:$min';
}
