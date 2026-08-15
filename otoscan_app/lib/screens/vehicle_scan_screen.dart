import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/inspection_model.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/vehicle_painter.dart';
import 'damage_confirmation_screen.dart';

class VehicleScanScreen extends StatefulWidget {
  final VehicleRecord record;
  final String? initialScanMode; // 'camera' or 'gallery'

  const VehicleScanScreen({
    super.key,
    required this.record,
    this.initialScanMode,
  });

  @override
  State<VehicleScanScreen> createState() => _VehicleScanScreenState();
}

class _VehicleScanScreenState extends State<VehicleScanScreen> with SingleTickerProviderStateMixin {
  ScanAngle _currentAngle = ScanAngle.kanan;
  bool _isScanning = false;
  late AnimationController _scanAnimationController;
  final ImagePicker _picker = ImagePicker();

  // Map to store captured photo files / bytes for each angle cross-platform
  final Map<ScanAngle, File?> _capturedPhotos = {
    ScanAngle.kanan: null,
    ScanAngle.kiri: null,
    ScanAngle.depan: null,
    ScanAngle.belakang: null,
  };

  final Map<ScanAngle, Uint8List?> _capturedBytes = {
    ScanAngle.kanan: null,
    ScanAngle.kiri: null,
    ScanAngle.depan: null,
    ScanAngle.belakang: null,
  };

  @override
  void initState() {
    super.initState();
    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    super.dispose();
  }

  /// Run AI YOLO Scan (via Backend API or local fallback)
  void _runAIScan({Uint8List? customPhotoBytes, String? filePath}) async {
    setState(() {
      _isScanning = true;
    });
    _scanAnimationController.forward(from: 0.0);

    final appState = Provider.of<AppState>(context, listen: false);
    await appState.runYoloAIScan(_currentAngle, imageBytes: customPhotoBytes, imagePath: filePath);

    if (!mounted) return;
    setState(() {
      _isScanning = false;
    });

    // Show damage confirmation sheet
    _openDamageConfirmation();
  }

