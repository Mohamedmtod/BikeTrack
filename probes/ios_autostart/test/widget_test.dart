import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:biketrack_probe/main.dart';

void main() {
  const channel = MethodChannel('biketrack/probe');

  testWidgets('shows native probe status and log tail', (
    WidgetTester tester,
  ) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      MethodCall call,
    ) async {
      switch (call.method) {
        case 'status':
          return {
            'recording': false,
            'rideId': '',
            'locationAuthorization': 'always',
            'notificationAuthorization': 'authorized',
          };
        case 'readLogTail':
          return ['{"event":"launch"}'];
        default:
          return null;
      }
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );

    await tester.pumpWidget(const ProbeApp());
    await tester.pumpAndSettle();

    expect(find.text('BikeTrack Probe'), findsOneWidget);
    expect(find.text('Native status'), findsOneWidget);
    expect(find.text('Log tail (30)'), findsOneWidget);
    expect(find.textContaining('locationAuthorization'), findsOneWidget);
    expect(find.text('{"event":"launch"}'), findsOneWidget);
    expect(find.text('Start ride'), findsOneWidget);
  });
}
