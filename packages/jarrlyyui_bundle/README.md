# jarrlyyui_bundle

A standalone bundle validation and update coordinator for jarrlyyui v1.

The package lets an Android or Windows host check a configured source for a newer UI bundle, verify its manifest and SHA-256 file hashes, parse every .jui screen, and stage the validated result before atomically activating it. It rejects path traversal, unknown file types, malformed screens, mismatched file lists, incompatible host API requirements, oversized bundles and version downgrades.

The app supplies two platform-specific adapters:

- JuiBundleSource fetches a package from the app's configured update source. It can point at a GitHub release, raw repository content or a private service.
- JuiBundleStore persists staged and active bundles. Its activation operation must atomically switch the active version and preserve the previous bundle if activation fails.

This package deliberately does not own HTTP, platform storage, app startup, navigation or gameplay. The host controls when updates are checked and supplies the storage implementation. UI documents cannot run code or mutate saves. All actions still go through the app's allowlisted Dart host bridge.

SHA-256 detects content changes relative to the manifest. It does not authenticate who published the manifest. Production apps should fetch from a trusted HTTPS source and add signed-manifest verification before accepting bundles from untrusted distribution channels.
