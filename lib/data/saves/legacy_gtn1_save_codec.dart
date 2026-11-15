import 'dart:convert';

/// Reproduces the legacy inner payload wrapper used by GTN1 SaveManager.
///
/// GTN1 wraps the serialized save bundle with a fixed salt, XOR byte 0x42
/// and Base64 before the optional GTNPORT1 passphrase envelope is applied.
/// This is compatibility obfuscation, not encryption. New portable backups
/// must still use [PortableSaveBackup].
class LegacyGtn1SaveCodec {
  LegacyGtn1SaveCodec._();

  static const _salt = 'GTN_ENC_2025_';
  static const _xorKey = 0x42;

  /// Decodes a GTN1 legacy payload, including the plain-Base64 fallback that
  /// the pinned source importer accepts.
  static String? decode(String input) {
    try {
      final decoded = base64.decode(input);
      final salt = ascii.encode(_salt);
      if (decoded.length <= salt.length) return null;

      var hasSalt = true;
      for (var index = 0; index < salt.length; index++) {
        if (decoded[index] != salt[index]) {
          hasSalt = false;
          break;
        }
      }

      if (!hasSalt) {
        return utf8.decode(decoded, allowMalformed: true);
      }

      final payload = decoded
          .skip(salt.length)
          .map((byte) => byte ^ _xorKey)
          .toList(growable: false);
      return utf8.decode(payload, allowMalformed: true);
    } on FormatException {
      return null;
    }
  }

  /// Encodes the exact legacy wrapper for cross-version fixture generation.
  /// Production exports should use the modern GTNPORT1 encryption envelope.
  static String encode(String payload) {
    final bytes = utf8.encode(payload);
    final salt = ascii.encode(_salt);
    final wrapped = <int>[
      ...salt,
      for (final byte in bytes) byte ^ _xorKey,
    ];
    return base64.encode(wrapped);
  }
}
