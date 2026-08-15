import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum ScanAngle {
  kanan,
  kiri,
  depan,
  belakang;

  String get label {
    switch (this) {
      case ScanAngle.kanan:
        return 'Right';
      case ScanAngle.kiri:
        return 'Left';
      case ScanAngle.depan:
        return 'Front';
      case ScanAngle.belakang:
        return 'Rear';
    }
  }

  String get description {
    switch (this) {
      case ScanAngle.kanan:
        return 'Scan the right side: doors, mirror, body & right wheel';
      case ScanAngle.kiri:
        return 'Scan the left side: doors, mirror, body & left wheel';
      case ScanAngle.depan:
        return 'Scan front bumper, hood, windshield & headlights';
      case ScanAngle.belakang:
        return 'Scan trunk, rear bumper & tail lights';
    }
  }

  IconData get iconData {
    switch (this) {
      case ScanAngle.kanan:
        return Icons.directions_car_rounded;
      case ScanAngle.kiri:
        return Icons.directions_car_outlined;
      case ScanAngle.depan:
        return Icons.minor_crash_rounded;
      case ScanAngle.belakang:
        return Icons.drive_eta_rounded;
    }
  }

  String get iconAsset {
    switch (this) {
      case ScanAngle.kanan:
        return 'assets/icons/side.png';
      case ScanAngle.kiri:
        return 'assets/icons/side.png';
      case ScanAngle.depan:
        return 'assets/icons/front.png';
      case ScanAngle.belakang:
        return 'assets/icons/rear.png';
    }
  }
}

enum DamageSeverity {
  ringan('Minor', 1),
  sedang('Moderate', 2),
  berat('Severe', 3);

  final String label;
  final int level;
  const DamageSeverity(this.label, this.level);
}

class DamageItem {
  final String id;
  final ScanAngle angle;
  final String type; // e.g. Scratch, Dent, Crack
  final DamageSeverity severity;
  final String description;
  final double xRatio; // 0.0 to 1.0 for bounding box center X
  final double yRatio; // 0.0 to 1.0 for bounding box center Y
  final double widthRatio; // 0.0 to 1.0 for bounding box width
  final double heightRatio; // 0.0 to 1.0 for bounding box height
  final double confidence; // e.g. 0.94
  bool isConfirmed;

  DamageItem({
    required this.id,
    required this.angle,
    required this.type,
    required this.severity,
    required this.description,
    required this.xRatio,
    required this.yRatio,
    double? widthRatio,
    double? heightRatio,
    double? confidence,
    this.isConfirmed = true,
  })  : widthRatio = widthRatio ?? 0.18,
        heightRatio = heightRatio ?? 0.14,
        confidence = confidence ?? 0.90;
}

class AngleCapture {
  final ScanAngle angle;
  bool isCaptured;
  DateTime? capturedAt;
  String? rawImageUrl;
  String? annotatedImageUrl;
  List<DamageItem> damages;

  AngleCapture({
    required this.angle,
    this.isCaptured = false,
    this.capturedAt,
    this.rawImageUrl,
    this.annotatedImageUrl,
    List<DamageItem>? damages,
  }) : damages = damages ?? [];
}

enum InspectionStatus {
  waiting('Waiting'),
  inProgress('In Progress'),
  completed('Completed'),
  failed('Failed'),
  draft('Draft');

  final String label;
  const InspectionStatus(this.label);
}

class VehicleRecord {
  final String id;
  final String merk; // e.g. Toyota, Honda, Hyundai
  final String tipe; // e.g. HR-V, Avanza, Civic RS
  final String jenis; // e.g. SUV, MPV, Sedan, Hatchback
  final String nopol; // e.g. B 1234 ABC
  final String ownerName; // e.g. Client / Owner Name
  final DateTime createdAt;
  String? statusId;
  InspectionStatus status;
  final Map<ScanAngle, AngleCapture> angleCaptures;
  final String inspectorName;

  VehicleRecord({
    required this.id,
    required this.merk,
    required this.tipe,
    required this.jenis,
    required this.nopol,
    required this.ownerName,
    required this.createdAt,
    this.statusId,
    this.status = InspectionStatus.inProgress,
    Map<ScanAngle, AngleCapture>? angleCaptures,
    this.inspectorName = 'AI Inspector',
  }) : angleCaptures = angleCaptures ?? {
          ScanAngle.kanan: AngleCapture(angle: ScanAngle.kanan),
          ScanAngle.kiri: AngleCapture(angle: ScanAngle.kiri),
          ScanAngle.depan: AngleCapture(angle: ScanAngle.depan),
          ScanAngle.belakang: AngleCapture(angle: ScanAngle.belakang),
        };

  factory VehicleRecord.createNew({
    String? customId,
    required String nopol,
    required String merk,
    required String tipe,
    String? jenis,
    String? ownerName,
    String? inspectorName,
  }) {
    return VehicleRecord(
      id: customId ?? const Uuid().v4(),
      nopol: nopol,
      merk: merk,
      tipe: tipe,
      jenis: jenis ?? 'MPV',
      ownerName: ownerName ?? 'Client',
      inspectorName: inspectorName ?? 'Inspector',
      createdAt: DateTime.now(),
    );
  }

  int get totalDamages {
    int total = 0;
    for (var capture in angleCaptures.values) {
      total += capture.damages.where((d) => d.isConfirmed).length;
    }
    return total;
  }

  int get capturedAnglesCount {
    return angleCaptures.values.where((c) => c.isCaptured).length;
  }

  AngleCapture getAngleCapture(ScanAngle angle) {
    return angleCaptures.putIfAbsent(angle, () => AngleCapture(angle: angle));
  }
}
