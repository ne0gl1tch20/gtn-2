# jarrlyyui_bundle

A standalone bundle validation and update coordinator for jarrlyyui v1.

The package lets an Android or Windows host check a configured source for a newer UI bundle, verify its manifest and SHA-256 file hashes, parse every .jui screen, and stage the validated result before atomically activating it. It rejects path traversal, unknown file types, malformed screens, mismatched file lists, incompatible host API requirements, oversized bundles and version downgrades.

The app supplies a source and an application-support directory:

- JuiGitHubBundleSource downloads a manifest and its listed files from a configured GitHub repository over HTTPS. Other sources can implement JuiBundleSource.
- JuiFileBundleStore persists staged and active bundles under a directory supplied by the host. It writes the bundle first, then switches the active-version pointer; a failed or stale activation leaves the previous active version intact.

This package does not own app startup, navigation or gameplay. The host chooses the repository/ref, provides an application-support directory and controls when updates are checked. UI documents cannot run code or mutate saves. All actions still go through the app's allowlisted Dart host bridge.

SHA-256 detects content changes relative to the manifest. It does not authenticate who published the manifest. Production apps should fetch from a trusted HTTPS source and add signed-manifest verification before accepting bundles from untrusted distribution channels.
