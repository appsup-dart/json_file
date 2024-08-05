import '../json_file.dart';

/// Computes the difference between two JSON files.
///
/// The difference is computed as a list of operations that can be applied to
/// the original JSON file to obtain the new JSON file. The operations follow
/// the [JSON Patch standard (RFC 6902)](https://datatracker.ietf.org/doc/html/rfc6902#page-6).
class JsonDifferencer extends JsonFileConsumer<List<Map<String, dynamic>>> {
  final RandomAccessJsonFile original;

  const JsonDifferencer(this.original);

  @override
  List<Map<String, dynamic>> consume(RandomAccessJsonFile file) {
    original.setPositionSync(0);

    return _diff(file, original).toList();
  }

  Iterable<Map<String, dynamic>> _diff(
      RandomAccessJsonFile newJson, RandomAccessJsonFile oldJson) sync* {
    var start = oldJson.readSync()!;

    var newNode = newJson.peekSync();

    if (newNode == null ||
        (start.isScalar &&
            (!newNode.isScalar || start.value != newNode.value)) ||
        (start.isObject && !newNode.isObject) ||
        (start.isArray && !newNode.isArray)) {
      yield {
        'op': 'replace',
        'path': '/${start.path!.segments.join('/')}',
        'value': const JsonAssembler().consume(newJson),
      };
      return;
    }

    if (start.isScalar) {
      newJson.skipSync();
      return;
    }

    var newStart = newJson.readSync()!;
    if (start.isObject) {
      var node = oldJson.peekSync();

      var indexes = <String, int>{};

      while (node != null && node.path?.parent == start.path) {
        var newNode = newJson.peekSync();

        // check if the old key is already indexed
        var index = indexes.remove(node.path!.key);
        if (index != null) {
          newJson.saveStateSync();
          newJson.setPositionSync(index);
          yield* _diff(newJson, oldJson);
          newJson.restoreStateSync();
        } else if (newNode == null || newNode.path?.parent != newStart.path) {
          // at end of new object, all remaining keys are deleted
          yield {
            'op': 'remove',
            'path': '/${node.path!.segments.join('/')}',
          };
          oldJson.skipSync();
        } else {
          if (newNode.path?.key == node.path?.key) {
            // same object key, compare values and advance
            yield* _diff(newJson, oldJson);
          } else {
            // different object keys

            // index the new key and check next new key
            indexes[newNode.path!.key as String] = newJson.positionSync();
            newJson.skipSync();
          }
        }
        node = oldJson.peekSync();
      }

      // all remaining keys are new
      var newNode = newJson.peekSync();
      while (newNode != null && newNode.path?.parent == newStart.path) {
        yield {
          'op': 'add',
          'path': '/${newNode.path!.segments.join('/')}',
          'value': const JsonAssembler().consume(newJson),
        };
        newNode = newJson.peekSync();
      }

      // all remaining keys in indexes are new
      for (var e in indexes.entries) {
        var index = e.value;
        newJson.saveStateSync();
        newJson.setPositionSync(index);
        yield {
          'op': 'add',
          'path': newStart.path == null
              ? '/${e.key}'
              : '/${newStart.path!.segments.join('/')}/${e.key}',
          'value': const JsonAssembler().consume(newJson),
        };
        newJson.restoreStateSync();
      }
    } else {
      throw UnimplementedError();
    }
  }
}
