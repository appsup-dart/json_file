import 'package:file/memory.dart';
import 'package:json_file/json_file.dart';
import 'package:test/test.dart';

void main() {
  group('RandomAccessJsonFile.setPositionSync', () {
    late RandomAccessJsonFile f;

    setUp(() {
      var file = MemoryFileSystem().file('test.dart')
        ..writeAsStringSync('{"hello": {"world": ["world", "world"]}}');

      f = RandomAccessJsonFile(file.openSync());
    });

    test('should parse everything when position on start', () {
      f.readSync();
      f.setPositionSync(0);

      expect(f.readSync()?.position, 0);

      f.setPositionSync(0);

      expect(JsonAssembler().consume(f), {
        "hello": {
          "world": ["world", "world"]
        }
      });
    });

    test('should parse sub object when forward to start of object', () {
      f.readSync();
      f.setPositionSync(9);

      expect(f.readSync()?.position, 0);

      f.setPositionSync(9);

      expect(JsonAssembler().consume(f), {
        "world": ["world", "world"]
      });
    });

    test('should parse sub object when backward to start of object', () {
      f.readSync();
      f.readSync();
      f.readSync();
      f.setPositionSync(9);

      expect(f.readSync()?.position, 0);

      f.setPositionSync(9);

      expect(JsonAssembler().consume(f), {
        "world": ["world", "world"]
      });
    });
  });
}
