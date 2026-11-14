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
      expect(find.text('Save profile'), findsOneWidget);
    },
  );
}
