import 'package:json_file/json_file.dart';
import 'package:test/test.dart';
import 'package:file/memory.dart';

void main() {
  group('JsonAssembler', () {
    test('should assemble a boolean', () {
      var v = assemble('true');

      expect(v, true);
    });

    test('should assemble a null', () {
      var v = assemble('null');

      expect(v, null);
    });

    test('should assemble a string', () {
      var v = assemble('"hello"');

      expect(v, 'hello');
    });

    test('should assemble an integer', () {
      var v = assemble('123');

      expect(v, 123);
    });

    test('should assemble a double', () {
      var v = assemble('123.456');

      expect(v, 123.456);
    });

    test('should assemble an empty object', () {
      var v = assemble('{}');

      expect(v, {});
    });

    test('should assemble an object', () {
      var v = assemble('{"hello": "world"}');

      expect(v, {'hello': 'world'});
    });

    test('should assemble an empty array', () {
      var v = assemble('[]');

      expect(v, []);
    });

    test('should assemble an array', () {
      var v = assemble('["hello", "world"]');

      expect(v, ['hello', 'world']);
    });

    test('should assemble a nested object', () {
      var v = assemble('{"hello": {"world": "world"}}');

      expect(v, {
        'hello': {'world': 'world'}
      });
    });

    test('should assemble a nested array', () {
      var v = assemble('{"hello": ["world", "world"]}');

      expect(v, {
        'hello': ['world', 'world']
      });
    });

    test('should assemble a nested object and array', () {
      var v = assemble('{"hello": {"world": ["world", "world"]}}');

      expect(v, {
        'hello': {
          'world': ['world', 'world']
        }
      });
    });
  });
}

dynamic assemble(String json) {
  var file = MemoryFileSystem().file('test.dart')..writeAsStringSync(json);

  var f = RandomAccessJsonFile(file.openSync());

  var v = JsonAssembler().consume(f);

  return v;
}
