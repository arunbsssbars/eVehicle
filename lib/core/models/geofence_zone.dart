/// Type of operational geofenced zone
enum GeofenceType {
  headquarters('Headquarters', 0xFF004AC6),
  clientSite('Authorized Client Site', 0xFF16A34A),
  maintenanceDepot('Maintenance Depot', 0xFFEA580C),
  restrictedArea('Restricted / Out of Bounds', 0xFFDC2626),
  customPerimeter('Custom Operational Area', 0xFF64748B);

  final String label;
  final int colorValue;
  const GeofenceType(this.label, this.colorValue);
}

/// Coordinate point representing (latitude, longitude)
class GeoCoordinate {
  final double latitude;
  final double longitude;

  const GeoCoordinate(this.latitude, this.longitude);

  Map<String, dynamic> toJson() => {'lat': latitude, 'lng': longitude};

  factory GeoCoordinate.fromJson(Map<String, dynamic> json) => GeoCoordinate(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      );
}

/// Operational Geofence Zone model
class GeofenceZone {
  final String id;
  final String name;
  final GeofenceType type;
  final double centerLatitude;
  final double centerLongitude;
  final double radiusMeters;
  final List<GeoCoordinate> polygonVertices;
  final bool isRestricted;
  final bool isActive;
  final String? notes;

  const GeofenceZone({
    required this.id,
    required this.name,
    required this.type,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.radiusMeters,
    this.polygonVertices = const [],
    this.isRestricted = false,
    this.isActive = true,
    this.notes,
  });

  bool get isPolygon => polygonVertices.length >= 3;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'center_lat': centerLatitude,
        'center_lng': centerLongitude,
        'radius_m': radiusMeters,
        'polygon_vertices': polygonVertices.map((v) => v.toJson()).toList(),
        'is_restricted': isRestricted,
        'is_active': isActive,
        'notes': notes,
      };

  factory GeofenceZone.fromJson(Map<String, dynamic> json) => GeofenceZone(
        id: json['id'] as String,
        name: json['name'] as String,
        type: GeofenceType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => GeofenceType.headquarters,
        ),
        centerLatitude: (json['center_lat'] as num).toDouble(),
        centerLongitude: (json['center_lng'] as num).toDouble(),
        radiusMeters: (json['radius_m'] as num).toDouble(),
        polygonVertices: (json['polygon_vertices'] as List<dynamic>?)
                ?.map((e) => GeoCoordinate.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        isRestricted: json['is_restricted'] as bool? ?? false,
        isActive: json['is_active'] as bool? ?? true,
        notes: json['notes'] as String?,
      );
}

/// Result of evaluating a location or route against geofenced zones
class GeofenceEvaluationResult {
  final bool hasViolation;
  final List<String> violatedZoneNames;
  final List<String> activeZoneNames;
  final String summary;

  const GeofenceEvaluationResult({
    required this.hasViolation,
    required this.violatedZoneNames,
    required this.activeZoneNames,
    required this.summary,
  });
}
