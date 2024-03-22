import 'dart:collection';

abstract class UnmodifiableListBase<E> extends ListBase<E> {
  @override
  void operator []=(int index, E value) {
    throw UnsupportedError('Cannot modify an unmodifiable list');
  }

  @override
  set length(int value) =>
      throw UnsupportedError('Cannot modify an unmodifiable list');
}

class SubList<T> extends UnmodifiableListBase<T> {
  final List<T> _source;
  final int _start;
  final int _end;

  SubList(this._source, this._start, this._end);

  @override
  T operator [](int index) {
    return _source[_start + index];
  }

  @override
  int get length => _end - _start;
}

class CombinedList<T> extends UnmodifiableListBase<T> {
  final List<T> _first;
  final List<T> _second;

  CombinedList._(this._first, this._second);

  static List<T> from<T>(List<T> first, List<T> second) {
    if (first.isEmpty) return second;
    if (second.isEmpty) return first;
    return CombinedList._(first, second);
  }

  @override
  T operator [](int index) {
    if (index >= _first.length) {
      return _second[index - _first.length];
    }
    return _first[index];
  }

  @override
  int get length => _first.length + _second.length;
}
