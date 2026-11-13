# GTN1 buildSrc → GTN2 build/CI mapping

**Authority:** `ne0gl1tch20/GuessTheNumber` at `fe9cf567169e19059e0330d08769fe454336ef94`  
**GTN2 snapshot inspected:** `main` at `685a152685e67101628b68c9c3a5d344457599e3`  
**Inventory:** exactly two production Kotlin build-logic files under `buildSrc/src/main`. The pinned inventory contains no buildSrc test files.

This is build-system mapping only. It does not claim that generated APK/Windows artifacts have been inspected or that missing embedded metadata is harmless.

## Source-to-target map

| GTN1 buildSrc source | Source behavior | GTN2 equivalent | Status / remaining work |
|---|---|---|---|
| `buildSrc/src/main/kotlin/buildlogic/GenerateApkBuildInfo.kt` | Generates `assets/info.txt` on every Android build. Records app name, environment, short Git commit, branch, version name/code and build timestamp in Asia/Manila. Uses GitHub environment variables first and local Git as fallback; refreshes timestamp even if commit is unchanged. | `.github/workflows/build.yml` and `.github/workflows/validate.yml` pass `APP_VERSION` and `APP_BUILD_NUMBER` through Dart defines. The publish job emits Android/Windows JSON manifests containing version, run number, commit and SHA-256. | **Gap / partial metadata:** CI release manifests preserve version/build/commit identity outside the application, but no generation of the source-compatible embedded `assets/info.txt` or its branch/build-date fields was found. Decide whether About/diagnostics or artifact verification still consumes this file, then implement or record an owner-approved N/A. |
| `buildSrc/src/main/kotlin/buildlogic/GenerateDesktopLogoAssets.kt` | Copies the canonical `GTN_APP_LOGO.png` into desktop resources and creates a multi-resolution Windows ICO (16, 32, 48 and 256 px) using high-quality bicubic interpolation and alpha. | `scripts/sync_gtn1_assets.sh` bundles the pinned logo to `assets/gtn1/gtn-app-logo.png`. `scripts/generate_platform_icons.py` generates a Windows ICO from that canonical asset and Android density icons. Both Windows build workflows run the generator after creating the Flutter Windows runner. | **Mapped, output verification open:** canonical source and generated Windows ICO are covered by CI; the GTN2 generator uses LANCZOS and includes 16/24/32/48/64/128/256 px sizes. Verify the actual packaged Windows executable/installer icon visually and ensure debug/release jobs both generate it. |

## CI/build evidence

- `.github/workflows/build.yml` fetches the exact pinned GTN1 commit and runs `scripts/sync_gtn1_assets.sh` plus `scripts/verify_gtn1_assets.py`.
- Its Windows job runs `flutter create --platforms=windows`, then `scripts/generate_platform_icons.py --windows-only`, then builds and packages the Windows debug output.
- `.github/workflows/validate.yml` runs the same asset sync/verification and Windows icon generation in both Windows debug and installer/release jobs.
- The Android build jobs pass version/build number Dart defines, but neither workflow currently creates an embedded `assets/info.txt`.
- No buildSrc-specific test suite exists in the pinned source inventory; build outputs and generated icon resources require CI artifact checks/manual platform verification.

## Conclusion

- **Inventory reconciled:** 2/2 buildSrc production files reviewed; zero buildSrc Kotlin tests exist in the pinned source tree.
- **Build-only mapping complete:** the desktop logo task has a direct CI/script replacement. APK build metadata has release-manifest equivalents but is not embedded in the same format, so it remains a concrete gap pending a product/diagnostics usage check.
- This mapping closes source discovery only. It does not close the Stage 6 build, artifact metadata or packaged icon verification gates.

**Next Stage 1 item:** map the single Web Play HTML shell, its actual route/screen renderers and five JavaScript modules to native Flutter destinations and behaviors.
