import 'dart:io';

import 'package:json_file/src/parser.dart';

import '../json_file.dart';

class JsonFileImpl implements RandomAccessJsonFile {
  static const int _chunkSize = 8 * 1024;

  final RandomAccessFile file;

  final JsonParser parser = JsonParser(_chunkSize);

  JsonNodeImpl? _current;

  int _startPosition = 0;

  JsonFileImpl(this.file);

  @override
  void closeSync() {
    file.closeSync();
  }

  @override
  int lengthSync() {
    return file.lengthSync();
  }

  @override
  int positionSync() {
    var n = peekSync();
    if (n == null) return lengthSync();
    return _startPosition + n.position;
  }

  @override
  JsonNode? readSync() {
    var v = peekSync();
    _current = null;
    return v;
  }

  @override
  JsonNodeImpl? peekSync() {
    if (_current != null) {
      return _current;
    }
    while (true) {
      _current = parser.next();
      if (_current != null) return _current;

      if (!_addNextChunk()) {
        return null;
      }
    }
  }

  bool _addNextChunk() {
    if (parser.isDone) {
      return false;
    }
    var bytes = file.readSync(_chunkSize);
    if (bytes.isEmpty) {
      parser.finilize();
      return true;
    }
    parser.addChunk(bytes);
    return true;
  }

  @override
  void setPositionSync(int position) {
    // TODO: optimize when position in range of current chunk
    parser.reset();
    _current = null;
    _startPosition = position;
    file.setPositionSync(position);
  }

  @override
  void skipSync() {
    var node = readSync();
    if (node == null || node.isScalar) {
      return;
    }
    while (!parser.skip()) {
      if (!_addNextChunk()) {
        return;
      }
    }
  }

  final List<MapEntry<int, JsonNodeImpl?>> _states = [];

  @override
  void restoreStateSync() {
    var state = _states.removeLast();

    var node = state.value;
    setPositionSync(state.key + (node?.position ?? 0));
    _startPosition = state.key;
    parser.setState(node?.path, node?.position);
  }

  @override
  void saveStateSync() {
    var node = peekSync();
    _states.add(MapEntry(_startPosition, node));
  }
}
