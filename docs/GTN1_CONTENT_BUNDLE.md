# GTN1 source content bundle

Source: `ne0gl1tch20/GuessTheNumber` at pinned commit `fe9cf567169e19059e0330d08769fe454336ef94`.

The Flutter CI sync in `scripts/sync_gtn1_assets.sh` now copies:
- All 17 canonical game JSON catalogs.
- The complete trait asset tree: 320 definitions, 320 rule files, 320 SVG icons and 320 English localization files.
- The six required font files, canonical app logo and supported Web Play raster assets.
- Changelog and third-party license notices when present.

The generated `catalog-manifest.json` indexes every stable trait ID and its definition, rules, localization and icon paths. `scripts/verify_gtn1_assets.py` validates JSON syntax, exact catalog counts, unique trait IDs, package paths and the pinned source revision before Flutter validation and Android/Windows builds.

This is an offline content-bundle foundation. It does not by itself implement the native Flutter screens or gameplay behavior that consume every source definition.


## Release safety gate

The `debug-latest` publishing job is disabled unless the repository variable `GTN1_FULL_PORT_VERIFIED` is explicitly set to `true`. Android and Windows CI builds can still run and produce short-lived validation artifacts, but merging an intermediate porting PR cannot overwrite the public debug release. Set the variable only after the full parity audit, gameplay tests, UI checks and device/platform validation are complete.
