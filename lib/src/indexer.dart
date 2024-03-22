import '../json_file.dart';

/// Indexes a JSON file.
class Indexer implements JsonFileConsumer<Object?> {
  final int depth;

  const Indexer({this.depth = 1});

  @override
  Object? consume(RandomAccessJsonFile file) {
    var start = file.readSync();
    if (start == null || start.isScalar) {
      return null;
    }

    return start.isObject
        ? _indexObject(file, start)
        : _indexArray(file, start);
  }

  Map<String, dynamic> _indexObject(RandomAccessJsonFile file, JsonNode start) {
    var result = <String, dynamic>{};

    while (true) {
      var node = file.peekSync();
      if (node == null || node.path?.parent != start.path) {
        return result;
      }
      var key = node.path!.key as String;
      result[key] = depth == 1
          ? file.positionSync()
          : Indexer(depth: depth - 1).consume(file);
      file.skipSync();
    }
  }

  List<dynamic> _indexArray(RandomAccessJsonFile file, JsonNode start) {
    var result = <dynamic>[];

    while (true) {
      var node = file.peekSync();
      if (node == null || node.path?.parent != start.path) {
        return result;
      }
      result.add(depth == 1
          ? file.positionSync()
          : Indexer(depth: depth - 1).consume(file));
      file.skipSync();
    }
  }
}
