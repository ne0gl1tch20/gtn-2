import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

class PlayerProfile {
  const PlayerProfile({
    this.username = '',
    this.bio = '',
    this.avatarId = 'star',
    this.customAvatarPath,
    this.customAvatarData,
    this.profileId = '',
    this.setupComplete = false,
  });

  final String username;
  final String bio;
  final String avatarId;
  final String? customAvatarPath;
  // Read only for migration from early GTN2 builds; new saves use app-private files.
  final String? customAvatarData;
  final String profileId;
  final bool setupComplete;

  PlayerProfile copyWith({
    String? username,
    String? bio,
    String? avatarId,
    String? customAvatarPath,
    String? customAvatarData,
    bool clearCustomAvatar = false,
    String? profileId,
    bool? setupComplete,
  }) => PlayerProfile(
    username: username ?? this.username,
    bio: bio ?? this.bio,
    avatarId: avatarId ?? this.avatarId,
    customAvatarPath: clearCustomAvatar
        ? null
        : customAvatarPath ?? this.customAvatarPath,
    customAvatarData: clearCustomAvatar
        ? null
        : customAvatarData ?? this.customAvatarData,
    profileId: profileId ?? this.profileId,
    setupComplete: setupComplete ?? this.setupComplete,
  );

  Map<String, Object?> toJson() => {
    'schemaVersion': 1,
    'username': username,
    'bio': bio,
    'avatarId': avatarId,
    'customAvatarPath': customAvatarPath,
    'profileId': profileId,
    'setupComplete': setupComplete,
  };

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    final username = json['username'] ?? '';
    final bio = json['bio'] ?? '';
    final avatarId = json['avatarId'] ?? 'star';
    final customAvatarPath = json['customAvatarPath'];
    final customAvatarData = json['customAvatarData'];
    final profileId = json['profileId'];
    final setupComplete = json['setupComplete'];
    if (username is! String ||
        username.length > 20 ||
        bio is! String ||
        bio.length > 120 ||
        avatarId is! String ||
        (!avatarPresets.containsKey(avatarId) && avatarId != 'custom') ||
        customAvatarPath != null &&
            (customAvatarPath is! String || customAvatarPath.length > 2048) ||
        customAvatarData != null &&
            (customAvatarData is! String ||
                !customAvatarData.startsWith('data:image/')) ||
        profileId != null && profileId is! String ||
        setupComplete != null && setupComplete is! bool) {
      throw const FormatException('Invalid player profile.');
    }
    return PlayerProfile(
      username: username,
      bio: bio,
      avatarId: avatarId,
      customAvatarPath: customAvatarPath as String?,
      customAvatarData: customAvatarData as String?,
      profileId: (profileId as String?)?.isNotEmpty == true
          ? profileId as String
          : _newProfileId(),
      setupComplete: setupComplete as bool? ?? username.isNotEmpty,
    );
  }
}

