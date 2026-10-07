import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/organization.dart';
import '../models/tenant_settings.dart';
import '../storage/local_database.dart';

/// HTTP Client handling communication with the SaaS Cloud REST API with automatic tenant context injection.
class SaasApiClient {
  final String baseUrl;
  final http.Client _client;

  SaasApiClient({
    this.baseUrl = 'http://localhost:3000/api/v1',
    http.Client? client,
  }) : _client = client ?? http.Client();

  Map<String, String> _buildHeaders({String? tenantId, String? authToken}) {
    final activeTenantId = tenantId ??
        LocalDatabase.instance.currentUser?.organizationId ??
        'ORG-PWD-01';

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'x-tenant-id': activeTenantId,
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };
  }

  /// Fetch active workspace profile and settings from SaaS Cloud
  Future<Map<String, dynamic>?> fetchCurrentTenant() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/tenants/current'),
        headers: _buildHeaders(),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (_) {
      // Offline fallback: load from LocalDatabase
      final org = LocalDatabase.instance.organizations.firstOrNull;
      return org?.toJson();
    }
  }

  /// Update tenant white-label branding and regional currency/distance preferences
  Future<bool> updateTenantSettings(TenantSettings settings) async {
    try {
      final response = await _client.patch(
        Uri.parse('$baseUrl/tenants/settings'),
        headers: _buildHeaders(),
        body: jsonEncode(settings.toJson()),
      );

      return response.statusCode == 200;
    } catch (_) {
      // Local fallback
      final org = LocalDatabase.instance.organizations.firstOrNull;
      if (org != null) {
        final updated = org.copyWith(settings: settings);
        await LocalDatabase.instance.updateOrganization(updated);
        return true;
      }
      return false;
    }
  }

  /// Fetch subscription resource usage vs plan limits
  Future<Map<String, dynamic>?> fetchSubscriptionUsage() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/subscriptions/usage'),
        headers: _buildHeaders(),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (_) {
      // Offline calculation fallback
      final org = LocalDatabase.instance.organizations.firstOrNull;
      final vehicleCount = LocalDatabase.instance.vehicles.length;
      final journeyCount = LocalDatabase.instance.journeys.length;

      return {
        'tenantId': org?.id ?? 'ORG-PWD-01',
        'tenantName': org?.name ?? 'Workspace',
        'currentPlan': {'code': org?.subscriptionTier.code ?? 'FREE'},
        'usage': {
          'vehiclesUsed': vehicleCount,
          'vehiclesAllowed': org?.subscriptionTier.maxVehicles ?? 2,
          'journeysUsed': journeyCount,
          'journeysAllowed': org?.subscriptionTier.maxMonthlyJourneys ?? 50,
        },
      };
    }
  }

  /// Request subscription upgrade
  Future<bool> upgradeSubscription(String planCode) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/subscriptions/upgrade'),
        headers: _buildHeaders(),
        body: jsonEncode({'plan': planCode}),
      );

      return response.statusCode == 200;
    } catch (_) {
      // Local fallback
      final org = LocalDatabase.instance.organizations.firstOrNull;
      if (org != null) {
        final newTier = SubscriptionTier.fromCode(planCode);
        final updated = org.copyWith(subscriptionTier: newTier);
        await LocalDatabase.instance.updateOrganization(updated);
        return true;
      }
      return false;
    }
  }
}
