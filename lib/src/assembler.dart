import '../json_file.dart';

/// Assembles a JSON file into a Dart object.
class JsonAssembler extends JsonFileConsumer<dynamic> {
  @override
  dynamic consume(RandomAccessJsonFile file) {
    var node = file.readSync();
    if (node == null) {
      return null;
    }
    return _assembleNode(node, file);
  }

  dynamic _assembleNode(JsonNode node, RandomAccessJsonFile file) {
    if (node.isObject) {
      return _assembleObject(node, file);
    } else if (node.isArray) {
      return _assembleArray(node, file);
    } else {
      return node.value;
    }
  }

  Map<String, dynamic> _assembleObject(
      JsonNode start, RandomAccessJsonFile file) {
    var result = <String, dynamic>{};

    while (true) {
      var node = file.peekSync();
      if (node == null || node.path?.parent != start.path) {
        return result;
      }
      var key = node.path!.key as String;
      result[key] = _assembleNode(file.readSync()!, file);
    }
  }

  List<dynamic> _assembleArray(JsonNode start, RandomAccessJsonFile file) {
    var result = <dynamic>[];

    while (true) {
      var node = file.peekSync();
      if (node == null || node.path?.parent != start.path) {
        return result;
      }
      result.add(_assembleNode(file.readSync()!, file));
    }
  }
}
