import 'dart:convert';
import 'dart:math';

import 'package:json_file/json_file.dart';
import 'package:json_file/src/parser.dart';
import 'package:test/test.dart';

void main() {
  group('JsonParser', () {
    test('should parse a boolean', () {
      var nodes = parse('true');

      var node = nodes.single;

      expect(node.isScalar, isTrue);
      expect(node.value, true);
    });

    test('should parse a null', () {
      var nodes = parse('null');

      var node = nodes.single;

      expect(node.isScalar, isTrue);
      expect(node.value, null);
    });

    test('should parse a string', () {
      var nodes = parse('"hello"');

      var node = nodes.single;

      expect(node.isScalar, isTrue);
      expect(node.value, 'hello');
    });

    test('should parse an integer', () {
      var nodes = parse('123');

      var node = nodes.single;

      expect(node.isScalar, isTrue);
      expect(node.value, 123);
    });

    test('should parse a double', () {
      var nodes = parse('123.456');

      var node = nodes.single;

      expect(node.isScalar, isTrue);
      expect(node.value, 123.456);
    });

    test('should end parsing on `}`-token', () {
      var nodes = parse('123.456}');

      var node = nodes.single;

      expect(node.isScalar, isTrue);
      expect(node.value, 123.456);
    });

    test('should parse an object', () {
      var nodes = parse('{"hello": "world"}');

      expect(nodes.length, 2);

      var node = nodes.first;

      expect(node.isObject, isTrue);

      node = nodes.elementAt(1);
      expect(node.isScalar, isTrue);
      expect(node.path!.key, 'hello');
      expect(node.value, 'world');
    });

    test('should parse an array', () {
      var nodes = parse('[1, 2, 3]');

      expect(nodes.length, 4);

      var node = nodes.first;

      expect(node.isArray, isTrue);

      node = nodes.elementAt(1);
      expect(node.isScalar, isTrue);
      expect(node.path!.key, 0);
      expect(node.value, 1);

      node = nodes.elementAt(2);
      expect(node.isScalar, isTrue);
      expect(node.path!.key, 1);
      expect(node.value, 2);

      node = nodes.elementAt(3);
      expect(node.isScalar, isTrue);
      expect(node.path!.key, 2);
      expect(node.value, 3);
    });

    test('should parse an empty object', () {
      var nodes = parse('{}');

      expect(nodes.length, 1);

      var node = nodes.single;

      expect(node.isObject, isTrue);
    });

    test('should parse an empty array', () {
      var nodes = parse('[]');

      expect(nodes.length, 1);

      var node = nodes.single;

      expect(node.isArray, isTrue);
    });

    test('should parse a nested object', () {
      var nodes = parse('{"hello": {"world": "!"}}');

      expect(nodes.length, 3);

      var node = nodes.first;

      expect(node.isObject, isTrue);

      node = nodes.elementAt(1);
      expect(node.isObject, isTrue);
      expect(node.path!.key, 'hello');

      node = nodes.elementAt(2);
      expect(node.isScalar, isTrue);
      expect(node.path!.parent!.key, 'hello');
      expect(node.path!.key, 'world');
      expect(node.value, '!');
    });

    test('should parse a nested array', () {
      var nodes = parse('[1, [2, 3], 4]');

      expect(nodes.length, 6);

      var node = nodes.first;

      expect(node.isArray, isTrue);

      node = nodes.elementAt(1);
      expect(node.isScalar, isTrue);
      expect(node.path!.key, 0);
      expect(node.value, 1);

      node = nodes.elementAt(2);
      expect(node.isArray, isTrue);
      expect(node.path!.key, 1);

      node = nodes.elementAt(3);
      expect(node.isScalar, isTrue);
      expect(node.path!.parent!.key, 1);
      expect(node.path!.key, 0);
      expect(node.value, 2);

      node = nodes.elementAt(4);
      expect(node.isScalar, isTrue);
      expect(node.path!.parent!.key, 1);
      expect(node.path!.key, 1);
      expect(node.value, 3);

      node = nodes.elementAt(5);
      expect(node.isScalar, isTrue);
      expect(node.path!.parent, isNull);
      expect(node.path!.key, 2);
      expect(node.value, 4);
    });

    test('should parse a nested object in an array', () {
      var nodes = parse('[{"hello": "world"}]');

      expect(nodes.length, 3);

      var node = nodes.first;

      expect(node.isArray, isTrue);

      node = nodes.elementAt(1);
      expect(node.isObject, isTrue);
      expect(node.path!.key, 0);

      node = nodes.elementAt(2);
      expect(node.isScalar, isTrue);
      expect(node.path!.parent!.key, 0);
      expect(node.path!.key, 'hello');
      expect(node.value, 'world');
    });

    test('should parse a nested array in an object', () {
      var nodes = parse('{"hello": [1, 2, 3]}');

      expect(nodes.length, 5);

      var node = nodes.first;

      expect(node.isObject, isTrue);

      node = nodes.elementAt(1);
      expect(node.isArray, isTrue);
      expect(node.path!.key, 'hello');

      node = nodes.elementAt(2);
      expect(node.isScalar, isTrue);
      expect(node.path!.parent!.key, 'hello');
      expect(node.path!.key, 0);
      expect(node.value, 1);

      node = nodes.elementAt(3);
      expect(node.isScalar, isTrue);
      expect(node.path!.parent!.key, 'hello');
      expect(node.path!.key, 1);
      expect(node.value, 2);

      node = nodes.elementAt(4);
      expect(node.isScalar, isTrue);
      expect(node.path!.parent!.key, 'hello');
      expect(node.path!.key, 2);
      expect(node.value, 3);
    });

    test('should skip nested objects at higher depths', () {
      var nodes = parse('{"hello": [1, 2, 3], "world": {"!": 4}}', 1);

      expect(nodes.length, 3);

      var node = nodes.first;

      expect(node.isObject, isTrue);

      node = nodes.elementAt(1);
      expect(node.isArray, isTrue);
      expect(node.path!.key, 'hello');

      node = nodes.elementAt(2);
      expect(node.isObject, isTrue);
      expect(node.path!.key, 'world');
    });
  });
}

Iterable<JsonNode> parse(String json, [int? depth]) sync* {
  var parser = JsonParser(1024);
  var bytes = utf8.encode(json);

  while (!parser.isDone) {
    var node = parser.next();
    if (node != null) {
      yield node;
      if (depth != null && !node.isScalar) {
        if ((node.path?.segments.length ?? 0) >= depth) {
          parser.skip();
        }
      }
    } else {
      if (bytes.isEmpty) {
        parser.finilize();
      } else {
        parser.addChunk(bytes.sublist(0, min(1024, bytes.length)));
        bytes = bytes.sublist(min(1024, bytes.length));
      }
    }
  }
}
