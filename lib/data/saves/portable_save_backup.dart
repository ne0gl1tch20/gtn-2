import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// GTN1-compatible portable backup envelope.
///
/// The envelope is:
/// `GTNPORT1:` + Base64(salt[16] || nonce[12] || ciphertext || tag[16]).
/// The key uses PBKDF2-HMAC-SHA256 (310,000 iterations, 256 bits) and AES-256-GCM.
class PortableSaveBackup {
  PortableSaveBackup._();

  static const prefix = 'GTNPORT1:';
  static const minPassphraseLength = 12;
  static const _aad = 'GuessTheNumber/portable-save/v1';
  static const _saltLength = 16;
  static const _nonceLength = 12;
  static const _tagLength = 16;
  static const _iterations = 310000;

  static final _kdf = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: _iterations,
    bits: 256,
  );
  static final _cipher = AesGcm.with256bits();

  static bool isPortableFormat(String input) => input.startsWith('GTNPORT');

  static Future<String> encrypt(String payload, String passphrase) async {
    if (passphrase.length < minPassphraseLength) {
      throw ArgumentError('Passphrase must be at least $minPassphraseLength characters.');
    }

    final random = Random.secure();
    final salt = Uint8List.fromList(
      List<int>.generate(_saltLength, (_) => random.nextInt(256)),
    );
    final nonce = Uint8List.fromList(
      List<int>.generate(_nonceLength, (_) => random.nextInt(256)),
    );
    final passwordBytes = _passwordBytes(passphrase);
    try {
      final key = await _kdf.deriveKey(
        secretKey: SecretKey(passwordBytes),
        nonce: salt,
      );
      final box = await _cipher.encrypt(
        utf8.encode(payload),
        secretKey: key,
        nonce: nonce,
        aad: utf8.encode(_aad),
      );
      final envelope = Uint8List(
        salt.length + nonce.length + box.cipherText.length + box.mac.bytes.length,
      );
      var offset = 0;
      envelope.setRange(offset, offset + salt.length, salt);
      offset += salt.length;
      envelope.setRange(offset, offset + nonce.length, nonce);
      offset += nonce.length;
      envelope.setRange(offset, offset + box.cipherText.length, box.cipherText);
      offset += box.cipherText.length;
      envelope.setRange(offset, envelope.length, box.mac.bytes);
      return '$prefix${base64.encode(envelope).replaceAll('=', '')}';
    } finally {
      passwordBytes.fillRange(0, passwordBytes.length, 0);
    }
  }

  static Future<String?> decrypt(String input, String passphrase) async {
    if (!input.startsWith(prefix) || passphrase.length < minPassphraseLength) {
      return null;
    }

    final passwordBytes = _passwordBytes(passphrase);
    try {
      final encoded = input.substring(prefix.length);
      final envelope = base64.decode(base64.normalize(encoded));
      if (envelope.length <= _saltLength + _nonceLength + _tagLength) {
        return null;
      }
      final salt = envelope.sublist(0, _saltLength);
      final nonce = envelope.sublist(_saltLength, _saltLength + _nonceLength);
      final tagStart = envelope.length - _tagLength;
      final ciphertext = envelope.sublist(_saltLength + _nonceLength, tagStart);
      final tag = envelope.sublist(tagStart);
      final key = await _kdf.deriveKey(
        secretKey: SecretKey(passwordBytes),
        nonce: salt,
      );
      final cleartext = await _cipher.decrypt(
        SecretBox(
          ciphertext,
          nonce: nonce,
          mac: Mac(tag),
        ),
        secretKey: key,
        aad: utf8.encode(_aad),
      );
      return utf8.decode(cleartext);
    } on FormatException {
      return null;
    } on SecretBoxAuthenticationError {
      return null;
    } on ArgumentError {
      return null;
    } finally {
      passwordBytes.fillRange(0, passwordBytes.length, 0);
    }
  }

  // Java's PBEKeySpec uses the low byte of each UTF-16 code unit for the
  // PBKDF2 password input. Keeping that conversion preserves GTN1's envelope.
  static Uint8List _passwordBytes(String passphrase) =>
      Uint8List.fromList(passphrase.codeUnits.map((unit) => unit & 0xff).toList());
}