String _newProfileId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((value) => value.toRadixString(16).padLeft(2, '0'));
  final value = hex.join();
  return '${value.substring(0, 8)}-${value.substring(8, 12)}-${value.substring(12, 16)}-${value.substring(16, 20)}-${value.substring(20)}';
}

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
      var profile = PlayerProfile.fromJson(decoded);
      final directory = await getApplicationDocumentsDirectory();
      final avatarPath = profile.customAvatarPath;
      if (avatarPath != null &&
          !avatarPath.startsWith('${directory.path}${Platform.pathSeparator}')) {
        profile = profile.copyWith(clearCustomAvatar: true, avatarId: 'star');
      }
      if (profile.customAvatarData != null) {
        profile = await save(profile);
      }
      return profile;
    } on FormatException {
      return const PlayerProfile();
    }
  }

  Future<PlayerProfile> save(PlayerProfile profile) async {
    final directory = await getApplicationDocumentsDirectory();
    final identity = profile.profileId.isNotEmpty
        ? profile.profileId
        : _newProfileId();
    var persisted = profile.copyWith(profileId: identity);
    final legacyData = persisted.customAvatarData;
    if (legacyData != null) {
      final comma = legacyData.indexOf(',');
      if (comma < 0) throw const FormatException('Invalid custom avatar data.');
      final header = legacyData.substring(0, comma).toLowerCase();
      final extension = header.contains('image/png')
          ? 'png'
          : header.contains('image/jpeg')
          ? 'jpg'
          : header.contains('image/webp')
          ? 'webp'
          : header.contains('image/gif')
          ? 'gif'
          : null;
      if (extension == null) {
        throw const FormatException('Unsupported custom avatar format.');
      }
      final bytes = base64Decode(legacyData.substring(comma + 1));
      if (bytes.isEmpty || bytes.length > 4 * 1024 * 1024) {
        throw const FormatException('Custom avatar must be smaller than 4 MB.');
      }
      final avatarDirectory = Directory(
        '${directory.path}${Platform.pathSeparator}player-profile-avatars',
      );
      await avatarDirectory.create(recursive: true);
      final avatarFile = File(
        '${avatarDirectory.path}${Platform.pathSeparator}profile_${identity}.${extension}',
      );
      await avatarFile.writeAsBytes(bytes, flush: true);
      persisted = persisted.copyWith(
        customAvatarPath: avatarFile.path,
        clearCustomAvatar: true,
      );
    }
    final file = await _file;
    await file.parent.create(recursive: true);
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(jsonEncode(persisted.toJson()), flush: true);
    await temporary.rename(file.path);
    return persisted;
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
    this.viewOnly = true,
    this.firstLaunch = false,
  });

  final PlayerProfile initialProfile;
  final PlayerProfileStore store;
  final ValueChanged<PlayerProfile> onSaved;
  final String? equippedCosmeticId;
  final bool viewOnly;
  final bool firstLaunch;

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
  late String? _customAvatarPath = widget.initialProfile.customAvatarPath;
  late String? _customAvatarData = widget.initialProfile.customAvatarData;
  bool _saving = false;
  late bool _editing =
      widget.firstLaunch ||
      !widget.viewOnly ||
      !widget.initialProfile.setupComplete;
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
      _customAvatarPath = null;
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
      customAvatarPath: _customAvatarPath,
      customAvatarData: _customAvatarData,
      profileId: widget.initialProfile.profileId.isNotEmpty
          ? widget.initialProfile.profileId
          : _newProfileId(),
      setupComplete: true,
    );
    try {
      final savedProfile = await widget.store.save(profile);
      if (!mounted) return;
      widget.onSaved(savedProfile);
      if (widget.firstLaunch) {
        setState(() => _editing = false);
      } else {
        Navigator.of(context).pop();
      }
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
    final profileImage = _avatarId == 'custom' && _customAvatarPath != null
        ? Image.file(
            File(_customAvatarPath!),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const Icon(Icons.person_rounded),
          )
        : _avatarId == 'custom' && _customAvatarData != null
        ? Image.memory(
            base64Decode(_customAvatarData!.split(',').last),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const Icon(Icons.person_rounded),
          )
        : Text(
            avatarPresets[_avatarId] ?? '⭐',
            style: const TextStyle(fontSize: 48),
          );

    if (!_editing) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Player profile'),
          leading: IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            children: [
              Center(
                child: CircleAvatar(
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
              ),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  widget.initialProfile.username,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Offline player profile',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Bio',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.initialProfile.bio.isEmpty
                    ? 'No bio yet. Add a little introduction about yourself.'
                    : widget.initialProfile.bio,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: widget.initialProfile.bio.isEmpty
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: () => setState(() => _editing = true),
                child: const Text('Edit profile'),
              ),
            ],
          ),
        ),
      );
    }

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
                            color: theme.colorScheme.tertiary.withValues(
                              alpha: 0.65,
                            ),
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
                            _customAvatarPath = null;
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
