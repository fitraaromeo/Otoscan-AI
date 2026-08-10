import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/inspection_model.dart';
import '../services/api_service.dart';
import '../services/yolo_damage_detector.dart';

class AppState extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  bool _isDetectorReady = false;
  bool get isDetectorReady => _isDetectorReady;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  final List<VehicleRecord> _records = [];
  List<VehicleRecord> get records => List.unmodifiable(_records);

  VehicleRecord? _activeRecord;
  VehicleRecord? get activeRecord => _activeRecord;

  AppState() {
    _loadSampleRecords();
    fetchInspectionsFromApi();
    _initYoloDetector();
  }

  Future<void> fetchInspectionsFromApi() async {
    final apiInspections = await ApiService.getInspections();
    if (apiInspections.isNotEmpty) {
      final List<VehicleRecord> loaded = [];
      for (var json in apiInspections) {
        final id = json['id']?.toString() ?? '';
        final nopol = json['nopol']?.toString() ?? (json['vehicle']?['nopol']?.toString() ?? 'NOPOL');
        final merk = json['merk']?.toString() ?? (json['vehicle']?['merk']?.toString() ?? 'Car');
        final tipe = json['tipe']?.toString() ?? (json['vehicle']?['tipe']?.toString() ?? '');
        final jenis = json['jenis']?.toString() ?? (json['vehicle']?['jenis']?.toString() ?? 'Car');

        String owner = 'Client';
        if (json['vehicle'] != null && json['vehicle']['user'] != null && json['vehicle']['user']['name'] != null) {
          owner = json['vehicle']['user']['name'].toString();
        }

        String inspector = 'Inspector';
        if (json['employee'] != null && json['employee']['name'] != null) {
          inspector = json['employee']['name'].toString();
        }

        InspectionStatus status = InspectionStatus.inProgress;
        final statusStr = json['status']?.toString().toLowerCase() ?? '';
        if (statusStr == 'completed') {
          status = InspectionStatus.completed;
        } else if (statusStr == 'draft') {
          status = InspectionStatus.draft;
        }

        DateTime createdAt = DateTime.now();
        if (json['created_at'] != null) {
          try {
            createdAt = DateTime.parse(json['created_at'].toString());
          } catch (_) {}
        }

        final record = VehicleRecord(
          id: id,
          merk: merk,
          tipe: tipe,
          jenis: jenis,
          nopol: nopol,
          ownerName: owner,
          inspectorName: inspector,
          createdAt: createdAt,
          status: status,
        );

        if (json['photos'] != null && json['photos'] is List) {
          for (var p in (json['photos'] as List)) {
            String strToMatch = '';
            if (p['angleCapture'] != null) {
              strToMatch += ' ${p['angleCapture']['name'] ?? ''} ${p['angleCapture']['description'] ?? ''}';
            }
            if (p['imagePath'] != null) {
              strToMatch += ' ${p['imagePath']}';
            }
            strToMatch = strToMatch.toLowerCase();

            ScanAngle? angle;
            if (strToMatch.contains('depan') || strToMatch.contains('front')) {
              angle = ScanAngle.depan;
            } else if (strToMatch.contains('belakang') || strToMatch.contains('rear')) {
              angle = ScanAngle.belakang;
            } else if (strToMatch.contains('samping') || strToMatch.contains('side')) {
              angle = ScanAngle.samping;
            } else if (strToMatch.contains('atas') || strToMatch.contains('top')) {
              angle = ScanAngle.atas;
            }

            if (angle != null) {
              final cap = record.angleCaptures[angle]!;
              cap.isCaptured = true;
              final imgPath = p['imagePath']?.toString();
              if (imgPath != null && imgPath.isNotEmpty) {
                cap.rawImageUrl = imgPath.startsWith('http') ? imgPath : '${ApiService.serverBaseUrl}$imgPath';
              }
              if (p['damages'] != null && p['damages'] is List) {
                final List damageList = p['damages'];
                final List<DamageItem> parsedDamages = [];

                for (var d in damageList) {
                  final dId = d['id']?.toString() ?? '';
                  final dTypeObj = d['damageType'];
                  String typeName = dTypeObj?['name']?.toString() ?? (dTypeObj?['code']?.toString() ?? 'Kerusakan');
                  String description = dTypeObj?['description']?.toString() ?? 'Terdeteksi oleh AI YOLOv12';

                  DamageSeverity severity = DamageSeverity.sedang;
                  final sevStr = dTypeObj?['defaultSeverity']?.toString().toLowerCase() ?? '';
                  if (sevStr == 'berat') {
                    severity = DamageSeverity.berat;
                  } else if (sevStr == 'ringan') {
                    severity = DamageSeverity.ringan;
                  }

                  double xRatio = 0.5;
                  double yRatio = 0.5;
                  double wRatio = 0.2;
                  double hRatio = 0.2;

                  final bboxStr = d['bboxCoordinates']?.toString() ?? '';
                  if (bboxStr.isNotEmpty) {
                    try {
                      final cleaned = bboxStr.replaceAll('[', '').replaceAll(']', '').trim();
                      final parts = cleaned.split(',');
                      if (parts.length >= 4) {
                        double x1 = double.parse(parts[0].trim());
                        double y1 = double.parse(parts[1].trim());
                        double x2 = double.parse(parts[2].trim());
                        double y2 = double.parse(parts[3].trim());

                        xRatio = (((x1 + x2) / 2.0) / 800.0).clamp(0.05, 0.95);
                        yRatio = (((y1 + y2) / 2.0) / 800.0).clamp(0.05, 0.95);
                        wRatio = ((x2 - x1) / 800.0).clamp(0.05, 0.95);
                        hRatio = ((y2 - y1) / 800.0).clamp(0.05, 0.95);
                      }
                    } catch (_) {}
                  }

                  parsedDamages.add(
                    DamageItem(
                      id: dId,
                      angle: angle,
                      type: typeName,
                      severity: severity,
                      description: description,
                      xRatio: xRatio,
                      yRatio: yRatio,
                      widthRatio: wRatio,
                      heightRatio: hRatio,
                      isConfirmed: true,
                    ),
                  );

                  final annPath = d['annotatedImagePath']?.toString();
                  if (annPath != null && annPath.isNotEmpty) {
                    cap.annotatedImageUrl = annPath.startsWith('http') ? annPath : '${ApiService.serverBaseUrl}$annPath';
                  }
                }

                if (parsedDamages.isNotEmpty) {
                  cap.damages = parsedDamages;
                }
              }
            }
          }
        }

        loaded.add(record);
      }
      if (loaded.isNotEmpty) {
        _records.clear();
        _records.addAll(loaded);
        if (_activeRecord != null) {
          final updated = _records.firstWhere(
            (r) => r.id == _activeRecord!.id,
            orElse: () => _activeRecord!,
          );
          _activeRecord = updated;
        }
        notifyListeners();
      }
    }
  }

  Future<void> _initYoloDetector() async {
    await YoloDamageDetector.instance.initialize();
    _isDetectorReady = true;
    notifyListeners();
  }

  void _loadSampleRecords() {
    final now = DateTime.now();

    final record1 = VehicleRecord(
      id: 'REC-001',
      merk: 'Toyota',
      tipe: 'Fortuner VRZ',
      jenis: 'SUV',
      nopol: 'B 1888 DSK',
      ownerName: 'Budi Santoso',
      createdAt: now.subtract(const Duration(hours: 2)),
      status: InspectionStatus.completed,
    );

    // Add sample captures and damages detected by YOLO ONNX
    record1.angleCaptures[ScanAngle.depan]!.isCaptured = true;
    record1.angleCaptures[ScanAngle.depan]!.capturedAt = now.subtract(const Duration(hours: 2));
    record1.angleCaptures[ScanAngle.depan]!.damages = [
      DamageItem(
        id: 'D1',
        angle: ScanAngle.depan,
        type: 'Paint Scratch (Scratch)',
        severity: DamageSeverity.ringan,
        description: 'Detected by AI YOLO ONNX (best.onnx - 94.2% Accuracy)',
        xRatio: 0.65,
        yRatio: 0.45,
      ),
      DamageItem(
        id: 'D2',
        angle: ScanAngle.depan,
        type: 'Body Dent (Dent)',
        severity: DamageSeverity.sedang,
        description: 'Detected by AI YOLO ONNX (best.onnx - 88.5% Accuracy)',
        xRatio: 0.32,
        yRatio: 0.62,
      ),
    ];

    record1.angleCaptures[ScanAngle.samping]!.isCaptured = true;
    record1.angleCaptures[ScanAngle.samping]!.capturedAt = now.subtract(const Duration(hours: 2));
    record1.angleCaptures[ScanAngle.samping]!.damages = [
      DamageItem(
        id: 'D3',
        angle: ScanAngle.samping,
        type: 'Body Dent (Dent)',
        severity: DamageSeverity.sedang,
        description: 'Detected by AI YOLO ONNX (best.onnx - 91.8% Accuracy)',
        xRatio: 0.42,
        yRatio: 0.52,
      ),
    ];

    record1.angleCaptures[ScanAngle.belakang]!.isCaptured = true;
    record1.angleCaptures[ScanAngle.belakang]!.capturedAt = now.subtract(const Duration(hours: 2));
    record1.angleCaptures[ScanAngle.belakang]!.damages = [
      DamageItem(
        id: 'D4',
        angle: ScanAngle.belakang,
        type: 'Broken Lamp (Lamp Broken)',
        severity: DamageSeverity.berat,
        description: 'Detected by AI YOLO ONNX (best.onnx - 96.5% Accuracy)',
        xRatio: 0.76,
        yRatio: 0.38,
      ),
    ];

    record1.angleCaptures[ScanAngle.atas]!.isCaptured = true;
    record1.angleCaptures[ScanAngle.atas]!.capturedAt = now.subtract(const Duration(hours: 2));

    final record2 = VehicleRecord(
      id: 'REC-002',
      merk: 'Honda',
      tipe: 'Civic RS',
      jenis: 'Sedan',
      nopol: 'D 1414 RFS',
      ownerName: 'Siti Aminah',
      createdAt: now.subtract(const Duration(days: 1)),
      status: InspectionStatus.completed,
    );

    record2.angleCaptures[ScanAngle.depan]!.isCaptured = true;
    record2.angleCaptures[ScanAngle.samping]!.isCaptured = true;
    record2.angleCaptures[ScanAngle.belakang]!.isCaptured = true;
    record2.angleCaptures[ScanAngle.atas]!.isCaptured = true;

    _records.addAll([record1, record2]);
  }

  void setActiveRecord(VehicleRecord record) {
    _activeRecord = record;
    notifyListeners();
  }

  void addRecord(VehicleRecord record) {
    _records.insert(0, record);
    _activeRecord = record;
    notifyListeners();
  }

  void updateRecordStatus(String id, InspectionStatus status) {
    final index = _records.indexWhere((r) => r.id == id);
    if (index != -1) {
      _records[index].status = status;
      notifyListeners();
    }
  }

  void completeActiveInspection() {
    if (_activeRecord != null) {
      _activeRecord!.status = InspectionStatus.completed;
      notifyListeners();
    }
  }

  Future<void> runYoloAIScan(ScanAngle angle, {Uint8List? imageBytes, String? imagePath}) async {
    if (_activeRecord == null) return;

    final String angleNameStr = switch (angle) {
      ScanAngle.depan => 'Tampak Depan',
      ScanAngle.samping => 'Tampak Samping',
      ScanAngle.belakang => 'Tampak Belakang',
      ScanAngle.atas => 'Tampak Atas',
    };

    List<DamageItem> damageItems = [];

    // 1. Send photo to Go Backend API YOLOv12 Service
    final backendResult = await ApiService.detectDamageAI(
      inspectionId: _activeRecord!.id,
      imagePath: imagePath ?? '',
      angleName: angleNameStr,
      imageBytes: imageBytes,
    );

    if (backendResult != null && backendResult['status'] == 'success') {
      final rawPredictions = backendResult['rawPredictions'];
      if (rawPredictions != null && rawPredictions['predictions'] != null) {
        final List preds = rawPredictions['predictions'];
        for (var p in preds) {
          final box = p['box_xyxy'] as List?;
          double xRatio = 0.5;
          double yRatio = 0.5;
          if (box != null && box.length >= 4) {
            xRatio = (((box[0] as num) + (box[2] as num)) / 2.0) / 800.0;
            yRatio = (((box[1] as num) + (box[3] as num)) / 2.0) / 800.0;
          }
          final String classCode = p['class_code'] ?? 'Damage';
          final double conf = (p['confidence'] as num?)?.toDouble() ?? 0.85;

          final severity = conf > 0.85
              ? DamageSeverity.berat
              : conf > 0.6
                  ? DamageSeverity.sedang
                  : DamageSeverity.ringan;

          damageItems.add(
            DamageItem(
              id: 'AI-${DateTime.now().millisecondsSinceEpoch}',
              angle: angle,
              type: classCode.replaceAll('_', ' ').toUpperCase(),
              severity: severity,
              description: 'Detected by YOLOv12 Backend (${(conf * 100).toStringAsFixed(1)}% Confidence)',
              xRatio: xRatio.clamp(0.05, 0.95),
              yRatio: yRatio.clamp(0.05, 0.95),
            ),
          );
        }
      }
    } else {
      // 2. Fallback to Local ONNX detector if backend is offline
      final detectedList = await YoloDamageDetector.instance.detectDamagesFromImage(
        imageBytes ?? Uint8List(0),
        angle: angle,
      );
      damageItems = detectedList.map((d) => d.toDamageItem(angle)).toList();
    }

    final capture = _activeRecord!.angleCaptures[angle]!;
    capture.isCaptured = true;
    capture.capturedAt = DateTime.now();
    capture.damages = damageItems;

    if (backendResult != null && backendResult['status'] == 'success') {
      final photoObj = backendResult['photo'];
      final rawPredictions = backendResult['rawPredictions'];

      String? rawPath = photoObj?['imagePath']?.toString();
      String? annotatedPath = rawPredictions?['annotated_image_path']?.toString();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      if (rawPath != null && rawPath.isNotEmpty) {
        final fullUrl = rawPath.startsWith('http') ? rawPath : '${ApiService.serverBaseUrl}$rawPath';
        capture.rawImageUrl = '$fullUrl?t=$timestamp';
      }
      if (annotatedPath != null && annotatedPath.isNotEmpty) {
        final fullUrl = annotatedPath.startsWith('http') ? annotatedPath : '${ApiService.serverBaseUrl}$annotatedPath';
        capture.annotatedImageUrl = '$fullUrl?t=$timestamp';
      }
    }

    if (_activeRecord!.capturedAnglesCount == 4) {
      _activeRecord!.status = InspectionStatus.completed;
    } else {
      _activeRecord!.status = InspectionStatus.inProgress;
    }

    final recIndex = _records.indexWhere((r) => r.id == _activeRecord!.id);
    if (recIndex != -1) {
      _records[recIndex] = _activeRecord!;
    }

    notifyListeners();
  }

  void _syncActiveRecordToRecords() {
    if (_activeRecord == null) return;
    final index = _records.indexWhere((r) => r.id == _activeRecord!.id);
    if (index != -1) {
      _records[index] = _activeRecord!;
    }
  }

  void addDamageToAngle(ScanAngle angle, DamageItem item) {
    if (_activeRecord == null) return;
    final capture = _activeRecord!.angleCaptures[angle]!;
    capture.isCaptured = true;
    capture.damages.add(item);
    _syncActiveRecordToRecords();
    notifyListeners();
  }

  void addManualDamage(ScanAngle angle, DamageItem item) {
    addDamageToAngle(angle, item);
  }

  void toggleDamageConfirmation(ScanAngle angle, String damageId, bool confirmed) {
    if (_activeRecord == null) return;
    final capture = _activeRecord!.angleCaptures[angle]!;
    final index = capture.damages.indexWhere((d) => d.id == damageId);
    if (index != -1) {
      capture.damages[index].isConfirmed = confirmed;
      _syncActiveRecordToRecords();
      notifyListeners();
    }
  }

  void removeDamage(ScanAngle angle, String damageId) {
    if (_activeRecord == null) return;
    final capture = _activeRecord!.angleCaptures[angle]!;
    capture.damages.removeWhere((d) => d.id == damageId);
    _syncActiveRecordToRecords();
    notifyListeners();
  }

  Future<bool> deleteInspection(String id) async {
    final success = await ApiService.deleteInspection(id);
    _records.removeWhere((r) => r.id == id);
    if (_activeRecord?.id == id) {
      _activeRecord = null;
    }
    notifyListeners();
    return success;
  }
}
