//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftShims

// Conversions between different Unicode encodings.  Note that UTF-16 and
// UTF-32 decoding are *not* currently resilient to erroneous data.

/// The result of one Unicode decoding step.
///
/// Each `UnicodeDecodingResult` instance can represent a Unicode scalar value,
/// an indication that no more Unicode scalars are available, or an indication
/// of a decoding error.
/// 
/// - SeeAlso: `UnicodeCodec.decode(next:)`
@_fixed_layout
public enum UnicodeDecodingResult : Equatable {
  /// A decoded Unicode scalar value.
  case scalarValue(Unicode.Scalar)
  
  /// An indication that no more Unicode scalars are available in the input.
  case emptyInput
  
  /// An indication of a decoding error.
  case error

  public static func == (
    lhs: UnicodeDecodingResult,
    rhs: UnicodeDecodingResult
  ) -> Bool {
    switch (lhs, rhs) {
    case (.scalarValue(let lhsScalar), .scalarValue(let rhsScalar)):
      return lhsScalar == rhsScalar
    case (.emptyInput, .emptyInput):
      return true
    case (.error, .error):
      return true
    default:
      return false
    }
  }
}

/// A Unicode encoding form that translates between Unicode scalar values and
/// form-specific code units.
///
/// The `UnicodeCodec` protocol declares methods that decode code unit
/// sequences into Unicode scalar values and encode Unicode scalar values
/// into code unit sequences. The standard library implements codecs for the
/// UTF-8, UTF-16, and UTF-32 encoding schemes as the `UTF8`, `UTF16`, and
/// `UTF32` types, respectively. Use the `Unicode.Scalar` type to work with
/// decoded Unicode scalar values.
///
/// - SeeAlso: `UTF8`, `UTF16`, `UTF32`, `Unicode.Scalar`
public protocol UnicodeCodec : Unicode.Encoding {

  /// Creates an instance of the codec.
  init()

  /// Starts or continues decoding a code unit sequence into Unicode scalar
  /// values.
  ///
  /// To decode a code unit sequence completely, call this method repeatedly
  /// until it returns `UnicodeDecodingResult.emptyInput`. Checking that the
  /// iterator was exhausted is not sufficient, because the decoder can store
  /// buffered data from the input iterator.
  ///
  /// Because of buffering, it is impossible to find the corresponding position
  /// in the iterator for a given returned `Unicode.Scalar` or an error.
  ///
  /// The following example decodes the UTF-8 encoded bytes of a string into an
  /// array of `Unicode.Scalar` instances:
  ///
  ///     let str = "✨Unicode✨"
  ///     print(Array(str.utf8))
  ///     // Prints "[226, 156, 168, 85, 110, 105, 99, 111, 100, 101, 226, 156, 168]"
  ///
  ///     var bytesIterator = str.utf8.makeIterator()
  ///     var scalars: [Unicode.Scalar] = []
  ///     var utf8Decoder = UTF8()
  ///     Decode: while true {
  ///         switch utf8Decoder.decode(&bytesIterator) {
  ///         case .scalarValue(let v): scalars.append(v)
  ///         case .emptyInput: break Decode
  ///         case .error:
  ///             print("Decoding error")
  ///             break Decode
  ///         }
  ///     }
  ///     print(scalars)
  ///     // Prints "["\u{2728}", "U", "n", "i", "c", "o", "d", "e", "\u{2728}"]"
  ///
  /// - Parameter input: An iterator of code units to be decoded. `input` must be
  ///   the same iterator instance in repeated calls to this method. Do not
  ///   advance the iterator or any copies of the iterator outside this
  ///   method.
  /// - Returns: A `UnicodeDecodingResult` instance, representing the next
  ///   Unicode scalar, an indication of an error, or an indication that the
  ///   UTF sequence has been fully decoded.
  mutating func decode<I : IteratorProtocol>(
    _ input: inout I
  ) -> UnicodeDecodingResult where I.Element == CodeUnit

  /// Encodes a Unicode scalar as a series of code units by calling the given
  /// closure on each code unit.
  ///
  /// For example, the musical fermata symbol ("𝄐") is a single Unicode scalar
  /// value (`\u{1D110}`) but requires four code units for its UTF-8
  /// representation. The following code uses the `UTF8` codec to encode a
  /// fermata in UTF-8:
  ///
  ///     var bytes: [UTF8.CodeUnit] = []
  ///     UTF8.encode("𝄐", into: { bytes.append($0) })
  ///     print(bytes)
  ///     // Prints "[240, 157, 132, 144]"
  ///
  /// - Parameters:
  ///   - input: The Unicode scalar value to encode.
  ///   - processCodeUnit: A closure that processes one code unit argument at a
  ///     time.
  static func encode(
    _ input: Unicode.Scalar,
    into processCodeUnit: (CodeUnit) -> Void
  )

  /// Searches for the first occurrence of a `CodeUnit` that is equal to 0.
  ///
  /// Is an equivalent of `strlen` for C-strings.
  ///
  /// - Complexity: O(*n*)
  static func _nullCodeUnitOffset(in input: UnsafePointer<CodeUnit>) -> Int
}

