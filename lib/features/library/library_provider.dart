// library_provider.dart
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database.dart';

final librarySearchQueryProvider = StateProvider<String>((ref) => '');

final pinsProvider = StreamProvider<List<Pin>>((ref) {
  final query = ref.watch(librarySearchQueryProvider);
  return ref.watch(dbProvider).watchPins(query: query.isEmpty ? null : query);
});

final studySessionsProvider = StreamProvider<List<StudySession>>((ref) {
  return ref.watch(dbProvider).watchStudySessions();
});

final addPinProvider = Provider<
    Future<void> Function({
      required String content,
      required String type,
      String? author,
      String? note,
      List<String> tags,
    })>((ref) {
  final db = ref.watch(dbProvider);
  return ({
    required String content,
    required String type,
    String? author,
    String? note,
    List<String> tags = const [],
  }) =>
      db.addPin(PinsCompanion.insert(
        content: content,
        type: type,
        createdAt: DateTime.now(),
        author: Value(author),
        note: Value(note),
        tags: Value('[${tags.map((t) => '"$t"').join(',')}]'),
      ));
});
