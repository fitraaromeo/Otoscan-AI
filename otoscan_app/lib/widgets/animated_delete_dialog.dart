import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';

class AnimatedDeleteDialog extends StatefulWidget {
  final String inspectionId;
  final String nopol;
  final VoidCallback onDeletedSuccess;

  const AnimatedDeleteDialog({
    super.key,
    required this.inspectionId,
    required this.nopol,
    required this.onDeletedSuccess,
  });

  @override
  State<AnimatedDeleteDialog> createState() => _AnimatedDeleteDialogState();
}

class _AnimatedDeleteDialogState extends State<AnimatedDeleteDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  bool _isDeleting = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeInOut,
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _executeDelete() async {
    setState(() {
      _isDeleting = true;
    });

    final appState = Provider.of<AppState>(context, listen: false);
    final success = await appState.deleteInspection(widget.inspectionId);

    if (mounted) {
      if (success) {
        setState(() {
          _isDeleting = false;
          _isSuccess = true;
        });

        // Trigger unique success bounce animation
        _animController.reset();
        _animController.forward();

        // Wait for user to enjoy the unique animation before returning
        await Future.delayed(const Duration(milliseconds: 1400));

        if (mounted) {
          Navigator.of(context).pop(); // Close dialog
          widget.onDeletedSuccess(); // Return to dashboard
        }
      } else {
        setState(() {
          _isDeleting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Failed to delete inspection')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2430) : Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isDark
                  ? Colors.white.withAlpha(20)
                  : Colors.black.withAlpha(15),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 90 : 30),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isDeleting) ...[
                const SizedBox(height: 16),
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    color: AppColors.danger,
                    strokeWidth: 3.5,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Deleting Inspection Data...',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Removing from backend database & storage',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
                const SizedBox(height: 16),
              ] else if (_isSuccess) ...[
                // Unique Animated Deletion Success Badge 🎉
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withAlpha(30),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.danger, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.danger.withAlpha(100),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.delete_forever_rounded,
                      color: AppColors.danger,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Inspection Successfully Deleted',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Vehicle ${widget.nopol} data has been cleared.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
                const SizedBox(height: 10),
              ] else ...[
                // Confirmation State
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_delete_rounded,
                    color: AppColors.danger,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Delete Inspection Report?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to delete inspection for vehicle ${widget.nopol}? This action is permanent and cannot be undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: textSecondary),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textSecondary,
                            side: BorderSide(
                              color: isDark
                                  ? Colors.white.withAlpha(30)
                                  : Colors.black.withAlpha(30),
                            ),
                            shape: const StadiumBorder(),
                          ),
                          child: const Text('Cancel',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _executeDelete,
                          icon: const Icon(Icons.delete_forever_rounded,
                              size: 18),
                          label: const Text(
                            'Delete',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.danger,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: AppColors.danger.withAlpha(100),
                            shape: const StadiumBorder(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