/// A codec for translating between Unicode scalar values and UTF-8 code
/// units.
extension Unicode.UTF8 : UnicodeCodec {
  /// Creates an instance of the UTF-8 codec.
  public init() { self = ._swift3Buffer(ForwardParser()) }

  /// Starts or continues decoding a UTF-8 sequence.
  ///
  /// To decode a code unit sequence completely, call this method repeatedly
  /// until it returns `UnicodeDecodingResult.emptyInput`. Checking that the
  /// iterator was exhausted is not sufficient, because the decoder can store
  /// buffered data from the input iterator.
  ///
  /// Because of buffering, it is impossible to find the corresponding position
  /// in the iterator for a given returned `Unicode.Scalar` or an error.
  ///
  /// The following example decodes the UTF-8 encoded bytes of a string into an
  /// array of `Unicode.Scalar` instances. This is a demonstration only---if
  /// you need the Unicode scalar representation of a string, use its
  /// `unicodeScalars` view.
  ///
  ///     let str = "✨Unicode✨"
  ///     print(Array(str.utf8))
  ///     // Prints "[226, 156, 168, 85, 110, 105, 99, 111, 100, 101, 226, 156, 168]"
  ///
  ///     var bytesIterator = str.utf8.makeIterator()
  ///     var scalars: [Unicode.Scalar] = []
  ///     var utf8Decoder = UTF8()
  ///     Decode: while true {
  ///         switch utf8Decoder.decode(&bytesIterator) {
  ///         case .scalarValue(let v): scalars.append(v)
  ///         case .emptyInput: break Decode
  ///         case .error:
  ///             print("Decoding error")
  ///             break Decode
  ///         }
  ///     }
  ///     print(scalars)
  ///     // Prints "["\u{2728}", "U", "n", "i", "c", "o", "d", "e", "\u{2728}"]"
  ///
  /// - Parameter input: An iterator of code units to be decoded. `input` must be
  ///   the same iterator instance in repeated calls to this method. Do not
  ///   advance the iterator or any copies of the iterator outside this
  ///   method.
  /// - Returns: A `UnicodeDecodingResult` instance, representing the next
  ///   Unicode scalar, an indication of an error, or an indication that the
  ///   UTF sequence has been fully decoded.
  @inline(__always)
  public mutating func decode<I : IteratorProtocol>(
    _ input: inout I
  ) -> UnicodeDecodingResult where I.Element == CodeUnit {
    guard case ._swift3Buffer(var parser) = self else {
      Builtin.unreachable()
    }
    defer { self = ._swift3Buffer(parser) }

    switch parser.parseScalar(from: &input) {
    case .valid(let s): return .scalarValue(UTF8.decode(s))
    case .error: return .error
    case .emptyInput: return .emptyInput
    }
  }

  /// Attempts to decode a single UTF-8 code unit sequence starting at the LSB
  /// of `buffer`.
  ///
  /// - Returns:
  ///   - result: The decoded code point if the code unit sequence is
  ///     well-formed; `nil` otherwise.
  ///   - length: The length of the code unit sequence in bytes if it is
  ///     well-formed; otherwise the *maximal subpart of the ill-formed
  ///     sequence* (Unicode 8.0.0, Ch 3.9, D93b), i.e. the number of leading
  ///     code units that were valid or 1 in case none were valid.  Unicode
  ///     recommends to skip these bytes and replace them by a single
  ///     replacement character (U+FFFD).
  ///
  /// - Requires: There is at least one used byte in `buffer`, and the unused
  ///   space in `buffer` is filled with some value not matching the UTF-8
  ///   continuation byte form (`0b10xxxxxx`).
  public // @testable
  static func _decodeOne(_ buffer: UInt32) -> (result: UInt32?, length: UInt8) {
    // Note the buffer is read least significant byte first: [ #3 #2 #1 #0 ].

    if buffer & 0x80 == 0 { // 1-byte sequence (ASCII), buffer: [ ... ... ... CU0 ].
      let value = buffer & 0xff
      return (value, 1)
    }
    var p = ForwardParser()
    p._buffer._storage = buffer
    p._buffer._bitCount = 32
    var i = EmptyCollection<UInt8>().makeIterator()
    switch p.parseScalar(from: &i) {
    case .valid(let s):
      return (
        result: UTF8.decode(s).value,
        length: UInt8(extendingOrTruncating: s.count))
    case .error(let l):
      return (result: nil, length: UInt8(extendingOrTruncating: l))
    case .emptyInput: Builtin.unreachable()
    }
  }

