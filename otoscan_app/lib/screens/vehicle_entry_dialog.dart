import 'package:flutter/material.dart';
import '../models/inspection_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class VehicleEntryDialog extends StatefulWidget {
  const VehicleEntryDialog({super.key});

  @override
  State<VehicleEntryDialog> createState() => _VehicleEntryDialogState();
}

class _VehicleEntryDialogState extends State<VehicleEntryDialog> {
  final _merkController = TextEditingController();
  final _jenisController = TextEditingController();
  final _nopolController = TextEditingController();

  List<Map<String, dynamic>> _vehiclesList = [];
  List<Map<String, dynamic>> _employeesList = [];
  bool _isLoadingData = true;

  String? _selectedVehicleId;
  String? _selectedEmployeeId;
  String _selectedStatus = 'inProgress';

  bool _isManualVehicleEntry = false;
  bool _isSubmitting = false;

  String? _merkError;
  String? _jenisError;
  String? _nopolError;

  final List<String> _commonMerks = [
    'Toyota',
    'Honda',
    'Mitsubishi',
    'Suzuki',
    'Hyundai',
    'Daihatsu',
    'Wuling',
    'BMW',
  ];

  @override
  void initState() {
    super.initState();
    _fetchMasterData();
  }

  Future<void> _fetchMasterData() async {
    final vehicles = await ApiService.getVehicles();
    final employees = await ApiService.getEmployees();

    if (mounted) {
      setState(() {
        _vehiclesList = vehicles;
        _employeesList = employees;

        if (vehicles.isNotEmpty) {
          _selectedVehicleId = vehicles.first['id']?.toString();
        } else {
          _isManualVehicleEntry = true;
        }

        if (employees.isNotEmpty) {
          _selectedEmployeeId = employees.first['id']?.toString();
        }

        _isLoadingData = false;
      });
    }
  }

  @override
  void dispose() {
    _merkController.dispose();
    _jenisController.dispose();
    _nopolController.dispose();
    super.dispose();
  }

