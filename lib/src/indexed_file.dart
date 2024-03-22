import 'dart:collection';

import '../json_file.dart';
import 'indexer.dart';
import 'list_util.dart';

class IndexedJsonFile {
  static const int _minSizeToIndex = 10 * 1024;
  final RandomAccessJsonFile file;

  final int position;

  final int lengthUpperBound;

  Map<String, IndexedJsonFile>? _mapIndex;

  List<IndexedJsonFile>? _listIndex;

  IndexedJsonFile(this.file, this.position, this.lengthUpperBound);

  factory IndexedJsonFile.fromJson(
      RandomAccessJsonFile file, Map<String, dynamic> json) {
    var index = json['index'];
    if (index is Map<String, dynamic>) {
      var map = index.map((k, v) => MapEntry(
          k, IndexedJsonFile.fromJson(file, v as Map<String, dynamic>)));
      return IndexedJsonFile(file, json['position'], json['lengthUpperBound'])
        .._mapIndex = map;
    }
    if (index is List) {
      var list = index
          .map((v) => IndexedJsonFile.fromJson(file, v as Map<String, dynamic>))
          .toList();
      return IndexedJsonFile(file, json['position'], json['lengthUpperBound'])
        .._listIndex = list;
    }
    return IndexedJsonFile(file, json['position'], json['lengthUpperBound']);
  }

  Map<String, dynamic> toJson() {
    return {
      'position': position,
      'lengthUpperBound': lengthUpperBound,
      'index': _mapIndex ?? _listIndex
    };
  }

  void _initIndex() {
    if (_mapIndex != null || _listIndex != null) return;
    if (lengthUpperBound < _minSizeToIndex) {
      return;
    }

    file.setPositionSync(position);
    var index = Indexer().consume(file);

    if (index == null) return;

    if (index is Map) {
      var positions = [...index.values, position + lengthUpperBound];

      var lengths =
          List.generate(index.length, (i) => positions[i + 1] - positions[i]);
      _mapIndex = index.map(
          (k, v) => MapEntry(k, IndexedJsonFile(file, v, lengths.removeAt(0))));
    } else if (index is List) {
      var positions = [...index, position + lengthUpperBound];

      var lengths =
          List.generate(index.length, (i) => positions[i + 1] - positions[i]);
      _listIndex = index
          .map((v) => IndexedJsonFile(file, v, lengths.removeAt(0)))
          .toList();
    }
  }

  dynamic read() {
    file.setPositionSync(position);
    return JsonAssembler().consume(file);
  }

  dynamic asJson() {
    _initIndex();
    if (_mapIndex != null) {
      return _JsonFileMap(this);
    }
    if (_listIndex != null) {
      return _JsonFileList(this);
    }
    return read();
  }
}

extension JsonFileX on RandomAccessJsonFile {
  dynamic asJson() {
    var f = IndexedJsonFile(this, 0, lengthSync());
    return f.asJson();
  }
}

class _JsonFileMap extends UnmodifiableMapBase<String, dynamic> {
  final IndexedJsonFile file;

  _JsonFileMap(this.file);

  @override
  operator [](Object? key) {
    var v = file._mapIndex![key];

    if (v != null) {
      return v.asJson();
    }
    return null;
  }

  @override
  Iterable<String> get keys {
    return file._mapIndex!.keys;
  }
}

class _JsonFileList extends UnmodifiableListBase<dynamic> {
  final IndexedJsonFile file;

  _JsonFileList(this.file);

  @override
  dynamic operator [](int index) {
    var v = file._listIndex![index];
    return v.asJson();
  }

  @override
  int get length => file._listIndex!.length;
}