  /// Encodes a Unicode scalar as a series of code units by calling the given
  /// closure on each code unit.
  ///
  /// For example, the musical fermata symbol ("𝄐") is a single Unicode scalar
  /// value (`\u{1D110}`) but requires four code units for its UTF-8
  /// representation. The following code encodes a fermata in UTF-8:
  ///
  ///     var bytes: [UTF8.CodeUnit] = []
  ///     UTF8.encode("𝄐", into: { bytes.append($0) })
  ///     print(bytes)
  ///     // Prints "[240, 157, 132, 144]"
  ///
  /// - Parameters:
  ///   - input: The Unicode scalar value to encode.
  ///   - processCodeUnit: A closure that processes one code unit argument at a
  ///     time.
  public static func encode(
    _ input: Unicode.Scalar,
    into processCodeUnit: (CodeUnit) -> Void
  ) {
    var s = encode(input)!._storage
    processCodeUnit(UInt8(extendingOrTruncating: s))
    s &>>= 8
    if _fastPath(s == 0) { return }
    processCodeUnit(UInt8(extendingOrTruncating: s))
    s &>>= 8
    if _fastPath(s == 0) { return }
    processCodeUnit(UInt8(extendingOrTruncating: s))
    s &>>= 8
    if _fastPath(s == 0) { return }
    processCodeUnit(UInt8(extendingOrTruncating: s))
  }

  /// Returns a Boolean value indicating whether the specified code unit is a
  /// UTF-8 continuation byte.
  ///
  /// Continuation bytes take the form `0b10xxxxxx`. For example, a lowercase
  /// "e" with an acute accent above it (`"é"`) uses 2 bytes for its UTF-8
  /// representation: `0b11000011` (195) and `0b10101001` (169). The second
  /// byte is a continuation byte.
  ///
  ///     let eAcute = "é"
  ///     for codePoint in eAcute.utf8 {
  ///         print(codePoint, UTF8.isContinuation(codePoint))
  ///     }
  ///     // Prints "195 false"
  ///     // Prints "169 true"
  ///
  /// - Parameter byte: A UTF-8 code unit.
  /// - Returns: `true` if `byte` is a continuation byte; otherwise, `false`.
  public static func isContinuation(_ byte: CodeUnit) -> Bool {
    return byte & 0b11_00__0000 == 0b10_00__0000
  }

  public static func _nullCodeUnitOffset(
    in input: UnsafePointer<CodeUnit>
  ) -> Int {
    return Int(_swift_stdlib_strlen_unsigned(input))
  }
  // Support parsing C strings as-if they are UTF8 strings.
  public static func _nullCodeUnitOffset(
    in input: UnsafePointer<CChar>
  ) -> Int {
    return Int(_swift_stdlib_strlen(input))
  }
}

// @available(swift, obsoleted: 4.0, renamed: "Unicode.UTF8")
public typealias UTF8 = Unicode.UTF8

/// A codec for translating between Unicode scalar values and UTF-16 code
/// units.
extension Unicode.UTF16 : UnicodeCodec {
  /// Creates an instance of the UTF-16 codec.
  public init() { self = ._swift3Buffer(ForwardParser()) }

  /// Starts or continues decoding a UTF-16 sequence.
  ///
  /// To decode a code unit sequence completely, call this method repeatedly
  /// until it returns `UnicodeDecodingResult.emptyInput`. Checking that the
  /// iterator was exhausted is not sufficient, because the decoder can store
  /// buffered data from the input iterator.
  ///
  /// Because of buffering, it is impossible to find the corresponding position
  /// in the iterator for a given returned `Unicode.Scalar` or an error.
  ///
  /// The following example decodes the UTF-16 encoded bytes of a string into an
  /// array of `Unicode.Scalar` instances. This is a demonstration only---if
  /// you need the Unicode scalar representation of a string, use its
  /// `unicodeScalars` view.
  ///
  ///     let str = "✨Unicode✨"
  ///     print(Array(str.utf16))
  ///     // Prints "[10024, 85, 110, 105, 99, 111, 100, 101, 10024]"
  ///
  ///     var codeUnitIterator = str.utf16.makeIterator()
  ///     var scalars: [Unicode.Scalar] = []
  ///     var utf16Decoder = UTF16()
  ///     Decode: while true {
  ///         switch utf16Decoder.decode(&codeUnitIterator) {
  ///         case .scalarValue(let v): scalars.append(v)
  ///         case .emptyInput: break Decode
  ///         case .error:
  ///             print("Decoding error")
  ///             break Decode
  ///         }
  ///     }
  ///     print(scalars)
  ///     // Prints "["\u{2728}", "U", "n", "i", "c", "o", "d", "e", "\u{2728}"]"
  ///
  /// - Parameter input: An iterator of code units to be decoded. `input` must be
  ///   the same iterator instance in repeated calls to this method. Do not
  ///   advance the iterator or any copies of the iterator outside this
  ///   method.
  /// - Returns: A `UnicodeDecodingResult` instance, representing the next
  ///   Unicode scalar, an indication of an error, or an indication that the
  ///   UTF sequence has been fully decoded.
  public mutating func decode<I : IteratorProtocol>(
    _ input: inout I
  ) -> UnicodeDecodingResult where I.Element == CodeUnit {
    guard case ._swift3Buffer(var parser) = self else {
      Builtin.unreachable()
    }
    defer { self = ._swift3Buffer(parser) }
    switch parser.parseScalar(from: &input) {
    case .valid(let s): return .scalarValue(UTF16.decode(s))
    case .error: return .error
    case .emptyInput: return .emptyInput
    }
  }

