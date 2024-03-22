import 'list_util.dart';

class Tokenizer {
  final List<Token> _tokens;

  Tokenizer(int chunkSize)
      : _tokens = List<Token>.filled(chunkSize, Token(0, 0, false));

  static const int quote = 0x22; // "

  static const int openCurly = 0x7b; // {

  static const int closeCurly = 0x7d; // }

  static const int colon = 0x3a; // :

  static const int comma = 0x2c; // ,

  static const int openBracket = 0x5b; // [

  static const int closeBracket = 0x5d; // ]

  static const int backslash = 0x5c; // \

  bool _inString = false;

  bool _inEscape = false;

  bool _hasNonSpaces = false;

  void reset() {
    _inString = false;
    _inEscape = false;
    _hasNonSpaces = false;
  }

  bool _isSpace(int byte) {
    switch (byte) {
      case 0x20: // space
      case 0x09: // tab
      case 0x0a: // newline
      case 0x0d: // carriage return
        return true;
    }
    return false;
  }

  bool _isToken(int byte) {
    switch (byte) {
      case openCurly:
      case closeCurly:
      case colon:
      case comma:
      case openBracket:
      case closeBracket:
        return true;
    }
    return false;
  }

  List<Token> addChunk(List<int> bytes) {
    var out = _tokens;
    var j = 0;
    for (var i = 0; i < bytes.length; i++) {
      var b = bytes[i];
      if (_inEscape) {
        _inEscape = false;
      } else if (b == backslash) {
        _inEscape = true;
      } else if (b == quote) {
        _inString = !_inString;
        _hasNonSpaces = true;
      } else if (!_inString && _isToken(b)) {
        out[j++] = Token(b, i, _hasNonSpaces);
        _hasNonSpaces = false;
      } else if (!_hasNonSpaces && !_inString && !_isSpace(b)) {
        _hasNonSpaces = true;
      }
    }
    return SubList(out, 0, j);
  }
}

class Token {
  final int value;

  final int position;

  final bool marksEndOfScalar;

  Token(this.value, this.position, this.marksEndOfScalar);
}
