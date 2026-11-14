import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/profile/player_profile_page.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('profile JSON preserves GTN1 identity and setup completion', () {
    final profile = PlayerProfile.fromJson({
      'username': 'Player One',
      'bio': 'Offline player',
      'avatarId': 'star',
      'profileId': 'profile-123',
      'setupComplete': true,
    });

    expect(profile.profileId, 'profile-123');
    expect(profile.setupComplete, isTrue);
    expect(PlayerProfile.fromJson(profile.toJson()).profileId, 'profile-123');
  });

  test('profile JSON keeps the app-private custom avatar path', () {
    final profile = PlayerProfile.fromJson({
      'username': 'Player One',
      'avatarId': 'custom',
      'customAvatarPath': '/app/documents/player-profile-avatars/avatar.png',
      'profileId': 'profile-456',
      'setupComplete': true,
    });

    expect(profile.customAvatarPath, contains('player-profile-avatars'));
    expect(profile.toJson()['customAvatarPath'], profile.customAvatarPath);
  });

  test(
    'legacy profile data receives a stable identity and completed setup',
    () {
      final profile = PlayerProfile.fromJson({
        'username': 'Legacy Player',
        'bio': '',
        'avatarId': 'star',
      });

      expect(profile.profileId, isNotEmpty);
      expect(profile.setupComplete, isTrue);
    },
  );

  test(
    'profile store persists and reloads identity and custom avatar path',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      final directory = await Directory.systemTemp.createTemp(
        'gtn-profile-test-',
      );
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getApplicationDocumentsDirectory') {
          return directory.path;
        }
        return null;
      });
      addTearDown(() async {
        messenger.setMockMethodCallHandler(channel, null);
        await directory.delete(recursive: true);
      });

      final store = PlayerProfileStore();
      final avatar = await store.importCustomAvatar(
        Uint8List.fromList([1, 2, 3, 4]),
        'png',
      );
      final profile = PlayerProfile(
        username: 'Player One',
        bio: 'Offline player',
        avatarId: 'custom',
        customAvatarPath: avatar,
        profileId: 'profile-persisted',
        setupComplete: true,
      );

      await store.save(profile);
      final restored = await store.load();

      expect(restored.profileId, 'profile-persisted');
      expect(restored.username, 'Player One');
      expect(restored.bio, 'Offline player');
      expect(restored.setupComplete, isTrue);
      expect(restored.customAvatarPath, avatar);
      expect(await File(avatar).exists(), isTrue);
    },
  );

  testWidgets('first launch opens the required profile creation flow', (
    tester,
  ) async {
    await tester.pumpWidget(
      M3EMaterialApp(
        data: M3EThemeData.light(seedColor: const Color(0xFF7C5CFC)),
        fontFamily: 'Manrope',
        autoTheming: false,
        initialTheme: Brightness.dark,
        home: PlayerProfilePage(
          initialProfile: const PlayerProfile(
            profileId: 'new-profile',
            setupComplete: false,
          ),
          store: PlayerProfileStore(),
          firstLaunch: true,
          viewOnly: false,
          onSaved: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Create your profile'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Create profile & continue'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Create profile & continue'), findsOneWidget);
    expect(find.byTooltip('Back'), findsNothing);
    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets(
    'completed profile opens read-only and has a separate edit action',
    (tester) async {
      final profile = PlayerProfile(
        username: 'Player One',
        bio: 'Offline player',
        profileId: 'profile-123',
        setupComplete: true,
      );

      await tester.pumpWidget(
        M3EMaterialApp(
          data: M3EThemeData.light(seedColor: const Color(0xFF7C5CFC)),
          fontFamily: 'Manrope',
          autoTheming: false,
          initialTheme: Brightness.dark,
          home: PlayerProfilePage(
            initialProfile: profile,
            store: PlayerProfileStore(),
            onSaved: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Player One'), findsOneWidget);
      expect(find.text('Offline player'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      await tester.tap(find.text('Edit profile'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNWidgets(2));
      await tester.scrollUntilVisible(
        find.text('Save profile'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Save profile'), findsOneWidget);
    },
  );
}