  /// Try to decode one Unicode scalar, and return the actual number of code
  /// units it spanned in the input.  This function may consume more code
  /// units than required for this scalar.
  @_versioned
  internal mutating func _decodeOne<I : IteratorProtocol>(
    _ input: inout I
  ) -> (UnicodeDecodingResult, Int) where I.Element == CodeUnit {
    let result = decode(&input)
    switch result {
    case .scalarValue(let us):
      return (result, UTF16.width(us))

    case .emptyInput:
      return (result, 0)

    case .error:
      return (result, 1)
    }
  }

  /// Encodes a Unicode scalar as a series of code units by calling the given
  /// closure on each code unit.
  ///
  /// For example, the musical fermata symbol ("𝄐") is a single Unicode scalar
  /// value (`\u{1D110}`) but requires two code units for its UTF-16
  /// representation. The following code encodes a fermata in UTF-16:
  ///
  ///     var codeUnits: [UTF16.CodeUnit] = []
  ///     UTF16.encode("𝄐", into: { codeUnits.append($0) })
  ///     print(codeUnits)
  ///     // Prints "[55348, 56592]"
  ///
  /// - Parameters:
  ///   - input: The Unicode scalar value to encode.
  ///   - processCodeUnit: A closure that processes one code unit argument at a
  ///     time.
  public static func encode(
    _ input: Unicode.Scalar,
    into processCodeUnit: (CodeUnit) -> Void
  ) {
    var s = encode(input)!._storage
    processCodeUnit(UInt16(extendingOrTruncating: s))
    s &>>= 16
    if _fastPath(s == 0) { return }
    processCodeUnit(UInt16(extendingOrTruncating: s))
  }
}
// @available(swift, obsoleted: 4.0, renamed: "Unicode.UTF16")
public typealias UTF16 = Unicode.UTF16

/// A codec for translating between Unicode scalar values and UTF-32 code
/// units.
extension Unicode.UTF32 : UnicodeCodec {
  /// Creates an instance of the UTF-32 codec.
  public init() { self = ._swift3Codec }

  /// Starts or continues decoding a UTF-32 sequence.
  ///
  /// To decode a code unit sequence completely, call this method repeatedly
  /// until it returns `UnicodeDecodingResult.emptyInput`. Checking that the
  /// iterator was exhausted is not sufficient, because the decoder can store
  /// buffered data from the input iterator.
  ///
  /// Because of buffering, it is impossible to find the corresponding position
  /// in the iterator for a given returned `Unicode.Scalar` or an error.
  ///
  /// The following example decodes the UTF-16 encoded bytes of a string
  /// into an array of `Unicode.Scalar` instances. This is a demonstration
  /// only---if you need the Unicode scalar representation of a string, use
  /// its `unicodeScalars` view.
  ///
  ///     // UTF-32 representation of "✨Unicode✨"
  ///     let codeUnits: [UTF32.CodeUnit] =
  ///             [10024, 85, 110, 105, 99, 111, 100, 101, 10024]
  ///
  ///     var codeUnitIterator = codeUnits.makeIterator()
  ///     var scalars: [Unicode.Scalar] = []
  ///     var utf32Decoder = UTF32()
  ///     Decode: while true {
  ///         switch utf32Decoder.decode(&codeUnitIterator) {
  ///         case .scalarValue(let v): scalars.append(v)
  ///         case .emptyInput: break Decode
  ///         case .error:
  ///             print("Decoding error")
  ///             break Decode
  ///         }
  ///     }
  ///     print(scalars)
  ///     // Prints "["\u{2728}", "U", "n", "i", "c", "o", "d", "e", "\u{2728}"]"
  ///
  /// - Parameter input: An iterator of code units to be decoded. `input` must be
  ///   the same iterator instance in repeated calls to this method. Do not
  ///   advance the iterator or any copies of the iterator outside this
  ///   method.
  /// - Returns: A `UnicodeDecodingResult` instance, representing the next
  ///   Unicode scalar, an indication of an error, or an indication that the
  ///   UTF sequence has been fully decoded.
  public mutating func decode<I : IteratorProtocol>(
    _ input: inout I
  ) -> UnicodeDecodingResult where I.Element == CodeUnit {
    return UTF32._decode(&input)
  }

  internal static func _decode<I : IteratorProtocol>(
    _ input: inout I
  ) -> UnicodeDecodingResult where I.Element == CodeUnit {
    var parser = ForwardParser()
    
    switch parser.parseScalar(from: &input) {
    case .valid(let s): return .scalarValue(UTF32.decode(s))
    case .error:      return .error
    case .emptyInput:   return .emptyInput
    }
  }

  /// Encodes a Unicode scalar as a UTF-32 code unit by calling the given
  /// closure.
  ///
  /// For example, like every Unicode scalar, the musical fermata symbol ("𝄐")
  /// can be represented in UTF-32 as a single code unit. The following code
  /// encodes a fermata in UTF-32:
  ///
  ///     var codeUnit: UTF32.CodeUnit = 0
  ///     UTF32.encode("𝄐", into: { codeUnit = $0 })
  ///     print(codeUnit)
  ///     // Prints "119056"
  ///
  /// - Parameters:
  ///   - input: The Unicode scalar value to encode.
  ///   - processCodeUnit: A closure that processes one code unit argument at a
  ///     time.
  public static func encode(
    _ input: Unicode.Scalar,
    into processCodeUnit: (CodeUnit) -> Void
  ) {
    processCodeUnit(UInt32(input))
  }
}
// @available(swift, obsoleted: 4.0, renamed: "Unicode.UTF32")
public typealias UTF32 = Unicode.UTF32

