/// Workspace settings and white-label preferences for a SaaS tenant organization.
class TenantSettings {
  final String currencyCode; // 'INR', 'USD', 'EUR', 'GBP'
  final String currencySymbol; // '₹', '$', '€', '£'
  final String distanceUnit; // 'km' or 'mi'
  final int brandPrimaryColorValue; // e.g. 0xFF004AC6
  final String? brandLogoUrl;
  final String? taxId;
  final bool enableDriverSelfApproval;
  final bool enforceGeofencedTrips;

  const TenantSettings({
    this.currencyCode = 'INR',
    this.currencySymbol = '₹',
    this.distanceUnit = 'km',
    this.brandPrimaryColorValue = 0xFF004AC6,
    this.brandLogoUrl,
    this.taxId,
    this.enableDriverSelfApproval = false,
    this.enforceGeofencedTrips = false,
  });

  bool get isMetric => distanceUnit.toLowerCase() == 'km';
  bool get isImperial => distanceUnit.toLowerCase() == 'mi';

  TenantSettings copyWith({
    String? currencyCode,
    String? currencySymbol,
    String? distanceUnit,
    int? brandPrimaryColorValue,
    String? brandLogoUrl,
    String? taxId,
    bool? enableDriverSelfApproval,
    bool? enforceGeofencedTrips,
  }) {
    return TenantSettings(
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      brandPrimaryColorValue:
          brandPrimaryColorValue ?? this.brandPrimaryColorValue,
      brandLogoUrl: brandLogoUrl ?? this.brandLogoUrl,
      taxId: taxId ?? this.taxId,
      enableDriverSelfApproval:
          enableDriverSelfApproval ?? this.enableDriverSelfApproval,
      enforceGeofencedTrips:
          enforceGeofencedTrips ?? this.enforceGeofencedTrips,
    );
  }

  Map<String, dynamic> toJson() => {
        'currency_code': currencyCode,
        'currency_symbol': currencySymbol,
        'distance_unit': distanceUnit,
        'brand_primary_color_value': brandPrimaryColorValue,
        'brand_logo_url': brandLogoUrl,
        'tax_id': taxId,
        'enable_driver_self_approval': enableDriverSelfApproval,
        'enforce_geofenced_trips': enforceGeofencedTrips,
      };

  factory TenantSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const TenantSettings();
    return TenantSettings(
      currencyCode: json['currency_code'] as String? ?? 'INR',
      currencySymbol: json['currency_symbol'] as String? ?? '₹',
      distanceUnit: json['distance_unit'] as String? ?? 'km',
      brandPrimaryColorValue:
          json['brand_primary_color_value'] as int? ?? 0xFF004AC6,
      brandLogoUrl: json['brand_logo_url'] as String?,
      taxId: json['tax_id'] as String?,
      enableDriverSelfApproval:
          json['enable_driver_self_approval'] as bool? ?? false,
      enforceGeofencedTrips: json['enforce_geofenced_trips'] as bool? ?? false,
    );
  }
}
