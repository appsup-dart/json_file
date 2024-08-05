import 'dart:io';

import 'package:json_file/src/indexed_file.dart';

import 'json_file_impl.dart';

extension ReadAsJsonFileExtension on File {
  /// Reads the file as JSON.
  ///
  /// The file is not read into memory all at once, but rather in chunks as
  /// needed. An index is built to allow fast access to the file contents.
  ///
  /// This should only be used for large files for which only a small portion
  /// of the json is needed. As more parts of the json are accessed, the index
  /// will grow bigger and the memory gain will be lost. When the entire json
  /// needs to be scanned, use [RandomAccessJsonFile] instead.
  dynamic readAsJsonSync() {
    return JsonFileImpl(openSync()).asJson();
  }
}

abstract class JsonFileConsumer<T> {
  const JsonFileConsumer();
  T consume(RandomAccessJsonFile file);
}

abstract class RandomAccessJsonFile {
  factory RandomAccessJsonFile(RandomAccessFile file) => JsonFileImpl(file);

  void closeSync();

  /// Reads the next node from the file.
  ///
  /// Returns `null` if the end of the file is reached.
  JsonNode? readSync();

  /// Peeks at the next node in the file.
  ///
  /// This does not advance the position in the file. Use [readSync] to advance
  /// the position. Returns `null` if the end of the file is reached.
  JsonNode? peekSync();

  /// Returns the position of the current node in the file.
  int positionSync();

  /// Returns the length of the file.
  int lengthSync();

  /// Sets the position in the file.
  ///
  /// The position should be the position of a node in the file, i.e. the
  /// beginning of a scalar value, object or array. Otherwise, subsequent reads
  /// will fail.
  ///
  /// The position should be obtained from a previous call to [positionSync].
  /// If the position is not valid, the behavior is undefined.
  ///
  /// The returned [JsonNode]s in subsequent calls to [readSync] or [peekSync]
  /// will represent nodes relative to this position. This means the path of the
  /// nodes will be relative to the path of the node at the given position. The
  /// position of the nodes will be relative to the position of the node at the
  /// given position. The method [positionSync] still returns the absolute
  /// position in the file. Calls to [readSync] or [peekSync] will return `null`
  /// if the end of the scalar, object or array is reached.
  void setPositionSync(int position);

  /// Skips the current node and all its children.
  ///
  /// For example, to read all the keys of an object without reading the values:
  ///
  /// ```dart
  /// var start = file.readSync();
  ///
  /// if (start.isObject) {
  ///   var node = file.peekSync();
  ///   while (node != null && node.path?.parent == start.path) {
  ///     print(node.path!.key);
  ///     file.skipSync();
  ///     node = file.peekSync();
  ///   }
  /// }
  /// ```
  ///
  void skipSync();
}

/// A node in a JSON file.
///
/// The node can be a scalar value, an object or an array.
abstract class JsonNode {
  /// The path to this node.
  JsonPath? get path;

  /// The position of this node in the file.
  int get position;

  /// Whether this node is a scalar value.
  bool get isScalar;

  /// Whether this node is an object.
  bool get isObject;

  /// Whether this node is an array.
  bool get isArray;

  /// The value of the node.
  dynamic get value;
}

/// A path to a node in a JSON file.
///
/// The path is a list of segments, where each segment is a key or index.
abstract class JsonPath {
  /// The parent path.
  JsonPath? get parent;

  /// The segments of the path.
  List<dynamic> get segments;

  /// The key of the last segment.
  ///
  /// If the last segment is an object key, this is the key. If the last segment
  /// is an array index, this is the index.
  Object get key;
}