/// Translates the given input from one Unicode encoding to another by calling
/// the given closure.
///
/// The following example transcodes the UTF-8 representation of the string
/// `"Fermata 𝄐"` into UTF-32.
///
///     let fermata = "Fermata 𝄐"
///     let bytes = fermata.utf8
///     print(Array(bytes))
///     // Prints "[70, 101, 114, 109, 97, 116, 97, 32, 240, 157, 132, 144]"
///
///     var codeUnits: [UTF32.CodeUnit] = []
///     let sink = { codeUnits.append($0) }
///     transcode(bytes.makeIterator(), from: UTF8.self, to: UTF32.self,
///               stoppingOnError: false, into: sink)
///     print(codeUnits)
///     // Prints "[70, 101, 114, 109, 97, 116, 97, 32, 119056]"
///
/// The `sink` closure is called with each resulting UTF-32 code unit as the
/// function iterates over its input.
///
/// - Parameters:
///   - input: An iterator of code units to be translated, encoded as
///     `inputEncoding`. If `stopOnError` is `false`, the entire iterator will
///     be exhausted. Otherwise, iteration will stop if an encoding error is
///     detected.
///   - inputEncoding: The Unicode encoding of `input`.
///   - outputEncoding: The destination Unicode encoding.
///   - stopOnError: Pass `true` to stop translation when an encoding error is
///     detected in `input`. Otherwise, a Unicode replacement character
///     (`"\u{FFFD}"`) is inserted for each detected error.
///   - processCodeUnit: A closure that processes one `outputEncoding` code
///     unit at a time.
/// - Returns: `true` if the translation detected encoding errors in `input`;
///   otherwise, `false`.
@inline(__always)
public func transcode<
  Input : IteratorProtocol,
  InputEncoding : Unicode.Encoding,
  OutputEncoding : Unicode.Encoding
>(
  _ input: Input,
  from inputEncoding: InputEncoding.Type,
  to outputEncoding: OutputEncoding.Type,
  stoppingOnError stopOnError: Bool,
  into processCodeUnit: (OutputEncoding.CodeUnit) -> Void
) -> Bool
  where InputEncoding.CodeUnit == Input.Element {
  var input = input

  // NB.  It is not possible to optimize this routine to a memcpy if
  // InputEncoding == OutputEncoding.  The reason is that memcpy will not
  // substitute U+FFFD replacement characters for ill-formed sequences.

  var p = InputEncoding.ForwardParser()
  var hadError = false
  loop:
  while true {
    switch p.parseScalar(from: &input) {
    case .valid(let s):
      let t = OutputEncoding.transcode(s, from: inputEncoding)
      guard _fastPath(t != nil), let s = t else { break }
      s.forEach(processCodeUnit)
      continue loop
    case .emptyInput:
      return hadError
    case .error:
      if _slowPath(stopOnError) { return true }
      hadError = true
    }
    OutputEncoding.encodedReplacementCharacter.forEach(processCodeUnit)
  }
}

