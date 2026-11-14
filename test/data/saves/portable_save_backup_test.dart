import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/data/saves/portable_save_backup.dart';

void main() {
  const passphrase = 'correct horse battery staple';

  test('portable backup round-trips with the GTN1 envelope prefix', () async {
    const payload = '{"formatVersion":2,"slot":"save-data"}';
    final encrypted = await PortableSaveBackup.encrypt(payload, passphrase);

    expect(encrypted, startsWith('GTNPORT1:'));
    expect(await PortableSaveBackup.decrypt(encrypted, passphrase), payload);
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