  /// Capture Photo using Device Camera
  Future<void> _takeCameraPhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        maxWidth: 1280,
        maxHeight: 1280,
      );

      if (photo != null) {
        final photoBytes = await photo.readAsBytes();
        if (!mounted) return;
        final appState = Provider.of<AppState>(context, listen: false);
        final capture = appState.activeRecord?.angleCaptures[_currentAngle];
        if (capture != null) {
          capture.annotatedImageUrl = null;
          capture.rawImageUrl = null;
          capture.damages.clear();
        }
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();

        setState(() {
          _capturedBytes[_currentAngle] = photoBytes;
          if (!kIsWeb) {
            _capturedPhotos[_currentAngle] = File(photo.path);
          }
        });
        _runAIScan(customPhotoBytes: photoBytes, filePath: photo.path);
      }
    } catch (e) {
      if (mounted) {
        _pickGalleryPhoto();
      }
    }
  }

  /// Pick Photo from Device Gallery
  Future<void> _pickGalleryPhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 1280,
        maxHeight: 1280,
      );

      if (photo != null) {
        final photoBytes = await photo.readAsBytes();
        if (!mounted) return;
        final appState = Provider.of<AppState>(context, listen: false);
        final capture = appState.activeRecord?.angleCaptures[_currentAngle];
        if (capture != null) {
          capture.annotatedImageUrl = null;
          capture.rawImageUrl = null;
          capture.damages.clear();
        }
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();

        setState(() {
          _capturedBytes[_currentAngle] = photoBytes;
          if (!kIsWeb) {
            _capturedPhotos[_currentAngle] = File(photo.path);
          }
        });
        _runAIScan(customPhotoBytes: photoBytes, filePath: photo.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gallery access failed: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _openDamageConfirmation() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DamageConfirmationModal(
        angle: _currentAngle,
      ),
    );
  }

  void _onTapCanvasAddDamage(double xRatio, double yRatio) {
    showDialog(
      context: context,
      builder: (context) {
        final typeController = TextEditingController(text: 'Body Dent (dent)');
        DamageSeverity selectedSeverity = DamageSeverity.sedang;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.add_location_alt_rounded, color: AppColors.neonCyan),
              SizedBox(width: 8),
              Text('Add Manual Pin', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: typeController,
                decoration: const InputDecoration(
                  labelText: 'Damage Type / YOLO Label',
                  hintText: 'e.g. dent, scratch, crack, lamp broken',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setStateDialog) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Severity Level:', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      SegmentedButton<DamageSeverity>(
                        segments: DamageSeverity.values.map((s) {
                          return ButtonSegment(
                            value: s,
                            label: Text(s.label),
                          );
                        }).toList(),
                        selected: {selectedSeverity},
                        onSelectionChanged: (set) {
                          setStateDialog(() {
                            selectedSeverity = set.first;
                          });
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final appState = Provider.of<AppState>(context, listen: false);
                final manualItem = DamageItem(
                  id: 'M_${DateTime.now().millisecondsSinceEpoch}',
                  angle: _currentAngle,
                  type: typeController.text.trim().isEmpty ? 'Body Dent (Dent)' : typeController.text.trim(),
                  severity: selectedSeverity,
                  description: 'Manually pinned by technician',
                  xRatio: xRatio,
                  yRatio: yRatio,
                  widthRatio: 0.16,
                  heightRatio: 0.12,
                );
                appState.addManualDamage(_currentAngle, manualItem);
                Navigator.pop(context);
              },
              child: const Text('Add Pin'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;

    return Consumer<AppState>(
      builder: (context, appState, child) {
        final record = appState.activeRecord ?? widget.record;
        final currentCapture = record.getAngleCapture(_currentAngle);
        final currentPhotoFile = _capturedPhotos[_currentAngle];
        final bool hasPhoto = (currentCapture.annotatedImageUrl != null && currentCapture.annotatedImageUrl!.isNotEmpty) ||
            (currentCapture.rawImageUrl != null && currentCapture.rawImageUrl!.isNotEmpty) ||
            _capturedBytes[_currentAngle] != null ||
            (currentPhotoFile != null && currentPhotoFile.path.isNotEmpty);

        int capturedCount = record.capturedAnglesCount;

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          appBar: AppBar(
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.nopol,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                Text(
                  '${record.merk} ${record.tipe} (${record.jenis})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.neonCyan : AppColors.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            actions: [
              if (capturedCount == 4)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      appState.completeActiveInspection();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text('Complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              // Top 4 Angle Selection Bar
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                color: isDark ? AppColors.darkSurface : Colors.white,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: ScanAngle.values.map((angle) {
                      final isSelected = angle == _currentAngle;
                      final angleCap = record.getAngleCapture(angle);
                      final isCap = angleCap.isCaptured;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentAngle = angle;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark ? AppColors.neonCyan : AppColors.lightPrimary)
                                  : (isDark ? Colors.white.withAlpha(12) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: isSelected
                                    ? (isDark ? AppColors.neonCyan : AppColors.lightPrimary)
                                    : (isCap ? AppColors.success : Colors.white.withAlpha(20)),
                                width: 1.5,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: (isDark ? AppColors.neonCyan : AppColors.lightPrimary).withAlpha(80),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [],
                            ),
                             child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  angle.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? (isDark ? Colors.black : Colors.white)
                                        : (isDark ? Colors.white70 : AppColors.lightTextSecondary),
                                  ),
                                ),
                                if (isCap) ...[
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 14,
                                    color: isSelected ? Colors.black : AppColors.success,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Main Inspection Canvas (Image Photo / Painter + YOLO Bounding Box)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      color: isDark ? const Color(0xFF111622) : const Color(0xFFE2E8F0),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Base Photo or Wireframe Painter
                          if (_isScanning && _capturedBytes[_currentAngle] != null)
                            Image.memory(
                              _capturedBytes[_currentAngle]!,
                              key: ValueKey('scanning_${_capturedBytes[_currentAngle]!.hashCode}'),
                              fit: BoxFit.cover,
                            )
                          else if (currentCapture.annotatedImageUrl != null && currentCapture.annotatedImageUrl!.isNotEmpty)
                            Image.network(
                              currentCapture.annotatedImageUrl!,
                              key: ValueKey(currentCapture.annotatedImageUrl!),
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => _capturedBytes[_currentAngle] != null
                                  ? Image.memory(_capturedBytes[_currentAngle]!, fit: BoxFit.cover)
                                  : VehiclePainterWidget(angle: _currentAngle, damages: currentCapture.damages),
                            )
                          else if (currentCapture.rawImageUrl != null && currentCapture.rawImageUrl!.isNotEmpty)
                            Image.network(
                              currentCapture.rawImageUrl!,
                              key: ValueKey(currentCapture.rawImageUrl!),
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => _capturedBytes[_currentAngle] != null
                                  ? Image.memory(_capturedBytes[_currentAngle]!, fit: BoxFit.cover)
                                  : VehiclePainterWidget(angle: _currentAngle, damages: currentCapture.damages),
                            )
                          else if (_capturedBytes[_currentAngle] != null)
                            Image.memory(
                              _capturedBytes[_currentAngle]!,
                              key: ValueKey('local_${_capturedBytes[_currentAngle]!.hashCode}'),
                              fit: BoxFit.cover,
                            )
                          else if (!kIsWeb && currentPhotoFile != null && currentPhotoFile.path.isNotEmpty)
                            Image.file(
                              currentPhotoFile,
                              key: ValueKey(currentPhotoFile.path),
                              fit: BoxFit.cover,
                            )
                          else
                            VehiclePainterWidget(
                              angle: _currentAngle,
                              damages: currentCapture.damages,
                            ),

                          // Bounding Box Overlay for Detections (Only draw if no backend annotated image)
                          if ((currentCapture.annotatedImageUrl == null || currentCapture.annotatedImageUrl!.isEmpty) && currentCapture.damages.isNotEmpty)
                            Positioned.fill(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final cw = constraints.maxWidth;
                                  final ch = constraints.maxHeight;

                                  return Stack(
                                    children: [
                                      ...currentCapture.damages.map((damage) {
                                        final boxW = damage.widthRatio * cw;
                                        final boxH = damage.heightRatio * ch;
                                        final boxX = (damage.xRatio * cw) - (boxW / 2);
                                        final boxY = (damage.yRatio * ch) - (boxH / 2);

                                        Color boxColor = AppColors.neonPink;
                                        if (damage.severity == DamageSeverity.berat) {
                                          boxColor = AppColors.danger;
                                        } else if (damage.severity == DamageSeverity.ringan) {
                                          boxColor = AppColors.neonCyan;
                                        }

                                        return Positioned(
                                          left: boxX.clamp(0.0, cw - boxW),
                                          top: boxY.clamp(0.0, ch - boxH),
                                          width: boxW.clamp(30.0, cw),
                                          height: boxH.clamp(20.0, ch),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: boxColor.withAlpha(45),
                                              border: Border.all(color: boxColor, width: 2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Stack(
                                              children: [
                                                Positioned(
                                                  top: 2,
                                                  left: 4,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black.withAlpha(200),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      '${damage.type} ${(damage.confidence * 100).toInt()}%',
                                                      style: TextStyle(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.bold,
                                                        color: boxColor,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  );
                                },
                              ),
                            ),

                          // Central Friendly Glass Card when No Photo Uploaded yet
                          if (!hasPhoto)
                            Center(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 28),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                decoration: BoxDecoration(
                                  color: (isDark ? Colors.black : Colors.white).withAlpha(175),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: AppColors.neonCyan.withAlpha(70)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(50),
                                      blurRadius: 16,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.neonCyan.withAlpha(30),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.add_a_photo_rounded, color: AppColors.neonCyan, size: 22),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'No Photo for ${_currentAngle.label} Side',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Use Real-Time Camera or Upload Photo for automatic YOLO AI damage analysis.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Results Count Tag
                          if (currentCapture.isCaptured)
                            Positioned(
                              top: 14,
                              right: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: currentCapture.damages.isNotEmpty
                                      ? AppColors.neonPink.withAlpha(217)
                                      : AppColors.neonGreen.withAlpha(217),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'YOLO: ${currentCapture.damages.length} Damages',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                          // Scan Animation Banner Overlay
                          if (_isScanning)
                            Positioned.fill(
                              child: Container(
                                color: Colors.black.withAlpha(128),
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                    decoration: BoxDecoration(
                                      color: AppColors.darkSurface,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppColors.neonCyan),
                                    ),
                                    child: const Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 32,
                                          height: 32,
                                          child: CircularProgressIndicator(
                                            color: AppColors.neonCyan,
                                            strokeWidth: 3,
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          'ONNX YOLO INFERENCE ON PHOTO...',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.neonCyan,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Detecting dent, scratch, crack, glass, & lamp',
                                          style: TextStyle(fontSize: 10, color: AppColors.darkTextSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom Control Panel with Real Camera / Gallery Action Buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Scan Progress: $capturedCount / 4 Sides',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        if (currentCapture.isCaptured)
                          TextButton.icon(
                            onPressed: _openDamageConfirmation,
                            icon: const Icon(Icons.list_alt_rounded, size: 16),
                            label: const Text('Review YOLO Findings', style: TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 2 Choice Action Buttons: Real-Time Camera & Upload Photo Gallery
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: _isScanning ? null : _takeCameraPhoto,
                              icon: const Icon(Icons.camera_alt_rounded, size: 18),
                              label: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Real-Time Camera',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? AppColors.neonCyan : AppColors.lightPrimary,
                                foregroundColor: isDark ? Colors.black : Colors.white,
                                elevation: 4,
                                shadowColor: (isDark ? AppColors.neonCyan : AppColors.lightPrimary).withAlpha(100),
                                shape: const StadiumBorder(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: _isScanning ? null : _pickGalleryPhoto,
                              icon: const Icon(Icons.photo_library_rounded, size: 18),
                              label: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Upload Photo',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isDark ? AppColors.neonPink : AppColors.lightPrimary,
                                side: BorderSide(
                                  color: isDark ? AppColors.neonPink : AppColors.lightPrimary,
                                  width: 1.5,
                                ),
                                shape: const StadiumBorder(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Animated Coming Soon Warning Dialog ──────────────────────────────────────
class _CameraComingSoonDialog extends StatefulWidget {
  final VoidCallback onOpenGallery;
  const _CameraComingSoonDialog({required this.onOpenGallery});

  @override
  State<_CameraComingSoonDialog> createState() => _CameraComingSoonDialogState();
}

class _CameraComingSoonDialogState extends State<_CameraComingSoonDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 100 : 30),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Pulsing Icon Badge
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.warning.withAlpha(30),
                  border: Border.all(
                    color: AppColors.warning.withAlpha(100),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.warning.withAlpha(60),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_enhance_rounded,
                  color: AppColors.warning,
                  size: 34,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tag Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'FITUR DALAM PENGEMBANGAN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: AppColors.warning,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              'Pemindaian Kamera Segera Hadir',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 10),

            // Subtitle / Description
            Text(
              'Modul kamera real-time sedang dalam tahap optimalisasi akurasi AI YOLOv12. Untuk hasil pemindaian terbaik saat ini, silakan gunakan foto dari galeri.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Tutup',
                      style: TextStyle(
                        color: textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onOpenGallery();
                    },
                    icon: const Icon(Icons.photo_library_rounded, size: 16),
                    label: const Text('Buka Galeri'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
