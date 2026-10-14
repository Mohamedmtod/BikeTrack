import 'package:flutter_test/flutter_test.dart';

import 'package:biketrack_probe/main.dart';

void main() {
  testWidgets('Probe shell smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProbeApp());

    expect(find.text('BikeTrack Probe'), findsOneWidget);
    expect(find.text('1.0.0+1'), findsOneWidget);
    expect(find.text('Probe shell OK'), findsOneWidget);
  });
}
