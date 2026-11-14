import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

class PlayerProfile {
  const PlayerProfile({
    this.username = '',
    this.bio = '',
    this.avatarId = 'star',
    this.customAvatarData,
    this.customAvatarPath,
    this.profileId = '',
    this.setupComplete = false,
  });

  final String username;
  final String bio;
  final String avatarId;
  final String? customAvatarData;
  final String? customAvatarPath;
  final String profileId;
  final bool setupComplete;

  static String generateId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((value) => value.toRadixString(16).padLeft(2, '0'));
    final value = hex.join();
    return '${value.substring(0, 8)}-${value.substring(8, 12)}-${value.substring(12, 16)}-${value.substring(16, 20)}-${value.substring(20)}';
  }

  PlayerProfile copyWith({
    String? username,
    String? bio,
    String? avatarId,
    String? customAvatarData,
    String? customAvatarPath,
    String? profileId,
    bool? setupComplete,
    bool clearCustomAvatar = false,
    bool clearCustomAvatarData = false,
  }) {
    return PlayerProfile(
      username: username ?? this.username,
      bio: bio ?? this.bio,
      avatarId: avatarId ?? this.avatarId,
      customAvatarData: clearCustomAvatar || clearCustomAvatarData
          ? null
          : customAvatarData ?? this.customAvatarData,
      customAvatarPath: clearCustomAvatar
          ? null
          : customAvatarPath ?? this.customAvatarPath,
      profileId: profileId ?? this.profileId,
      setupComplete: setupComplete ?? this.setupComplete,
    );
  }

  Map<String, Object?> toJson() => {
    'schemaVersion': 2,
    'username': username,
    'bio': bio,
    'avatarId': avatarId,
    'customAvatarPath': customAvatarPath,
    if (customAvatarData != null) 'customAvatarData': customAvatarData,
    'profileId': profileId,
    'setupComplete': setupComplete,
  };

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    final username = json['username'] ?? '';
    final bio = json['bio'] ?? '';
    final avatarId = json['avatarId'] ?? 'star';
    final customAvatarData = json['customAvatarData'];
    final customAvatarPath = json['customAvatarPath'];
    final profileId = json['profileId'] ?? '';
    final setupComplete =
        json['setupComplete'] ?? (username is String && username.isNotEmpty);
    if (username is! String ||
        username.length > 20 ||
        bio is! String ||
        bio.length > 120 ||
        avatarId is! String ||
        (!avatarPresets.containsKey(avatarId) && avatarId != 'custom') ||
        customAvatarData != null &&
            (customAvatarData is! String ||
                !customAvatarData.startsWith('data:image/')) ||
        customAvatarPath != null && customAvatarPath is! String ||
        profileId is! String ||
        profileId.length > 80 ||
        setupComplete is! bool) {
      throw const FormatException('Invalid player profile.');
    }
    return PlayerProfile(
      username: username,
      bio: bio,
      avatarId: avatarId,
      customAvatarData: customAvatarData as String?,
      customAvatarPath: customAvatarPath as String?,
      profileId: profileId.isEmpty ? generateId() : profileId,
      setupComplete: setupComplete,
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

  Future<String> importCustomAvatar(Uint8List bytes, String extension) async {
    final directory = await getApplicationDocumentsDirectory();
    final safeExtension = extension.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    final fileName =
        'player_profile_avatar_${DateTime.now().microsecondsSinceEpoch}.${safeExtension.isEmpty ? 'img' : safeExtension}';
    final file = File('${directory.path}/$fileName');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<PlayerProfile> load() async {
    final file = await _file;
    if (!await file.exists()) {
      return PlayerProfile(profileId: PlayerProfile.generateId());
    }
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic> ||
          (decoded['schemaVersion'] != 1 && decoded['schemaVersion'] != 2)) {
        return PlayerProfile(profileId: PlayerProfile.generateId());
      }
      var profile = PlayerProfile.fromJson(decoded);
      final documents = await getApplicationDocumentsDirectory();
      final avatarPath = profile.customAvatarPath;
      if (avatarPath != null) {
        final privateRoot = '${documents.path}${Platform.pathSeparator}';
        final avatarFile = File(avatarPath);
        if (!avatarPath.startsWith(privateRoot) || !await avatarFile.exists()) {
          profile = profile.copyWith(clearCustomAvatar: true, avatarId: 'star');
          await save(profile);
        }
      }
      final legacyData = profile.customAvatarData;
      if (legacyData != null && profile.customAvatarPath == null) {
        final parts = legacyData.split(',');
        if (parts.length == 2) {
          final mime = legacyData.substring(5, legacyData.indexOf(';'));
          final extension = switch (mime) {
            'image/png' => 'png',
            'image/jpeg' => 'jpg',
            'image/webp' => 'webp',
            'image/gif' => 'gif',
            _ => 'img',
          };
          try {
            final path = await importCustomAvatar(
              base64Decode(parts.last),
              extension,
            );
            profile = profile.copyWith(
              customAvatarPath: path,
              clearCustomAvatarData: true,
            );
            await save(profile);
          } on Object {
            // Keep the legacy data URI if migration cannot complete.
          }
        }
      }
      return profile;
    } on FormatException {
      return PlayerProfile(profileId: PlayerProfile.generateId());
    } on FileSystemException {
      return PlayerProfile(profileId: PlayerProfile.generateId());
    }
  }

  Future<PlayerProfile> save(PlayerProfile profile) async {
    final file = await _file;
    await file.parent.create(recursive: true);
    final saved = profile.profileId.isEmpty
        ? profile.copyWith(profileId: PlayerProfile.generateId())
        : profile;
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(jsonEncode(saved.toJson()), flush: true);
    await temporary.rename(file.path);
    return saved;
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
  late PlayerProfile _profile = widget.initialProfile;
  late final TextEditingController _username = TextEditingController(
    text: _profile.username,
  );
  late final TextEditingController _bio = TextEditingController(
    text: _profile.bio,
  );
  late String _avatarId = _profile.avatarId;
  late String? _customAvatarData = _profile.customAvatarData;
  late String? _customAvatarPath = _profile.customAvatarPath;
  bool _saving = false;
  late bool _editing =
      widget.firstLaunch ||
      !widget.viewOnly ||
      !widget.initialProfile.setupComplete;
  String? _error;

  @override
  void didUpdateWidget(covariant PlayerProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialProfile != widget.initialProfile) {
      _profile = widget.initialProfile;
      _username.text = _profile.username;
      _bio.text = _profile.bio;
      _avatarId = _profile.avatarId;
      _customAvatarData = _profile.customAvatarData;
      _customAvatarPath = _profile.customAvatarPath;
    }
  }

  @override
  void dispose() {
    _username.dispose();
    _bio.dispose();
    super.dispose();
  }

  Widget _avatarImage() {
    if (_avatarId == 'custom' && _customAvatarPath != null) {
      return Image.file(
        File(_customAvatarPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(Icons.person_rounded),
      );
    }
    if (_avatarId == 'custom' && _customAvatarData != null) {
      return Image.memory(
        base64Decode(_customAvatarData!.split(',').last),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(Icons.person_rounded),
      );
    }
    return Text(
      avatarPresets[_avatarId] ?? '⭐',
      style: const TextStyle(fontSize: 48),
    );
  }

  Widget _profileAvatar(PlayerProfile profile) {
    if (profile.avatarId == 'custom' && profile.customAvatarPath != null) {
      return Image.file(
        File(profile.customAvatarPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(Icons.person_rounded),
      );
    }
    if (profile.avatarId == 'custom' && profile.customAvatarData != null) {
      return Image.memory(
        base64Decode(profile.customAvatarData!.split(',').last),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(Icons.person_rounded),
      );
    }
    return Text(
      avatarPresets[profile.avatarId] ?? '⭐',
      style: const TextStyle(fontSize: 56),
    );
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
    if (bytes == null || bytes.isEmpty) {
      setState(
        () => _error = 'Could not load that picture. Try another image.',
      );
      return;
    }
    final extension = (file.extension ?? '').toLowerCase();
    if (!const [
      'png',
      'jpg',
      'jpeg',
      'webp',
      'gif',
      'bmp',
      'heic',
    ].contains(extension)) {
      setState(() => _error = 'Choose a supported image file.');
      return;
    }
    try {
      final path = await widget.store.importCustomAvatar(bytes, extension);
      if (!mounted) return;
      setState(() {
        _customAvatarPath = path;
        _customAvatarData = null;
        _avatarId = 'custom';
        _error = null;
      });
    } on Exception {
      if (mounted) {
        setState(
          () => _error = 'Could not save that picture. Try another image.',
        );
      }
    }
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
    final profile = _profile.copyWith(
      username: username,
      bio: _bio.text.trim(),
      avatarId: _avatarId,
      customAvatarPath: _customAvatarPath,
      customAvatarData: _customAvatarData,
      profileId: _profile.profileId.isEmpty
          ? PlayerProfile.generateId()
          : _profile.profileId,
      setupComplete: true,
      clearCustomAvatar: _avatarId != 'custom',
    );
    try {
      final savedProfile = await widget.store.save(profile);
      if (!mounted) return;
      setState(() {
        _profile = savedProfile;
        _editing = false;
      });
      widget.onSaved(savedProfile);
      if (!widget.firstLaunch) Navigator.of(context).pop();
    } on Exception {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save your profile. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildReadOnly(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Player profile'),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        children: [
          Center(
            child: CircleAvatar(
              radius: 56,
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: ClipOval(
                child: SizedBox(
                  width: 112,
                  height: 112,
                  child: Center(child: _profileAvatar(_profile)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              _profile.username.isEmpty ? 'Player' : _profile.username,
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
            _profile.bio.isEmpty
                ? 'No bio yet. Add a little introduction about yourself.'
                : _profile.bio,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: _profile.bio.isEmpty
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
    );
  }

  Widget _buildEditor(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.firstLaunch ? 'Create your profile' : 'Player profile',
        ),
        automaticallyImplyLeading: !widget.firstLaunch,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            const SizedBox(height: 4),
            Text(
              widget.firstLaunch
                  ? 'Make this game yours.'
                  : 'Your identity stays on this device.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          widget.equippedCosmeticId == 'cosmetic_nebula_ring'
                          ? Border.all(
                              color: theme.colorScheme.primary,
                              width: 4,
                            )
                          : null,
                      boxShadow:
                          widget.equippedCosmeticId == 'cosmetic_pixel_glow'
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
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      child: ClipOval(
                        child: SizedBox(
                          width: 112,
                          height: 112,
                          child: Center(child: _avatarImage()),
                        ),
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
              child: Text(
                _saving
                    ? 'Saving…'
                    : widget.firstLaunch
                    ? 'Create profile & continue'
                    : 'Save profile',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _editing ? _buildEditor(context) : _buildReadOnly(context);
  }
}
