import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:json_file/json_file.dart' hide JsonPath;
import 'package:json_file/src/indexed_file.dart';
import 'package:json_path/json_path.dart';
import 'package:path/path.dart' as path;

final parser = ArgParser()
  ..addFlag('index', defaultsTo: true, help: 'Use an index file')
  ..addFlag('help', abbr: 'h', help: 'Print this help message');

void main(List<String> args) {
  var results = parser.parse(args);

  if (results['help']) {
    printUsage();
  } else {
    if (results.rest.length != 2) {
      printUsage();
      return;
    }
    var query = JsonPath(results.rest[0]);
    var file = File(results.rest[1]);

    var indexFile = File(path.join(file.parent.path,
        '${path.basenameWithoutExtension(file.path)}.index.json'));

    var jsonFile = RandomAccessJsonFile(file.openSync());
    IndexedJsonFile indexedFile;
    if (results['index'] &&
        indexFile.existsSync() &&
        indexFile.lastModifiedSync().isAfter(file.lastModifiedSync())) {
      var index = json.decode(indexFile.readAsStringSync());
      indexedFile = IndexedJsonFile.fromJson(jsonFile, index);
    } else {
      indexedFile = IndexedJsonFile(jsonFile, 0, jsonFile.lengthSync());
    }

    var r = query.read(indexedFile.asJson());

    for (var m in r) {
      print(JsonEncoder.withIndent(' ').convert(m.value));
    }

    if (results['index']) {
      indexFile.writeAsStringSync(json.encode(indexedFile));
    }
  }
}

void printUsage() {
  print('djq - JSON Query tool in Dart');
  print('');
  print('Usage: djq [options] <query> <file>');
  print(parser.usage);
}
