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
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
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
    fetchInspectionsFromApi();
    _initYoloDetector();
  }

  Future<void> fetchInspectionsFromApi() async {
    final apiInspections = await ApiService.getInspections();
    final List<VehicleRecord> loaded = [];

    for (var json in apiInspections) {
      final id = json['id']?.toString() ?? '';
      final vehicle = json['vehicle'] as Map<String, dynamic>?;

      String nopol = (vehicle?['nopol'] ?? json['nopol'] ?? '')
          .toString()
          .trim();
      String merk = (vehicle?['merk'] ?? json['merk'] ?? '').toString().trim();
      String tipe = (vehicle?['tipe'] ?? json['tipe'] ?? '').toString().trim();
      String jenis = (vehicle?['jenis'] ?? json['jenis'] ?? 'Sedan')
          .toString()
          .trim();

      // Skip incomplete/invalid inspection records with no vehicle or nopol
      if (nopol.isEmpty) {
        continue;
      }

      String owner = '-';
      if (vehicle != null &&
          vehicle['user'] != null &&
          vehicle['user']['name'] != null) {
        owner = vehicle['user']['name'].toString();
      } else if (json['user'] != null && json['user']['name'] != null) {
        owner = json['user']['name'].toString();
      }

      String inspector = 'Inspector';
      if (json['employee'] != null && json['employee']['name'] != null) {
        inspector = json['employee']['name'].toString();
      }

      String? stId = json['statusId']?.toString();
      if ((stId == null || stId.isEmpty) && json['inspectionStatus'] != null && json['inspectionStatus']['id'] != null) {
        stId = json['inspectionStatus']['id'].toString();
      }

      InspectionStatus status = InspectionStatus.waiting;
      String rawCode = '';
      if (json['inspectionStatus'] != null && json['inspectionStatus']['code'] != null) {
        rawCode = json['inspectionStatus']['code'].toString().toLowerCase();
      } else if (json['inspectionStatus'] != null && json['inspectionStatus']['name'] != null) {
        rawCode = json['inspectionStatus']['name'].toString().toLowerCase();
      }

      if (rawCode.contains('wait') || rawCode.contains('antrean') || rawCode.contains('menunggu')) {
        status = InspectionStatus.waiting;
      } else if (rawCode.contains('complet') || rawCode.contains('selesai')) {
        status = InspectionStatus.completed;
      } else if (rawCode.contains('fail') || rawCode.contains('gagal')) {
        status = InspectionStatus.failed;
      } else if (rawCode.contains('draft')) {
        status = InspectionStatus.draft;
      } else if (rawCode.contains('progress')) {
        status = InspectionStatus.inProgress;
      } else {
        status = InspectionStatus.waiting;
      }

      DateTime createdAt = DateTime.now();
      final rawCreated = json['createdAt'] ?? json['created_at'];
      if (rawCreated != null) {
        try {
          createdAt = DateTime.parse(rawCreated.toString()).toLocal();
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
        statusId: stId,
        status: status,
      );

      if (json['photos'] != null && json['photos'] is List) {
        for (var p in (json['photos'] as List)) {
          String strToMatch = '';
          if (p['angleCapture'] != null) {
            strToMatch +=
                ' ${p['angleCapture']['name'] ?? ''} ${p['angleCapture']['description'] ?? ''}';
          }
          if (p['imagePath'] != null) {
            strToMatch += ' ${p['imagePath']}';
          }
          strToMatch = strToMatch.toLowerCase();

          ScanAngle? angle;
          if (strToMatch.contains('kanan') || strToMatch.contains('right')) {
            angle = ScanAngle.kanan;
          } else if (strToMatch.contains('kiri') ||
              strToMatch.contains('left')) {
            angle = ScanAngle.kiri;
          } else if (strToMatch.contains('depan') ||
              strToMatch.contains('front')) {
            angle = ScanAngle.depan;
          } else if (strToMatch.contains('belakang') ||
              strToMatch.contains('rear')) {
            angle = ScanAngle.belakang;
          } else if (strToMatch.contains('samping') ||
              strToMatch.contains('side')) {
            angle = ScanAngle.kanan;
          } else if (strToMatch.contains('atas') ||
              strToMatch.contains('top')) {
            angle = ScanAngle.kiri;
          }

          if (angle != null) {
            final cap = record.getAngleCapture(angle);
            cap.isCaptured = true;
            final imgPath = p['imagePath']?.toString();
            if (imgPath != null && imgPath.isNotEmpty) {
              cap.rawImageUrl = imgPath.startsWith('http')
                  ? imgPath
                  : '${ApiService.serverBaseUrl}$imgPath';
            }
            if (p['damages'] != null && p['damages'] is List) {
              final List damageList = p['damages'];
              final List<DamageItem> parsedDamages = [];

              for (var d in damageList) {
                final dId = d['id']?.toString() ?? '';
                final dTypeObj = d['damageType'];
                String typeName =
                    dTypeObj?['name']?.toString() ??
                    (dTypeObj?['code']?.toString() ?? 'Kerusakan');
                String description =
                    dTypeObj?['description']?.toString() ??
                    'Terdeteksi oleh AI YOLOv12';

                DamageSeverity severity = DamageSeverity.sedang;
                final sevStr =
                    dTypeObj?['defaultSeverity']?.toString().toLowerCase() ??
                    '';
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
                    final cleaned = bboxStr
                        .replaceAll('[', '')
                        .replaceAll(']', '')
                        .trim();
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
                  cap.annotatedImageUrl = annPath.startsWith('http')
                      ? annPath
                      : '${ApiService.serverBaseUrl}$annPath';
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

    _records.clear();
    _records.addAll(loaded);
    if (_activeRecord != null) {
      final index = _records.indexWhere((r) => r.id == _activeRecord!.id);
      if (index != -1) {
        _activeRecord = _records[index];
      }
    }
    notifyListeners();
  }

  Future<void> _initYoloDetector() async {
    await YoloDamageDetector.instance.initialize();
    _isDetectorReady = true;
    notifyListeners();
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

  Future<void> runYoloAIScan(
    ScanAngle angle, {
    Uint8List? imageBytes,
    String? imagePath,
  }) async {
    if (_activeRecord == null) return;

    final String angleNameStr = switch (angle) {
      ScanAngle.kanan => 'Tampak Kanan',
      ScanAngle.kiri => 'Tampak Kiri',
      ScanAngle.depan => 'Tampak Depan',
      ScanAngle.belakang => 'Tampak Belakang',
    };

    List<DamageItem> damageItems = [];

    final backendResult = await ApiService.detectDamageAI(
      inspectionId: _activeRecord!.id,
      imagePath: imagePath ?? '',
      angleName: angleNameStr,
      imageBytes: imageBytes,
    );

    if (backendResult != null &&
        backendResult['status'] == 'success' &&
        backendResult['rawPredictions'] != null) {
      final rawPreds = backendResult['rawPredictions'];
      final List detections = rawPreds['detections'] ?? [];

      for (var det in detections) {
        final labelStr = det['label']?.toString() ?? 'damage';
        final conf = (det['confidence'] as num?)?.toDouble() ?? 0.85;

        double x1 = 100, y1 = 100, x2 = 300, y2 = 300;
        final bbox = det['bbox'];
        if (bbox != null && bbox is List && bbox.length >= 4) {
          x1 = (bbox[0] as num).toDouble();
          y1 = (bbox[1] as num).toDouble();
          x2 = (bbox[2] as num).toDouble();
          y2 = (bbox[3] as num).toDouble();
        }

        DamageSeverity sev = DamageSeverity.sedang;
        if (labelStr.contains('scratch')) {
          sev = DamageSeverity.ringan;
        } else if (labelStr.contains('broken') ||
            labelStr.contains('shatter')) {
          sev = DamageSeverity.berat;
        }

        final detected = DetectedDamage(
          label: labelStr,
          labelId: labelStr,
          confidence: conf,
          severity: sev,
          xRatio: (((x1 + x2) / 2.0) / 800.0).clamp(0.05, 0.95),
          yRatio: (((y1 + y2) / 2.0) / 800.0).clamp(0.05, 0.95),
          widthRatio: ((x2 - x1) / 800.0).clamp(0.05, 0.95),
          heightRatio: ((y2 - y1) / 800.0).clamp(0.05, 0.95),
        );
        damageItems.add(detected.toDamageItem(angle));
      }
    }

    if (damageItems.isEmpty) {
      final detectedList = await YoloDamageDetector.instance
          .detectDamagesFromImage(imageBytes ?? Uint8List(0), angle: angle);
      damageItems = detectedList.map((d) => d.toDamageItem(angle)).toList();
    }

    final capture = _activeRecord!.getAngleCapture(angle);
    capture.isCaptured = true;
    capture.capturedAt = DateTime.now();
    capture.damages = damageItems;

    if (backendResult != null && backendResult['status'] == 'success') {
      final photoObj = backendResult['photo'];
      final rawPredictions = backendResult['rawPredictions'];

      String? rawPath = photoObj?['imagePath']?.toString();
      String? annotatedPath = rawPredictions?['annotated_image_path']
          ?.toString();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      if (rawPath != null && rawPath.isNotEmpty) {
        final fullUrl = rawPath.startsWith('http')
            ? rawPath
            : '${ApiService.serverBaseUrl}$rawPath';
        capture.rawImageUrl = '$fullUrl?t=$timestamp';
      }
      if (annotatedPath != null && annotatedPath.isNotEmpty) {
        final fullUrl = annotatedPath.startsWith('http')
            ? annotatedPath
            : '${ApiService.serverBaseUrl}$annotatedPath';
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
    final capture = _activeRecord!.getAngleCapture(angle);
    capture.isCaptured = true;
    capture.damages.add(item);
    _syncActiveRecordToRecords();
    notifyListeners();
  }

  void addManualDamage(ScanAngle angle, DamageItem item) {
    addDamageToAngle(angle, item);
  }

  void toggleDamageConfirmation(
    ScanAngle angle,
    String damageId,
    bool confirmed,
  ) {
    if (_activeRecord == null) return;
    final capture = _activeRecord!.getAngleCapture(angle);
    final index = capture.damages.indexWhere((d) => d.id == damageId);
    if (index != -1) {
      capture.damages[index].isConfirmed = confirmed;
      _syncActiveRecordToRecords();
      notifyListeners();
    }
  }

  void removeDamage(ScanAngle angle, String damageId) {
    if (_activeRecord == null) return;
    final capture = _activeRecord!.getAngleCapture(angle);
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