  Map<String, dynamic>? get _selectedVehicle {
    if (_selectedVehicleId == null) return null;
    try {
      return _vehiclesList.firstWhere((v) => v['id']?.toString() == _selectedVehicleId);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? get _selectedEmployee {
    if (_selectedEmployeeId == null) return null;
    try {
      return _employeesList.firstWhere((e) => e['id']?.toString() == _selectedEmployeeId);
    } catch (_) {
      return null;
    }
  }

  void _showVehicleSearchModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _SearchablePickerSheet<Map<String, dynamic>>(
          title: 'Cari & Pilih Kendaraan',
          hintText: 'Ketik Nopol, Merk, Tipe, Pemilik...',
          items: _vehiclesList,
          filterPredicate: (item, query) {
            final nopol = item['nopol']?.toString().toLowerCase() ?? '';
            final merk = item['merk']?.toString().toLowerCase() ?? '';
            final tipe = item['tipe']?.toString().toLowerCase() ?? '';
            final owner = (item['user'] != null && item['user']['name'] != null)
                ? item['user']['name'].toString().toLowerCase()
                : '';
            final q = query.toLowerCase();
            return nopol.contains(q) || merk.contains(q) || tipe.contains(q) || owner.contains(q);
          },
          itemBuilder: (item) {
            final id = item['id']?.toString() ?? '';
            final nopol = item['nopol']?.toString() ?? 'NOPOL';
            final merk = item['merk']?.toString() ?? '';
            final tipe = item['tipe']?.toString() ?? '';
            final jenis = item['jenis']?.toString() ?? 'Car';
            final owner = (item['user'] != null && item['user']['name'] != null)
                ? item['user']['name'].toString()
                : 'Tanpa Pemilik';
            final isSelected = id == _selectedVehicleId;

            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.neonCyan.withAlpha(40) : Colors.blue.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.directions_car_filled_rounded,
                  color: isSelected ? AppColors.neonCyan : AppColors.primary,
                  size: 20,
                ),
              ),
              title: Text(
                '$nopol - $merk $tipe',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              subtitle: Text(
                'Pemilik: $owner • Jenis: $jenis',
                style: const TextStyle(fontSize: 11.5),
              ),
              trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.success) : null,
              onTap: () {
                setState(() {
                  _selectedVehicleId = id;
                  _isManualVehicleEntry = false;
                });
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  void _showEmployeeSearchModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _SearchablePickerSheet<Map<String, dynamic>>(
          title: 'Cari & Pilih Inspector / Employee',
          hintText: 'Ketik Nama atau Kode Karyawan...',
          items: _employeesList,
          filterPredicate: (item, query) {
            final name = item['name']?.toString().toLowerCase() ?? '';
            final code = item['code']?.toString().toLowerCase() ?? '';
            final q = query.toLowerCase();
            return name.contains(q) || code.contains(q);
          },
          itemBuilder: (item) {
            final id = item['id']?.toString() ?? '';
            final name = item['name']?.toString() ?? 'Employee';
            final code = item['code']?.toString() ?? '';
            final isSelected = id == _selectedEmployeeId;

            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.neonCyan.withAlpha(40) : Colors.purple.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.badge_rounded,
                  color: isSelected ? AppColors.neonCyan : Colors.purple,
                  size: 20,
                ),
              ),
              title: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              subtitle: Text(
                code.isNotEmpty ? 'Kode: $code' : 'Staff Inspector',
                style: const TextStyle(fontSize: 11.5),
              ),
              trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.success) : null,
              onTap: () {
                setState(() {
                  _selectedEmployeeId = id;
                });
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  void _submitForm() async {
    if (_isSubmitting) return;

    if (_isManualVehicleEntry) {
      setState(() {
        _merkError = _merkController.text.trim().isEmpty ? 'Merk kendaraan wajib diisi' : null;
        _jenisError = _jenisController.text.trim().isEmpty ? 'Tipe / varian wajib diisi' : null;
        _nopolError = _nopolController.text.trim().isEmpty ? 'Nopol kendaraan wajib diisi' : null;
      });
      if (_merkError != null || _jenisError != null || _nopolError != null) return;
    }

    setState(() {
      _isSubmitting = true;
    });

    String nopolStr = '';
    String merkStr = '';
    String tipeStr = '';
    String jenisStr = 'MPV';
    String ownerStr = 'Client';

    if (!_isManualVehicleEntry && _selectedVehicle != null) {
      final selectedVehicle = _selectedVehicle!;
      nopolStr = selectedVehicle['nopol']?.toString() ?? 'NOPOL';
      merkStr = selectedVehicle['merk']?.toString() ?? 'Toyota';
      tipeStr = selectedVehicle['tipe']?.toString() ?? 'Car';
      jenisStr = selectedVehicle['jenis']?.toString() ?? 'MPV';
      if (selectedVehicle['user'] != null && selectedVehicle['user']['name'] != null) {
        ownerStr = selectedVehicle['user']['name'].toString();
      }
    } else {
      nopolStr = _nopolController.text.trim().toUpperCase();
      merkStr = _merkController.text.trim();
      tipeStr = _jenisController.text.trim();
      jenisStr = 'Car';
    }

    // Call backend API (POST /api/inspections)
    final backendInspectionId = await ApiService.createInspection(
      vehicleId: _isManualVehicleEntry ? null : _selectedVehicleId,
      nopol: nopolStr,
      merk: merkStr,
      tipe: tipeStr,
      jenis: jenisStr,
      employeeId: _selectedEmployeeId,
      status: _selectedStatus,
    );

    String inspectorStr = 'Staff Inspector';
    if (_selectedEmployee != null && _selectedEmployee!['name'] != null) {
      inspectorStr = _selectedEmployee!['name'].toString();
    }

    final newRecord = VehicleRecord.createNew(
      customId: backendInspectionId,
      nopol: nopolStr,
      merk: merkStr,
      tipe: tipeStr,
      jenis: jenisStr,
      ownerName: ownerStr,
      inspectorName: inspectorStr,
    );

    if (mounted) {
      Navigator.of(context).pop(newRecord);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accentPrimary = isDark ? AppColors.neonCyan : AppColors.lightPrimary;
    final cardBg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final borderColor = isDark ? Colors.white.withAlpha(25) : Colors.black.withAlpha(25);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(
            color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 90 : 30),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppColors.cyanGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonCyan.withAlpha(90),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New Inspection',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'Vehicle, Inspector & Status Selection',
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              Divider(color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(20)),
              const SizedBox(height: 14),

              if (_isLoadingData)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                // 1. VEHICLE SEARCH PICKER / MANUAL SELECTION
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PILIH KENDARAAN (VEHICLE) *',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: accentPrimary,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isManualVehicleEntry = !_isManualVehicleEntry;
                        });
                      },
                      child: Text(
                        _isManualVehicleEntry ? '← Cari Master Data' : '+ Input Baru',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (!_isManualVehicleEntry) ...[
                  // Searchable Vehicle Picker Button
                  InkWell(
                    onTap: () => _showVehicleSearchModal(context),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.directions_car_outlined, color: accentPrimary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _selectedVehicle != null
                                ? Text(
                                    '${_selectedVehicle!['nopol']} - ${_selectedVehicle!['merk']} ${_selectedVehicle!['tipe']}',
                                    style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : Text(
                                    'Cari Kendaraan...',
                                    style: TextStyle(color: textSecondary, fontSize: 13),
                                  ),
                          ),
                          Icon(Icons.search_rounded, color: accentPrimary, size: 20),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // Manual Merk Input
                  TextFormField(
                    controller: _merkController,
                    style: TextStyle(color: textPrimary),
                    onChanged: (_) {
                      if (_merkError != null) setState(() => _merkError = null);
                    },
                    decoration: InputDecoration(
                      hintText: 'Merk (e.g. Toyota, Honda)',
                      hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                      errorText: _merkError,
                      prefixIcon: Icon(Icons.directions_car_outlined, color: accentPrimary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: accentPrimary, width: 1.5)),
                      filled: true,
                      fillColor: cardBg,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Quick Merk Chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _commonMerks.map((merk) {
                      final isSelected = _merkController.text == merk;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _merkController.text = isSelected ? '' : merk;
                            _merkError = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? accentPrimary.withAlpha(46) : (isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(10)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSelected ? accentPrimary : borderColor),
                          ),
                          child: Text(
                            merk,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? accentPrimary : textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  // Manual Tipe Input
                  TextFormField(
                    controller: _jenisController,
                    style: TextStyle(color: textPrimary),
                    onChanged: (_) {
                      if (_jenisError != null) setState(() => _jenisError = null);
                    },
                    decoration: InputDecoration(
                      hintText: 'Tipe / Varian (e.g. Fortuner VRZ)',
                      hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                      errorText: _jenisError,
                      prefixIcon: Icon(Icons.category_outlined, color: accentPrimary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: accentPrimary, width: 1.5)),
                      filled: true,
                      fillColor: cardBg,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Manual Nopol Input
                  TextFormField(
                    controller: _nopolController,
                    style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (_) {
                      if (_nopolError != null) setState(() => _nopolError = null);
                    },
                    decoration: InputDecoration(
                      hintText: 'Nopol (e.g. B 1234 ABC)',
                      hintStyle: TextStyle(color: textSecondary, fontSize: 13, letterSpacing: 0),
                      errorText: _nopolError,
                      prefixIcon: Icon(Icons.badge_outlined, color: accentPrimary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: accentPrimary, width: 1.5)),
                      filled: true,
                      fillColor: cardBg,
                    ),
                  ),
                ],

                const SizedBox(height: 18),

                // 2. EMPLOYEE SEARCH PICKER
                Text(
                  'PILIH INSPECTOR / EMPLOYEE *',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: accentPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _showEmployeeSearchModal(context),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.person_outline_rounded, color: accentPrimary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _selectedEmployee != null
                              ? Text(
                                  '${_selectedEmployee!['name']}${_selectedEmployee!['code'] != null ? ' (${_selectedEmployee!['code']})' : ''}',
                                  style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                )
                              : Text(
                                  'Cari Inspector / Karyawan...',
                                  style: TextStyle(color: textSecondary, fontSize: 13),
                                ),
                        ),
                        Icon(Icons.search_rounded, color: accentPrimary, size: 20),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // 3. STATUS INSPECTIONS DROPDOWN
                Text(
                  'STATUS INSPEKSI *',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: accentPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedStatus,
                  dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
                  style: TextStyle(color: textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.timeline_rounded, color: accentPrimary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: accentPrimary, width: 1.5)),
                    filled: true,
                    fillColor: cardBg,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'inProgress',
                      child: Text('In Progress (Sedang Berjalan)'),
                    ),
                    DropdownMenuItem(
                      value: 'draft',
                      child: Text('Draft (Draf Simpan)'),
                    ),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text('Completed (Selesai Inspeksi)'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedStatus = val;
                      });
                    }
                  },
                ),
              ],

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitForm,
                  icon: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
                  label: Text(
                    _isSubmitting ? 'CREATING INSPECTION...' : 'START 4-SIDE SCAN',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
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
      ),
    );
  }
}

