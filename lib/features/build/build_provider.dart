// build_provider.dart
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database.dart';

final projectsProvider = StreamProvider<List<Project>>((ref) {
  return ref.watch(dbProvider).watchActiveProjects();
});

final addProjectProvider =
    Provider<Future<void> Function(String name, String? description)>((ref) {
  final db = ref.watch(dbProvider);
  return (name, description) => db.addProject(ProjectsCompanion.insert(
        name: name,
        description: Value(description),
        createdAt: DateTime.now(),
      ));
});

final updateProgressProvider =
    Provider<Future<void> Function(int id, int pct)>((ref) {
  final db = ref.watch(dbProvider);
  return (id, pct) => db.updateProjectProgress(id, pct);
});
