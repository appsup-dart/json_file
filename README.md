
This package provides fast and memory friendly access to large JSON files.


## Command line tool

The command line tool `djq` allows to query a JSON file using a simple query language. The query language is based on [RFC 9535 - JSONPath query expressions](https://pub.dev/packages/json_path) query language.

This tool, originally created to access backups of large firebase realtime databases, is comparable to [jq](https://stedolan.github.io/jq/), but it is optimized for large JSON files and queries that return only a small portion of the original JSON. E.g., for a file of 5GB, it takes about 20 seconds to create the index file on a modern laptop. Subsequent queries can be very fast, typically in the order of 1 second. Processing such a file with `jq`, takes far longer and might run out of memory. The query language is different from `jq` and less powerful, but it is sufficient for many use cases. Currently, it doesn't have the same nice colouring and formatting as `jq`, but by piping the output to `jq` the same result can be achieved.

### Installation

```bash
pub global activate json_file
```

### Usage

```bash
djq [options] <query> <file>
```

By default the tool will create an index file and store it alongside the JSON file. The index file is used to speed up queries. The index file is created only if it does not exist. The index file is updated if the JSON file is newer than the index file. The option `--no-index` can be used to disable the index file.

## Usage in dart code

### Accessing a JSON file as regular dart object

This package provides an extension method `readAsJsonSync` on the `dart:io` `File` class to read a JSON file as a regular dart object. This method will not read the whole file into memory, but will only read the necessary parts of the file. This is useful for large JSON files that do not fit into memory and when only a small part of the JSON is required in the code.

```dart
import 'package:json_file/json_file.dart';

void main() {
  final json = File('example.json').readAsJsonSync();
  print(json['key']);
}
```

### Scanning a large JSON file

When needing to process the entire JSON file, one can use the `RandomAccessJsonFile` class. It will return the JSON nodes in the order they appear in the file. A node is a combination of a path and either a scalar value or an object or array start marker. The node can be read using the `readSync` method. The method will return `null` when the end of the file is reached.

```dart
import 'package:json_file/json_file.dart';

void main() {
  final file = RandomAccessJsonFile(File('example.json').openSync());

  var node = f.readSync();
  while (node != null) {
    // process node
    node = f.readSync();
  }
}
```

