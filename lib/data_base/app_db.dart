import 'package:drift/drift.dart';

part 'app_db.g.dart';  // ✅ Required for drift code generation

@DataClassName('LocationPoint')
class LocationPoints extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  TextColumn get routeId => text()();
}

@DriftDatabase(tables: [LocationPoints])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  Future<void> insertPoint(LocationPointsCompanion entry) =>
      into(locationPoints).insert(entry);

  Stream<List<LocationPoint>> watchPointsByRoute(String routeId) =>
      (select(locationPoints)..where((tbl) => tbl.routeId.equals(routeId))).watch();

  Future<List<LocationPoint>> getPointsByRoute(String routeId) =>
      (select(locationPoints)..where((tbl) => tbl.routeId.equals(routeId))).get();

  Future<List<String>> getAllRouteIds() async {
    final results = await customSelect(
      'SELECT DISTINCT route_id FROM location_points',
    ).get();
    return results.map((row) => row.read<String>('route_id')).toList();
  }

  Future<Map<String, dynamic>> getRouteSummary(String routeId) async {
    final points = await getPointsByRoute(routeId);
    if (points.isEmpty) return {};

    return {
      'routeId': routeId,
      'startTime': points.first.timestamp,
      'endTime': points.last.timestamp,
      'pointCount': points.length,
      'duration': points.last.timestamp.difference(points.first.timestamp),
    };
  }

  Future<void> clearRoute(String routeId) async {
    await (delete(locationPoints)..where((tbl) => tbl.routeId.equals(routeId))).go();
  }

  Future<void> clearAllRoutes() async {
    await delete(locationPoints).go();
  }

  Future<int> getRouteCount() async {
    final results = await customSelect(
      'SELECT COUNT(DISTINCT route_id) as count FROM location_points',
    ).get();
    return results.first.read<int>('count');
  }

  Future<int> getTotalPoints() async {
    final result = await customSelect(
      'SELECT COUNT(*) as count FROM location_points',
    ).getSingle();
    return result.read<int>('count');
  }
}