/// Transcode UTF-16 to UTF-8, replacing ill-formed sequences with U+FFFD.
///
/// Returns the index of the first unhandled code unit and the UTF-8 data
/// that was encoded.
internal func _transcodeSomeUTF16AsUTF8<Input : Collection>(
  _ input: Input, _ startIndex: Input.Index
) -> (Input.Index, _StringCore._UTF8Chunk)
  where Input.Element == UInt16 {

  typealias _UTF8Chunk = _StringCore._UTF8Chunk

  let endIndex = input.endIndex
  let utf8Max = MemoryLayout<_UTF8Chunk>.size
  var result: _UTF8Chunk = 0
  var utf8Count = 0
  var nextIndex = startIndex
  while nextIndex != input.endIndex && utf8Count != utf8Max {
    let u = UInt(input[nextIndex])
    let shift = _UTF8Chunk(utf8Count * 8)
    var utf16Length: Input.IndexDistance = 1

    if _fastPath(u <= 0x7f) {
      result |= _UTF8Chunk(u) &<< shift
      utf8Count += 1
    } else {
      var scalarUtf8Length: Int
      var r: UInt
      if _fastPath((u &>> 11) != 0b1101_1) {
        // Neither high-surrogate, nor low-surrogate -- well-formed sequence
        // of 1 code unit, decoding is trivial.
        if u < 0x800 {
          r = 0b10__00_0000__110__0_0000
          r |= u &>> 6
          r |= (u & 0b11_1111) &<< 8
          scalarUtf8Length = 2
        }
        else {
          r = 0b10__00_0000__10__00_0000__1110__0000
          r |= u &>> 12
          r |= ((u &>> 6) & 0b11_1111) &<< 8
          r |= (u         & 0b11_1111) &<< 16
          scalarUtf8Length = 3
        }
      } else {
        let unit0 = u
        if _slowPath((unit0 &>> 10) == 0b1101_11) {
          // `unit0` is a low-surrogate.  We have an ill-formed sequence.
          // Replace it with U+FFFD.
          r = 0xbdbfef
          scalarUtf8Length = 3
        } else if _slowPath(input.index(nextIndex, offsetBy: 1) == endIndex) {
          // We have seen a high-surrogate and EOF, so we have an ill-formed
          // sequence.  Replace it with U+FFFD.
          r = 0xbdbfef
          scalarUtf8Length = 3
        } else {
          let unit1 = UInt(input[input.index(nextIndex, offsetBy: 1)])
          if _fastPath((unit1 &>> 10) == 0b1101_11) {
            // `unit1` is a low-surrogate.  We have a well-formed surrogate
            // pair.
            let v = 0x10000 + (((unit0 & 0x03ff) &<< 10) | (unit1 & 0x03ff))

            r = 0b10__00_0000__10__00_0000__10__00_0000__1111_0__000
            r |= v &>> 18
            r |= ((v &>> 12) & 0b11_1111) &<< 8
            r |= ((v &>> 6)  & 0b11_1111) &<< 16
            r |= (v          & 0b11_1111) &<< 24
            scalarUtf8Length = 4
            utf16Length = 2
          } else {
            // Otherwise, we have an ill-formed sequence.  Replace it with
            // U+FFFD.
            r = 0xbdbfef
            scalarUtf8Length = 3
          }
        }
      }
      // Don't overrun the buffer
      if utf8Count + scalarUtf8Length > utf8Max {
        break
      }
      result |= numericCast(r) &<< shift
      utf8Count += scalarUtf8Length
    }
    nextIndex = input.index(nextIndex, offsetBy: utf16Length)
  }
  // FIXME: Annoying check, courtesy of <rdar://problem/16740169>
  if utf8Count < MemoryLayout.size(ofValue: result) {
    result |= ~0 &<< numericCast(utf8Count * 8)
  }
  return (nextIndex, result)
}

/// Instances of conforming types are used in internal `String`
/// representation.
public // @testable
protocol _StringElement {
  static func _toUTF16CodeUnit(_: Self) -> UTF16.CodeUnit

  static func _fromUTF16CodeUnit(_ utf16: UTF16.CodeUnit) -> Self
}

extension UTF16.CodeUnit : _StringElement {
  public // @testable
  static func _toUTF16CodeUnit(_ x: UTF16.CodeUnit) -> UTF16.CodeUnit {
    return x
  }
  public // @testable
  static func _fromUTF16CodeUnit(
    _ utf16: UTF16.CodeUnit
  ) -> UTF16.CodeUnit {
    return utf16
  }
}

extension UTF8.CodeUnit : _StringElement {
  public // @testable
  static func _toUTF16CodeUnit(_ x: UTF8.CodeUnit) -> UTF16.CodeUnit {
    _sanityCheck(x <= 0x7f, "should only be doing this with ASCII")
    return UTF16.CodeUnit(extendingOrTruncating: x)
  }
  public // @testable
  static func _fromUTF16CodeUnit(
    _ utf16: UTF16.CodeUnit
  ) -> UTF8.CodeUnit {
    _sanityCheck(utf16 <= 0x7f, "should only be doing this with ASCII")
    return UTF8.CodeUnit(extendingOrTruncating: utf16)
  }
}

extension UTF16 {
  /// Returns the number of code units required to encode the given Unicode
  /// scalar.
  ///
  /// Because a Unicode scalar value can require up to 21 bits to store its
  /// value, some Unicode scalars are represented in UTF-16 by a pair of
  /// 16-bit code units. The first and second code units of the pair,
  /// designated *leading* and *trailing* surrogates, make up a *surrogate
  /// pair*.
  ///
  ///     let anA: Unicode.Scalar = "A"
  ///     print(anA.value)
  ///     // Prints "65"
  ///     print(UTF16.width(anA))
  ///     // Prints "1"
  ///
  ///     let anApple: Unicode.Scalar = "🍎"
  ///     print(anApple.value)
  ///     // Prints "127822"
  ///     print(UTF16.width(anApple))
  ///     // Prints "2"
  ///
  /// - Parameter x: A Unicode scalar value.
  /// - Returns: The width of `x` when encoded in UTF-16, either `1` or `2`.
  public static func width(_ x: Unicode.Scalar) -> Int {
    return x.value <= 0xFFFF ? 1 : 2
  }

