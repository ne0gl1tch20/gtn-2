import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/data/saves/legacy_gtn1_save_codec.dart';
import 'package:gtn_2/data/saves/portable_save_backup.dart';

void main() {
  const passphrase = 'correct horse battery staple';

  test('portable backup round-trips with the GTN1 envelope prefix', () async {
    const payload = '{"formatVersion":2,"slot":"save-data"}';
    final encrypted = await PortableSaveBackup.encrypt(payload, passphrase);

    expect(encrypted, startsWith('GTNPORT1:'));
    expect(await PortableSaveBackup.decrypt(encrypted, passphrase), payload);
  });

  test('decrypts a fixed vector from the pinned GTN1 envelope parameters', () async {
    const fixture =
        'GTNPORT1:AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGz7LWHAMisH/x7aX3zDHvENWzMQx6uMa1fp6boYc8/Em8ANESoiKRoXsvyu2X4Pr4M5Sc6o5r9tYLWpqNEnAe1mmWXHsD7qTT8EWqD1Sg50EQa57yBwCC33tyiDZZPYDeDvSzsXJ2ZNx9RLNUtOIzHVs2nECtkzh';
    const payload =
        '{"formatVersion":3,"appPreferencesJson":"{}","activeSlot":1,"slots":{},"backups":{},"creativeSlots":{}}';

    expect(await PortableSaveBackup.decrypt(fixture, passphrase), payload);
  });

  test('matches the pinned GTN1 XOR/Base64 inner payload vector', () {
    const payload = '{"formatVersion":2,"slot":"legacy"}';
    const fixture =
        'R1ROX0VOQ18yMDI1XzlgJC0wLyM2FCcwMSstLGB4cG5gMS4tNmB4YC4nJSMhO2A/';

    expect(LegacyGtn1SaveCodec.encode(payload), fixture);
    expect(LegacyGtn1SaveCodec.decode(fixture), payload);
  });

  test(
    'accepts GTN1 plain-Base64 legacy fallback and rejects malformed input',
    () {
      const plain = 'eyJmb3JtYXRWZXJzaW9uIjoyfQ==';
      expect(LegacyGtn1SaveCodec.decode(plain), '{"formatVersion":2}');
      expect(LegacyGtn1SaveCodec.decode('not-base64!'), isNull);
    },
  );

  test('decrypts a pinned GTN1 two-layer portable backup fixture', () async {
    const fixture =
        'GTNPORT1:AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxfYbFAm1/bEwOLd1RTsm1A0hYR0wdBa8sRmRdEo1fwy2CN9TaujJoutk2PzOtvD+v9RRKEggNdbRSkscCHJUn+feWOlLY/XCuwj8jFFnq9MMoFflnAiGkrA13mdWO0HYC3MrYf+zd5xLPqH6JQJlUjMVTjfwAmP71EhEmb/usltsYhT5gBTbuiHMFBgmJOO0HjYMTHDJX0mmtuxwwOhl4Vachs1s+43l0PW4PI';
    const payload =
        '{"formatVersion":3,"appPreferencesJson":"{}","activeSlot":2,'
        '"slots":{},"backups":{},"creativeSlots":{}}';

    expect(
      await PortableSaveBackup.decryptGtn1Payload(fixture, passphrase),
      payload,
    );
  });

  test('round-trips the two-layer GTN1 portable backup format', () async {
    const payload =
        '{"formatVersion":3,"appPreferencesJson":"{}","activeSlot":2,'
        '"slots":{},"backups":{},"creativeSlots":{}}';
    final encrypted = await PortableSaveBackup.encryptGtn1Payload(
      payload,
      passphrase,
    );

    expect(
      await PortableSaveBackup.decryptGtn1Payload(encrypted, passphrase),
      payload,
    );
    expect(
      await PortableSaveBackup.decryptGtn1Payload(
        encrypted,
        'another incorrect passphrase',
      ),
      isNull,
    );
  });

  test('wrong passphrase and tampered ciphertext are rejected', () async {
    final encrypted = await PortableSaveBackup.encrypt(
      'private-save',
      passphrase,
    );
    expect(
      await PortableSaveBackup.decrypt(
        encrypted,
        'another incorrect passphrase',
      ),
      isNull,
    );

    final encoded = encrypted.substring(PortableSaveBackup.prefix.length);
    final changed = encoded.split('');
    final index = changed.length ~/ 2;
    changed[index] = changed[index] == 'A' ? 'B' : 'A';
    expect(
      await PortableSaveBackup.decrypt(
        '${PortableSaveBackup.prefix}${changed.join()}',
        passphrase,
      ),
      isNull,
    );
  });

  test(
    'malformed and unknown GTNPORT versions are classified as portable',
    () async {
      expect(
        PortableSaveBackup.isPortableFormat('GTNPORT2:not-a-backup'),
        isTrue,
      );
      expect(
        await PortableSaveBackup.decrypt('GTNPORT2:not-a-backup', passphrase),
        isNull,
      );
      expect(
        await PortableSaveBackup.decrypt(
          '${PortableSaveBackup.prefix}not-base64!',
          passphrase,
        ),
        isNull,
      );
    },
  );

  test('short passphrases are rejected', () async {
    expect(PortableSaveBackup.encrypt('payload', 'short'), throwsArgumentError);
  });
}