// Reusable Searchable Picker Sheet Component
class _SearchablePickerSheet<T> extends StatefulWidget {
  final String title;
  final String hintText;
  final List<T> items;
  final bool Function(T item, String query) filterPredicate;
  final Widget Function(T item) itemBuilder;

  const _SearchablePickerSheet({
    required this.title,
    required this.hintText,
    required this.items,
    required this.filterPredicate,
    required this.itemBuilder,
  });

  @override
  State<_SearchablePickerSheet<T>> createState() => _SearchablePickerSheetState<T>();
}

class _SearchablePickerSheetState<T> extends State<_SearchablePickerSheet<T>> {
  final TextEditingController _queryController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(15);

    final filteredItems = widget.items.where((item) => widget.filterPredicate(item, _query)).toList();

    return Material(
      color: cardBg,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textSecondary.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: textSecondary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Live Search Bar
          TextField(
            controller: _queryController,
            autofocus: true,
            style: TextStyle(color: textPrimary, fontSize: 13),
            onChanged: (val) => setState(() => _query = val),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(color: textSecondary, fontSize: 13),
              prefixIcon: Icon(Icons.search_rounded, color: isDark ? AppColors.neonCyan : AppColors.primary, size: 20),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded, color: textSecondary, size: 18),
                      onPressed: () {
                        _queryController.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: borderColor)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: isDark ? AppColors.neonCyan : AppColors.primary, width: 1.5),
              ),
              filled: true,
              fillColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),

          // Results Count
          Text(
            '${filteredItems.length} hasil ditemukan',
            style: TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // Virtualized List
          Expanded(
            child: filteredItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 48, color: textSecondary.withAlpha(100)),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ada hasil untuk "$_query"',
                          style: TextStyle(color: textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : Material(
                    color: Colors.transparent,
                    child: ListView.separated(
                      itemCount: filteredItems.length,
                      separatorBuilder: (_, _) => Divider(color: borderColor, height: 1),
                      itemBuilder: (context, index) {
                        return widget.itemBuilder(filteredItems[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    ),
  );
  }
}

