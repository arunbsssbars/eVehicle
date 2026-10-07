import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evehicle_logbook/core/services/electrical_load_balancer_service.dart';
import 'package:evehicle_logbook/core/widgets/electrical_load_balancer_card.dart';

void main() {
  group('Loop 100: Heavy Vehicle 24V Electrical Load Balancer Tests', () {
    const service = ElectricalLoadBalancerService();

    test('Net positive charging balance reports healthy electrical bus', () {
      const telemetry = AlternatorBatteryTelemetry(
        alternatorRatedOutputAmperes: 150.0,
        alternatorCurrentOutputAmperes: 120.0,
        systemBusVoltage: 27.6,
        batteryStateOfChargePercent: 95.0,
        loads: [
          SubsystemPowerDraw(
            system: ElectricalSubsystem.cabinHvacBlower,
            currentAmperes: 25.0,
            durationHours: 4.0,
          ),
          SubsystemPowerDraw(
            system: ElectricalSubsystem.telematicsAndGps,
            currentAmperes: 2.0,
            durationHours: 4.0,
          ),
        ],
      );

      final result = service.balanceElectricalSystem(
        vehicleId: 'TRK-24V-01',
        telemetry: telemetry,
      );

      expect(result.status, equals(ElectricalBalanceStatus.netPositiveCharging));
      expect(result.isHealthy, isTrue);
      expect(result.isBatteryDepletingUnderLoad, isFalse);
      expect(result.totalDemandAmperes, equals(27.0));
    });

    test('Severe electrical deficit exceeding alternator capacity flags critical load shedding', () {
      const telemetry = AlternatorBatteryTelemetry(
        alternatorRatedOutputAmperes: 150.0,
        alternatorCurrentOutputAmperes: 150.0,
        systemBusVoltage: 23.5, // Voltage collapse under deficit
        batteryStateOfChargePercent: 50.0,
        loads: [
          SubsystemPowerDraw(
            system: ElectricalSubsystem.liftgateHydraulicPump,
            currentAmperes: 120.0,
            durationHours: 0.2,
          ),
          SubsystemPowerDraw(
            system: ElectricalSubsystem.trailerReeferElectricStandby,
            currentAmperes: 60.0,
            durationHours: 1.0,
          ),
        ],
      );

      final result = service.balanceElectricalSystem(
        vehicleId: 'TRK-24V-01',
        telemetry: telemetry,
      );

      expect(result.status, equals(ElectricalBalanceStatus.netDeficitDischargingCritical));
      expect(result.isHealthy, isFalse);
      expect(result.isBatteryDepletingUnderLoad, isTrue);
      expect(result.powerRecommendation, contains('ELECTRICAL DEFICIT CRITICAL'));
    });

    testWidgets('AQIL: ElectricalLoadBalancerCard renders cleanly at 320px compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const telemetry = AlternatorBatteryTelemetry(
        alternatorCurrentOutputAmperes: 80.0,
        systemBusVoltage: 27.2,
        batteryStateOfChargePercent: 90.0,
        loads: [
          SubsystemPowerDraw(
            system: ElectricalSubsystem.cabinHvacBlower,
            currentAmperes: 20.0,
            durationHours: 2.0,
          ),
        ],
      );

      final result = service.balanceElectricalSystem(
        vehicleId: 'TRK-24V-01',
        telemetry: telemetry,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ElectricalLoadBalancerCard(
                result: result,
                onShedAuxiliaryLoads: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ElectricalLoadBalancerCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