  /// Returns the high-surrogate code unit of the surrogate pair representing
  /// the specified Unicode scalar.
  ///
  /// Because a Unicode scalar value can require up to 21 bits to store its
  /// value, some Unicode scalars are represented in UTF-16 by a pair of
  /// 16-bit code units. The first and second code units of the pair,
  /// designated *leading* and *trailing* surrogates, make up a *surrogate
  /// pair*.
  ///
  ///     let apple: Unicode.Scalar = "🍎"
  ///     print(UTF16.leadSurrogate(apple)
  ///     // Prints "55356"
  ///
  /// - Parameter x: A Unicode scalar value. `x` must be represented by a
  ///   surrogate pair when encoded in UTF-16. To check whether `x` is
  ///   represented by a surrogate pair, use `UTF16.width(x) == 2`.
  /// - Returns: The leading surrogate code unit of `x` when encoded in UTF-16.
  ///
  /// - SeeAlso: `UTF16.width(_:)`, `UTF16.trailSurrogate(_:)`
  public static func leadSurrogate(_ x: Unicode.Scalar) -> UTF16.CodeUnit {
    _precondition(width(x) == 2)
    return 0xD800 + UTF16.CodeUnit(extendingOrTruncating:
      (x.value - 0x1_0000) &>> (10 as UInt32))
  }

  /// Returns the low-surrogate code unit of the surrogate pair representing
  /// the specified Unicode scalar.
  ///
  /// Because a Unicode scalar value can require up to 21 bits to store its
  /// value, some Unicode scalars are represented in UTF-16 by a pair of
  /// 16-bit code units. The first and second code units of the pair,
  /// designated *leading* and *trailing* surrogates, make up a *surrogate
  /// pair*.
  ///
  ///     let apple: Unicode.Scalar = "🍎"
  ///     print(UTF16.trailSurrogate(apple)
  ///     // Prints "57166"
  ///
  /// - Parameter x: A Unicode scalar value. `x` must be represented by a
  ///   surrogate pair when encoded in UTF-16. To check whether `x` is
  ///   represented by a surrogate pair, use `UTF16.width(x) == 2`.
  /// - Returns: The trailing surrogate code unit of `x` when encoded in UTF-16.
  ///
  /// - SeeAlso: `UTF16.width(_:)`, `UTF16.leadSurrogate(_:)`
  public static func trailSurrogate(_ x: Unicode.Scalar) -> UTF16.CodeUnit {
    _precondition(width(x) == 2)
    return 0xDC00 + UTF16.CodeUnit(extendingOrTruncating:
      (x.value - 0x1_0000) & (((1 as UInt32) &<< 10) - 1))
  }

  /// Returns a Boolean value indicating whether the specified code unit is a
  /// high-surrogate code unit.
  ///
  /// Here's an example of checking whether each code unit in a string's
  /// `utf16` view is a lead surrogate. The `apple` string contains a single
  /// emoji character made up of a surrogate pair when encoded in UTF-16.
  ///
  ///     let apple = "🍎"
  ///     for unit in apple.utf16 {
  ///         print(UTF16.isLeadSurrogate(unit))
  ///     }
  ///     // Prints "true"
  ///     // Prints "false"
  ///
  /// This method does not validate the encoding of a UTF-16 sequence beyond
  /// the specified code unit. Specifically, it does not validate that a
  /// low-surrogate code unit follows `x`.
  ///
  /// - Parameter x: A UTF-16 code unit.
  /// - Returns: `true` if `x` is a high-surrogate code unit; otherwise,
  ///   `false`.
  ///
  /// - SeeAlso: `UTF16.width(_:)`, `UTF16.leadSurrogate(_:)`
  public static func isLeadSurrogate(_ x: CodeUnit) -> Bool {
    return 0xD800...0xDBFF ~= x
  }

  /// Returns a Boolean value indicating whether the specified code unit is a
  /// low-surrogate code unit.
  ///
  /// Here's an example of checking whether each code unit in a string's
  /// `utf16` view is a trailing surrogate. The `apple` string contains a
  /// single emoji character made up of a surrogate pair when encoded in
  /// UTF-16.
  ///
  ///     let apple = "🍎"
  ///     for unit in apple.utf16 {
  ///         print(UTF16.isTrailSurrogate(unit))
  ///     }
  ///     // Prints "false"
  ///     // Prints "true"
  ///
  /// This method does not validate the encoding of a UTF-16 sequence beyond
  /// the specified code unit. Specifically, it does not validate that a
  /// high-surrogate code unit precedes `x`.
  ///
  /// - Parameter x: A UTF-16 code unit.
  /// - Returns: `true` if `x` is a low-surrogate code unit; otherwise,
  ///   `false`.
  ///
  /// - SeeAlso: `UTF16.width(_:)`, `UTF16.leadSurrogate(_:)`
  public static func isTrailSurrogate(_ x: CodeUnit) -> Bool {
    return 0xDC00...0xDFFF ~= x
  }

  public // @testable
  static func _copy<T : _StringElement, U : _StringElement>(
    source: UnsafeMutablePointer<T>,
    destination: UnsafeMutablePointer<U>,
    count: Int
  ) {
    if MemoryLayout<T>.stride == MemoryLayout<U>.stride {
      _memcpy(
        dest: UnsafeMutablePointer(destination),
        src: UnsafeMutablePointer(source),
        size: UInt(count) * UInt(MemoryLayout<U>.stride))
    }
    else {
      for i in 0..<count {
        let u16 = T._toUTF16CodeUnit((source + i).pointee)
        (destination + i).pointee = U._fromUTF16CodeUnit(u16)
      }
    }
  }

