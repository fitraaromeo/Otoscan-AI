import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/capsule_search_bar.dart';

class VehicleManagementScreen extends StatefulWidget {
  const VehicleManagementScreen({super.key});

  @override
  State<VehicleManagementScreen> createState() => VehicleManagementScreenState();
}

class VehicleManagementScreenState extends State<VehicleManagementScreen> {
  List<Map<String, dynamic>> _vehicles = [];
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    refreshData();
  }

  Future<void> refreshData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final vehiclesData = await ApiService.getVehicles();
    final usersData = await ApiService.getUsers();
    if (mounted) {
      setState(() {
        _vehicles = vehiclesData;
        _users = usersData;
        _isLoading = false;
      });
    }
  }

  void _showAddOrEditVehicleDialog({Map<String, dynamic>? existingVehicle}) {
    final isEditing = existingVehicle != null;
    final nopolController = TextEditingController(text: existingVehicle?['nopol'] ?? '');
    final merkController = TextEditingController(text: existingVehicle?['merk'] ?? '');
    final tipeController = TextEditingController(text: existingVehicle?['tipe'] ?? '');
    String selectedJenis = existingVehicle?['jenis'] ?? 'Sedan';
    String? selectedUserId = existingVehicle?['userId']?.toString() ?? existingVehicle?['user_id']?.toString();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit_rounded : Icons.directions_car_filled_rounded,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(isEditing ? 'Edit Vehicle Details' : 'Add Vehicle'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nopolController,
                      decoration: const InputDecoration(
                        labelText: 'License Plate Number *',
                        hintText: 'e.g. B 1234 ABC',
                        prefixIcon: Icon(Icons.pin),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: merkController,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Make *',
                        hintText: 'e.g. Toyota, Honda',
                        prefixIcon: Icon(Icons.branding_watermark),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: tipeController,
                      decoration: const InputDecoration(
                        labelText: 'Model / Variant',
                        hintText: 'e.g. HR-V, Avanza',
                        prefixIcon: Icon(Icons.model_training),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedJenis,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Category',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: ['Sedan', 'SUV', 'MPV', 'Hatchback', 'Crossover', 'Coupe', 'Minivan', 'Pickup']
                          .map((j) => DropdownMenuItem(value: j, child: Text(j)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedJenis = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      initialValue: selectedUserId,
                      decoration: const InputDecoration(
                        labelText: 'Owner (Client)',
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('-- No Owner --')),
                        ..._users.map((u) => DropdownMenuItem<String?>(
                              value: u['id'].toString(),
                              child: Text(u['name'] ?? 'Client'),
                            )),
                      ],
                      onChanged: (val) {
                        setDialogState(() => selectedUserId = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final nav = Navigator.of(dialogContext);

                    if (nopolController.text.trim().isEmpty || merkController.text.trim().isEmpty) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('License plate and make are required')),
                      );
                      return;
                    }

                    bool success = false;
                    if (isEditing) {
                      success = await ApiService.updateVehicle(
                        id: existingVehicle['id'].toString(),
                        nopol: nopolController.text.trim().toUpperCase(),
                        merk: merkController.text.trim(),
                        tipe: tipeController.text.trim(),
                        jenis: selectedJenis,
                        userId: selectedUserId,
                      );
                    } else {
                      success = await ApiService.createVehicle(
                        nopol: nopolController.text.trim().toUpperCase(),
                        merk: merkController.text.trim(),
                        tipe: tipeController.text.trim(),
                        jenis: selectedJenis,
                        userId: selectedUserId,
                      );
                    }

                    nav.pop();
                    if (success) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            isEditing ? '✅ Vehicle updated successfully!' : '✅ Vehicle added successfully!',
                          ),
                        ),
                      );
                      refreshData();
                    } else {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(isEditing ? '❌ Failed to update Vehicle' : '❌ Failed to add Vehicle'),
                        ),
                      );
                    }
                  },
                  child: Text(isEditing ? 'Update' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteVehicle(Map<String, dynamic> vehicle) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.danger),
              SizedBox(width: 10),
              Text('Delete Vehicle'),
            ],
          ),
          content: Text('Are you sure you want to delete vehicle "${vehicle['nopol']}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(dialogContext);

                final success = await ApiService.deleteVehicle(vehicle['id'].toString());

                nav.pop();
                if (success) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('✅ Vehicle deleted successfully!')),
                  );
                  refreshData();
                } else {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('❌ Failed to delete Vehicle')),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredVehicles = _vehicles.where((v) {
      final nopol = (v['nopol'] ?? '').toString().toLowerCase();
      final merk = (v['merk'] ?? '').toString().toLowerCase();
      final tipe = (v['tipe'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      return nopol.contains(q) || merk.contains(q) || tipe.contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Management'),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          heroTag: 'vehicle_fab',
          onPressed: () => _showAddOrEditVehicleDialog(),
          icon: const Icon(Icons.add_a_photo_rounded),
          label: const Text('Add Vehicle'),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: CapsuleSearchBar(
              hintText: 'Search plate number, make, or model...',
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: refreshData,
                    child: filteredVehicles.isEmpty
                        ? SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Container(
                              height: MediaQuery.of(context).size.height * 0.5,
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey.withAlpha(100)),
                                  const SizedBox(height: 12),
                                  const Text('No Vehicle Data Found'),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () => _showAddOrEditVehicleDialog(),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add First Vehicle'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 100),
                            itemCount: filteredVehicles.length,
                            itemBuilder: (context, index) {
                              final v = filteredVehicles[index];
                              final owner = v['user'] as Map<String, dynamic>?;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withAlpha(20),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.directions_car_filled_rounded, color: AppColors.primary),
                                  ),
                                  title: Row(
                                    children: [
                                      Text(
                                        v['nopol'] ?? '-',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withAlpha(20),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          v['jenis'] ?? 'SUV',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${v['merk'] ?? '-'} ${v['tipe'] ?? ''}'),
                                      if (owner != null && owner['name'] != null)
                                        Text(
                                          '👤 Owner: ${owner['name']}',
                                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500),
                                        ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
                                        tooltip: 'Edit Vehicle',
                                        onPressed: () => _showAddOrEditVehicleDialog(existingVehicle: v),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                                        tooltip: 'Delete Vehicle',
                                        onPressed: () => _confirmDeleteVehicle(v),
                                      ),
                                    ],
                                  ),
                                  isThreeLine: true,
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
