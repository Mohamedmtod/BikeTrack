import 'package:biketrack/app/raw_event_writer.dart';
import 'package:biketrack/data/database/app_database.dart';
import 'package:biketrack/data/events/event_record.dart';
import 'package:biketrack/domain/shared/event_source.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'recorder_test_fakes.dart';

void main() {
  late AppDatabase database;
  late FakeEventRepository repository;
  late RawEventWriter writer;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = FakeEventRepository(database);
    writer = RawEventWriter(repository);
  });
  tearDown(() => database.close());

  test(
    'serializes observed manual and callback append arrival order',
    () async {
      final writes = <String>[];
      repository.onAppend = (event) async {
        writes.add(event.type);
        return FakeEventRepository(database).append(event);
      };

      final manual = writer.append(
        const NewEvent(
          tsUtc: 1,
          source: EventSource.user,
          type: 'user_start',
          payloadJson: '{}',
        ),
      );
      final callback = writer.append(
        const NewEvent(
          tsUtc: 2,
          source: EventSource.gps,
          type: 'location',
          payloadJson: '{}',
        ),
      );
      final confirmation = writer.append(
        const NewEvent(
          tsUtc: 3,
          source: EventSource.system,
          type: 'recorder_start_confirmed',
          payloadJson: '{}',
        ),
      );

      await Future.wait([manual, callback, confirmation]);
      expect(writes, ['user_start', 'location', 'recorder_start_confirmed']);
      expect(
        (await repository.readRecent(10)).reversed.map((event) => event.type),
        ['user_start', 'location', 'recorder_start_confirmed'],
      );
    },
  );

  test(
    'notifies only committed writes without changing persistence results',
    () async {
      var notifications = 0;
      writer = RawEventWriter(
        repository,
        onPersisted: () {
          notifications++;
          throw StateError('projection scheduling failed');
        },
      );
      final id = await writer.append(
        const NewEvent(
          tsUtc: 1,
          source: EventSource.user,
          type: 'ok',
          payloadJson: '{}',
        ),
      );
      expect(id, 1);
      expect(notifications, 1);
      repository.onAppend = (_) async => throw StateError('disk full');
      await expectLater(
        writer.append(
          const NewEvent(
            tsUtc: 2,
            source: EventSource.user,
            type: 'bad',
            payloadJson: '{}',
          ),
        ),
        throwsStateError,
      );
      expect(notifications, 1);
      expect((await repository.readRecent(10)).single.type, 'ok');
    },
  );

  test('continues after a failed append without retrying it', () async {
    var calls = 0;
    repository.onAppend = (event) async {
      calls++;
      if (event.type == 'bad') throw StateError('disk full');
      return FakeEventRepository(database).append(event);
    };

    await expectLater(
      writer.append(
        const NewEvent(
          tsUtc: 1,
          source: EventSource.user,
          type: 'bad',
          payloadJson: '{}',
        ),
      ),
      throwsStateError,
    );
    await writer.append(
      const NewEvent(
        tsUtc: 2,
        source: EventSource.system,
        type: 'later',
        payloadJson: '{}',
      ),
    );

    expect(calls, 2);
    expect((await repository.readRecent(10)).single.type, 'later');
  });
}
