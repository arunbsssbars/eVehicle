import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:evehicle_logbook/app/app.dart';
import 'package:evehicle_logbook/core/storage/local_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App renders splash screen initially and navigates', (WidgetTester tester) async {
    await LocalDatabase.instance.init();

    await tester.pumpWidget(
      const ProviderScope(
        child: EVehicleLogBookApp(),
      ),
    );
    // Initial frame on splash screen
    await tester.pump();
    expect(find.text('eVehicle LogBook'), findsOneWidget);

    // Advance time past the splash delay to complete all timers
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