  /// Returns the number of UTF-16 code units required for the given code unit
  /// sequence when transcoded to UTF-16, and a Boolean value indicating
  /// whether the sequence was found to contain only ASCII characters.
  ///
  /// The following example finds the length of the UTF-16 encoding of the
  /// string `"Fermata 𝄐"`, starting with its UTF-8 representation.
  ///
  ///     let fermata = "Fermata 𝄐"
  ///     let bytes = fermata.utf8
  ///     print(Array(bytes))
  ///     // Prints "[70, 101, 114, 109, 97, 116, 97, 32, 240, 157, 132, 144]"
  ///
  ///     let result = transcodedLength(of: bytes.makeIterator(),
  ///                                   decodedAs: UTF8.self,
  ///                                   repairingIllFormedSequences: false)
  ///     print(result)
  ///     // Prints "Optional((10, false))"
  ///
  /// - Parameters:
  ///   - input: An iterator of code units to be translated, encoded as
  ///     `sourceEncoding`. If `repairingIllFormedSequences` is `true`, the
  ///     entire iterator will be exhausted. Otherwise, iteration will stop if
  ///     an ill-formed sequence is detected.
  ///   - sourceEncoding: The Unicode encoding of `input`.
  ///   - repairingIllFormedSequences: Pass `true` to measure the length of
  ///     `input` even when `input` contains ill-formed sequences. Each
  ///     ill-formed sequence is replaced with a Unicode replacement character
  ///     (`"\u{FFFD}"`) and is measured as such. Pass `false` to immediately
  ///     stop measuring `input` when an ill-formed sequence is encountered.
  /// - Returns: A tuple containing the number of UTF-16 code units required to
  ///   encode `input` and a Boolean value that indicates whether the `input`
  ///   contained only ASCII characters. If `repairingIllFormedSequences` is
  ///   `false` and an ill-formed sequence is detected, this method returns
  ///   `nil`.
  public static func transcodedLength<
    Input : IteratorProtocol,
    Encoding : Unicode.Encoding
  >(
    of input: Input,
    decodedAs sourceEncoding: Encoding.Type,
    repairingIllFormedSequences: Bool
  ) -> (count: Int, isASCII: Bool)?
    where Encoding.CodeUnit == Input.Element {

    var i = input
    var isASCII = true
    var count = 0
    let errorCount = Encoding.ForwardParser._parse(
      &i, repairingIllFormedSequences: repairingIllFormedSequences
    ) {
      if isASCII {
        isASCII = Unicode.ASCII.transcode($0, from: Encoding.self) != nil
      }
      count += numericCast(self._transcode($0, from: Encoding.self).count)
    }
    
    if _fastPath(errorCount == 0 || repairingIllFormedSequences) {
      return (count: count, isASCII: isASCII)
    }
    else { return nil }
  }
}

// Unchecked init to avoid precondition branches in hot code paths where we
// already know the value is a valid unicode scalar.
extension Unicode.Scalar {
  /// Create an instance with numeric value `value`, bypassing the regular
  /// precondition checks for code point validity.
  @_versioned
  internal init(_unchecked value: UInt32) {
    _sanityCheck(value < 0xD800 || value > 0xDFFF,
      "high- and low-surrogate code points are not valid Unicode scalar values")
    _sanityCheck(value <= 0x10FFFF, "value is outside of Unicode codespace")

    self._value = value
  }
}

extension UnicodeCodec {
  public static func _nullCodeUnitOffset(in input: UnsafePointer<CodeUnit>) -> Int {
    var length = 0
    while input[length] != 0 {
      length += 1
    }
    return length
  }
}

@available(*, unavailable, renamed: "UnicodeCodec")
public typealias UnicodeCodecType = UnicodeCodec

extension UnicodeCodec {
  @available(*, unavailable, renamed: "encode(_:into:)")
  public static func encode(
    _ input: Unicode.Scalar,
    output put: (CodeUnit) -> Void
  ) {
    Builtin.unreachable()
  }
}

@available(*, unavailable, message: "use 'transcode(_:from:to:stoppingOnError:into:)'")
public func transcode<Input, InputEncoding, OutputEncoding>(
  _ inputEncoding: InputEncoding.Type, _ outputEncoding: OutputEncoding.Type,
  _ input: Input, _ output: (OutputEncoding.CodeUnit) -> Void,
  stopOnError: Bool
) -> Bool
  where
  Input : IteratorProtocol,
  InputEncoding : UnicodeCodec,
  OutputEncoding : UnicodeCodec,
  InputEncoding.CodeUnit == Input.Element {
  Builtin.unreachable()
}

extension UTF16 {
  @available(*, unavailable, message: "use 'transcodedLength(of:decodedAs:repairingIllFormedSequences:)'")
  public static func measure<Encoding, Input>(
    _: Encoding.Type, input: Input, repairIllFormedSequences: Bool
  ) -> (Int, Bool)?
    where
    Encoding : UnicodeCodec,
    Input : IteratorProtocol,
    Encoding.CodeUnit == Input.Element {
    Builtin.unreachable()
  }
}

/// A namespace for Unicode utilities.
public enum Unicode {}

