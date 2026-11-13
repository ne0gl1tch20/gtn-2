import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

class PlayerProfile {
  const PlayerProfile({
    this.username = '',
    this.bio = '',
    this.avatarId = 'star',
    this.customAvatarData,
  });

  final String username;
  final String bio;
  final String avatarId;
  final String? customAvatarData;

  PlayerProfile copyWith({
    String? username,
    String? bio,
    String? avatarId,
    String? customAvatarData,
    bool clearCustomAvatar = false,
  }) => PlayerProfile(
    username: username ?? this.username,
    bio: bio ?? this.bio,
    avatarId: avatarId ?? this.avatarId,
    customAvatarData: clearCustomAvatar
        ? null
        : customAvatarData ?? this.customAvatarData,
  );

  Map<String, Object?> toJson() => {
    'schemaVersion': 1,
    'username': username,
    'bio': bio,
    'avatarId': avatarId,
    'customAvatarData': customAvatarData,
  };

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    final username = json['username'] ?? '';
    final bio = json['bio'] ?? '';
    final avatarId = json['avatarId'] ?? 'star';
    final customAvatarData = json['customAvatarData'];
    if (username is! String ||
        username.length > 20 ||
        bio is! String ||
        bio.length > 120 ||
        avatarId is! String ||
        (!avatarPresets.containsKey(avatarId) && avatarId != 'custom') ||
        customAvatarData != null &&
            (customAvatarData is! String ||
                !customAvatarData.startsWith('data:image/'))) {
      throw const FormatException('Invalid player profile.');
    }
    return PlayerProfile(
      username: username,
      bio: bio,
      avatarId: avatarId,
      customAvatarData: customAvatarData as String?,
    );
  }
}

const avatarPresets = <String, String>{
  'star': '⭐',
  'cat': '🐱',
  'fox': '🦊',
  'dog': '🐶',
  'robot': '🤖',
  'ghost': '👻',
  'dragon': '🐉',
  'alien': '👽',
  'rocket': '🚀',
  'crown': '👑',
  'gem': '💎',
  'controller': '🎮',
  'moon': '🌙',
  'sun': '☀️',
  'flower': '🌸',
  'lightning': '⚡',
};

class PlayerProfileStore {
  Future<File> get _file async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/gtn2-player-profile.json');
  }

  Future<PlayerProfile> load() async {
    final file = await _file;
    if (!await file.exists()) return const PlayerProfile();
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic> || decoded['schemaVersion'] != 1) {
        return const PlayerProfile();
      }
      return PlayerProfile.fromJson(decoded);
    } on FormatException {
      return const PlayerProfile();
    }
  }

  Future<void> save(PlayerProfile profile) async {
    final file = await _file;
    await file.parent.create(recursive: true);
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(jsonEncode(profile.toJson()), flush: true);
    await temporary.rename(file.path);
  }
}

class PlayerProfilePage extends StatefulWidget {
  const PlayerProfilePage({
    super.key,
    required this.initialProfile,
    required this.store,
    required this.onSaved,
    this.equippedCosmeticId,
  });

  final PlayerProfile initialProfile;
  final PlayerProfileStore store;
  final ValueChanged<PlayerProfile> onSaved;
  final String? equippedCosmeticId;

  @override
  State<PlayerProfilePage> createState() => _PlayerProfilePageState();
}

class _PlayerProfilePageState extends State<PlayerProfilePage> {
  late final TextEditingController _username = TextEditingController(
    text: widget.initialProfile.username,
  );
  late final TextEditingController _bio = TextEditingController(
    text: widget.initialProfile.bio,
  );
  late String _avatarId = widget.initialProfile.avatarId;
  late String? _customAvatarData = widget.initialProfile.customAvatarData;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _choosePicture() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty || bytes.length > 4 * 1024 * 1024) {
      setState(() => _error = 'Choose an image smaller than 4 MB.');
      return;
    }
    final extension = (file.extension ?? '').toLowerCase();
    final mime = switch (extension) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => null,
    };
    if (mime == null) {
      setState(() => _error = 'Use a PNG, JPG, WEBP or GIF image.');
      return;
    }
    setState(() {
      _customAvatarData = 'data:$mime;base64,${base64Encode(bytes)}';
      _avatarId = 'custom';
      _error = null;
    });
  }

  Future<void> _save() async {
    final username = _username.text.trim();
    if (username.length < 2 || username.length > 20) {
      setState(() => _error = 'Username must be 2–20 characters.');
      return;
    }
    if (username.runes.any((rune) => rune < 32 || rune == 127)) {
      setState(() => _error = 'Please choose a different username.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final profile = PlayerProfile(
      username: username,
      bio: _bio.text.trim(),
      avatarId: _avatarId,
      customAvatarData: _customAvatarData,
    );
    try {
      await widget.store.save(profile);
      if (!mounted) return;
      widget.onSaved(profile);
      Navigator.of(context).pop();
    } on Exception {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save your profile. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileImage = _avatarId == 'custom' && _customAvatarData != null
        ? Image.memory(
            base64Decode(_customAvatarData!.split(',').last),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const Icon(Icons.person_rounded),
          )
        : Text(
            avatarPresets[_avatarId] ?? '⭐',
            style: const TextStyle(fontSize: 48),
          );

    return Scaffold(
      appBar: AppBar(title: const Text('Player profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: widget.equippedCosmeticId == 'cosmetic_nebula_ring'
                      ? Border.all(color: theme.colorScheme.primary, width: 4)
                      : null,
                  boxShadow: widget.equippedCosmeticId == 'cosmetic_pixel_glow'
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.tertiary.withValues(alpha: 0.65),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      child: ClipOval(
                        child: SizedBox(
                          width: 112,
                          height: 112,
                          child: Center(child: profileImage),
                        ),
                      ),
                    ),
                    if (widget.equippedCosmeticId == 'cosmetic_starfield')
                      Positioned(
                        right: -3,
                        bottom: -3,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(7),
                            child: Icon(Icons.auto_awesome_rounded, size: 20),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: _saving ? null : _choosePicture,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Choose a picture'),
              ),
            ),
            const SizedBox(height: 12),
            Text('Choose an avatar', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in avatarPresets.entries)
                  ChoiceChip(
                    label: Text(
                      entry.value,
                      style: const TextStyle(fontSize: 22),
                    ),
                    selected: _avatarId == entry.key,
                    onSelected: _saving
                        ? null
                        : (_) => setState(() {
                            _avatarId = entry.key;
                            _customAvatarData = null;
                          }),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _username,
              maxLength: 20,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Username',
                helperText: '2–20 characters',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bio,
              maxLength: 120,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Bio (optional)',
                hintText: 'A little about you',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save profile'),
            ),
          ],
        ),
      ),
    );
  }
}
