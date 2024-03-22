import 'dart:convert';

import 'package:json_file/src/tokenizer.dart';

import '../json_file.dart';
import 'list_util.dart';

class JsonParser {
  final Tokenizer _tokenizer;

  final List<List<int>> _bytes;

  JsonParser(int chunkSize)
      : _tokenizer = Tokenizer(chunkSize),
        _bytes = List.filled(chunkSize + 1, const [], growable: false);

  JsonPathImpl? _path;

  List<Token> _tokens = const [];

  int _index = 0;

  int _depthToSkip = 0;

  int _processed = 0;

  void reset() {
    _tokenizer.reset();
    _bytes.fillRange(0, _bytes.length, const []);
    _path = null;
    _tokens = const [];
    _index = 0;
    _depthToSkip = 0;
    _processed = 0;
    _isDone = false;
  }

  bool skip() {
    if (_depthToSkip == 0) {
      _depthToSkip = 1;
    }

    while (true) {
      if (_index >= _tokens.length) {
        return false;
      }
      var b = _bytes[_index];
      var t = _tokens[_index++];
      _processed += b.length + 1;

      switch (t.value) {
        case Tokenizer.openCurly: // {
        case Tokenizer.openBracket: // [
          _depthToSkip++;
          break;
        case Tokenizer.closeCurly: // }
        case Tokenizer.closeBracket: // ]
          _depthToSkip--;
          if (_depthToSkip == 0) {
            _path = _path?.parent;
            return true;
          }
          break;
      }
    }
  }

  bool _isDone = false;

  JsonNode? next() {
    while (true) {
      if (_isDone || _index >= _tokens.length) {
        return null;
      }
      var b = _bytes[_index];
      var t = _tokens[_index++];

      var pos = _processed;
      _processed += b.length + 1;

      if (_path == null &&
          t.value != Tokenizer.openBracket &&
          t.value != Tokenizer.openCurly) {
        _isDone = true;
        if (t.marksEndOfScalar) {
          return JsonNodeImpl.scalar(_path, pos, b);
        }
        return null;
      }

      switch (t.value) {
        case Tokenizer.openCurly: // {
          var v = JsonNodeImpl.object(_path, pos);
          _path = JsonPathImpl(_path, JsonPathNodePlaceholder());
          return v;
        case Tokenizer.closeCurly: // }
          var p = _path;
          _path = _path!.parent;
          if (t.marksEndOfScalar) {
            return JsonNodeImpl.scalar(p, pos, b);
          }
          break;
        case Tokenizer.openBracket: // [
          var v = JsonNodeImpl.array(_path, pos);
          _path = JsonPathImpl(_path, JsonPathNodeIndex(0));
          return v;
        case Tokenizer.closeBracket: // ]
          var p = _path;
          _path = _path!.parent;
          if (t.marksEndOfScalar) {
            return JsonNodeImpl.scalar(p, pos, b);
          }
          break;
        case Tokenizer.colon: // :
          _path = JsonPathImpl(_path?.parent, JsonPathNodeKey(JsonValue(b)));
          break;
        case Tokenizer.comma: // ,
          var p = _path;
          var l = _path!.last;
          _path = JsonPathImpl(
              _path!.parent,
              l is JsonPathNodeIndex
                  ? JsonPathNodeIndex(l.index + 1) as JsonPathNode<dynamic>
                  : JsonPathNodePlaceholder());
          if (t.marksEndOfScalar) {
            return JsonNodeImpl.scalar(p, pos, b);
          }
      }
    }
  }

  bool get isDone => _isDone;

  void finilize() {
    if (_isDone) return;
    addChunk(const [Tokenizer.comma]);
  }

  void addChunk(List<int> bytes) {
    assert(!_isDone, 'Cannot add chunk after reaching end');
    if (_index < _tokens.length) {
      throw StateError(
          'Cannot add chunk while there are still tokens to consume');
    }

    var remainder = _bytes[_tokens.length];

    _tokens = _tokenizer.addChunk(bytes);
    _index = 0;

    if (_tokens.isEmpty) {
      _bytes[0] = CombinedList.from(remainder, bytes);
    } else {
      _bytes[0] =
          CombinedList.from(remainder, SubList(bytes, 0, _tokens[0].position));
      for (var i = 1; i < _tokens.length; i++) {
        _bytes[i] =
            SubList(bytes, _tokens[i - 1].position + 1, _tokens[i].position);
      }
      _bytes[_tokens.length] =
          SubList(bytes, _tokens.last.position + 1, bytes.length);
    }
  }
}

class JsonPathNodeKey extends JsonPathNode<String> {
  final JsonValue key;

  JsonPathNodeKey(this.key);

  @override
  String get value => key.value;
}

class JsonPathNodePlaceholder extends JsonPathNode<dynamic> {
  @override
  Null get value => null;
}

class JsonPathNodeIndex extends JsonPathNode<int> {
  final int index;

  JsonPathNodeIndex(this.index);

  @override
  int get value => index;
}

class JsonNodeImpl implements JsonNode {
  @override
  final JsonPath? path;

  @override
  final int position;

  @override
  final bool isObject;

  @override
  final bool isArray;

  @override
  final bool isScalar;

  final JsonValue? _value;

  JsonNodeImpl.scalar(this.path, this.position, List<int> bytes)
      : _value = JsonValue(bytes),
        isScalar = true,
        isObject = false,
        isArray = false;

  JsonNodeImpl.object(this.path, this.position)
      : _value = null,
        isScalar = false,
        isObject = true,
        isArray = false;

  JsonNodeImpl.array(this.path, this.position)
      : _value = null,
        isScalar = false,
        isObject = false,
        isArray = true;

  @override
  String toString() {
    return 'JsonNode.${isObject ? 'object' : isArray ? 'array' : 'scalar'}{path: ${path?.segments}, value: $value}';
  }

  @override
  get value => _value?.value;
}

/// A scalar value in a JSON file.
///
/// The value can be a string, number, boolean or null.
class JsonValue {
  /// The raw bytes of the value.
  final List<int> bytes;

  JsonValue(this.bytes);

  /// The decoded value.
  late final dynamic value =
      bytes.isEmpty ? null : json.decode(utf8.decode(bytes));
}

class JsonPathImpl implements JsonPath {
  @override
  final JsonPathImpl? parent;

  final JsonPathNode last;

  JsonPathImpl(this.parent, this.last);

  @override
  List<dynamic> get segments => [
        if (parent != null) ...parent!.segments,
        last.value,
      ];

  @override
  String toString() {
    return 'JsonPath{$segments}';
  }

  @override
  Object get key => last.value;
}

abstract class JsonPathNode<T> {
  T get value;

  @override
  String toString() {
    return 'JsonPathNode{value: $value}';
  }
}
