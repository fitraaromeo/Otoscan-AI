import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/capsule_search_bar.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => UserManagementScreenState();
}

class UserManagementScreenState extends State<UserManagementScreen> {
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
    final data = await ApiService.getUsers();
    if (mounted) {
      setState(() {
        _users = data;
        _isLoading = false;
      });
    }
  }

  void _showAddOrEditUserDialog({Map<String, dynamic>? existingUser}) {
    final isEditing = existingUser != null;
    final nameController = TextEditingController(text: existingUser?['name'] ?? '');
    final emailController = TextEditingController(text: existingUser?['email'] ?? '');
    final phoneController = TextEditingController(text: existingUser?['phone'] ?? '');
    final addressController = TextEditingController(text: existingUser?['address'] ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                isEditing ? Icons.edit_rounded : Icons.person_add_rounded,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Text(isEditing ? 'Edit Client' : 'Add Client'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
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

                if (nameController.text.trim().isEmpty) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Full name is required')),
                  );
                  return;
                }

                bool success = false;
                if (isEditing) {
                  success = await ApiService.updateUser(
                    id: existingUser['id'].toString(),
                    name: nameController.text.trim(),
                    email: emailController.text.trim(),
                    phone: phoneController.text.trim(),
                    address: addressController.text.trim(),
                  );
                } else {
                  success = await ApiService.createUser(
                    name: nameController.text.trim(),
                    email: emailController.text.trim(),
                    phone: phoneController.text.trim(),
                    address: addressController.text.trim(),
                  );
                }

                nav.pop();
                if (success) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        isEditing ? '✅ Client updated successfully!' : '✅ Client added successfully!',
                      ),
                    ),
                  );
                  refreshData();
                } else {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(isEditing ? '❌ Failed to update Client' : '❌ Failed to add Client'),
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
  }

  void _confirmDeleteUser(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.danger),
              SizedBox(width: 10),
              Text('Delete Client'),
            ],
          ),
          content: Text('Are you sure you want to delete "${user['name']}"?'),
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

                final success = await ApiService.deleteUser(user['id'].toString());

                nav.pop();
                if (success) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('✅ Client deleted successfully!')),
                  );
                  refreshData();
                } else {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('❌ Failed to delete Client')),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final filteredUsers = _users.where((u) {
      final name = (u['name'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      return name.contains(q) || email.contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Management'),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          heroTag: 'user_fab',
          onPressed: () => _showAddOrEditUserDialog(),
          icon: const Icon(Icons.person_add_rounded),
          label: const Text('Add Client'),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: CapsuleSearchBar(
              hintText: 'Search client name or email...',
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: refreshData,
                    child: filteredUsers.isEmpty
                        ? SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Container(
                              height: MediaQuery.of(context).size.height * 0.5,
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey.withAlpha(100)),
                                  const SizedBox(height: 12),
                                  const Text('No Client Data Found'),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () => _showAddOrEditUserDialog(),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add First Client'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 100),
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = filteredUsers[index];
                              final vehicleCount = user['vehicleCount'] ?? ((user['vehicles'] as List?)?.length ?? 0);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primary.withAlpha(30),
                                    child: Text(
                                      (user['name'] ?? 'C')[0].toUpperCase(),
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ),
                                  title: Text(
                                    user['name'] ?? '-',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (user['email'] != null && user['email'].toString().isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2.0),
                                          child: Row(
                                            children: [
                                              Icon(Icons.mail_outline_rounded, size: 14, color: subtextColor),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  user['email'].toString(),
                                                  style: TextStyle(color: subtextColor, fontSize: 13),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (user['phone'] != null && user['phone'].toString().isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2.0),
                                          child: Row(
                                            children: [
                                              Icon(Icons.phone_outlined, size: 14, color: subtextColor),
                                              const SizedBox(width: 6),
                                              Text(
                                                user['phone'].toString(),
                                                style: TextStyle(color: subtextColor, fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withAlpha(20),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppColors.primary.withAlpha(60)),
                                        ),
                                        child: Text(
                                          '🚗 $vehicleCount Registered Vehicles',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
                                        tooltip: 'Edit Client',
                                        onPressed: () => _showAddOrEditUserDialog(existingUser: user),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                                        tooltip: 'Delete Client',
                                        onPressed: () => _confirmDeleteUser(user),
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
