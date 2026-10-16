import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'projection_snapshot.dart';

class ProjectionStateRepository {
  ProjectionStateRepository(this._database);

  static const int _singletonId = 1;

  final AppDatabase _database;

  Future<String?> readStoredJson() async {
    final row = await (_database.select(
      _database.projectionStates,
    )..where((state) => state.id.equals(_singletonId))).getSingleOrNull();
    return row?.snapshotJson;
  }

  Future<ProjectionSnapshot> load() async {
    final row = await (_database.select(
      _database.projectionStates,
    )..where((state) => state.id.equals(_singletonId))).getSingleOrNull();
    if (row == null) return const ProjectionSnapshot.initial();
    return ProjectionSnapshotCodec.decode(row.snapshotJson);
  }

  Future<void> save(ProjectionSnapshot snapshot) => _database
      .into(_database.projectionStates)
      .insertOnConflictUpdate(
        ProjectionStatesCompanion.insert(
          id: const Value(_singletonId),
          snapshotJson: ProjectionSnapshotCodec.encode(snapshot),
        ),
      );
}
