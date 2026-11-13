#!/usr/bin/env python3
"""Validate the pinned GTN1 content bundle before Flutter builds."""

from __future__ import annotations

import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
GAME = ROOT / "assets" / "game"
TRAITS = ROOT / "assets" / "gtn1" / "traits"
LOCALES = ROOT / "assets" / "locales"
SCRIPTS = ROOT / "assets" / "scripts"
MANIFEST = ROOT / "assets" / "gtn1" / "source-manifest.json"
INVENTORY = ROOT / "docs" / "GTN1_SOURCE_INVENTORY.json"
TRAIT_ID_MAP = ROOT / "docs" / "GTN1_TRAIT_ID_MAP.json"
BUILTIN_TRAIT_CATALOG = ROOT / "lib" / "core" / "legacy" / "builtin_trait_catalog.dart"
APP_LOCALIZATIONS = ROOT / "lib" / "i18n" / "app_localizations.dart"


def fail(message: str) -> None:
    print(f"GTN1 asset validation failed: {message}", file=sys.stderr)
    raise SystemExit(1)


try:
    inventory = json.loads(INVENTORY.read_text(encoding="utf-8"))
except (OSError, json.JSONDecodeError) as error:
    fail(f"source inventory is invalid: {error}")

if inventory.get("source", {}).get("commit") != "fe9cf567169e19059e0330d08769fe454336ef94":
    fail("source inventory does not match the pinned GTN1 revision")

# Validate the complete canonical game catalog set, not only the files committed
# to the Flutter repository. The CI sync step copies the remaining source files.
expected_game_catalogs = {
    Path(path).name for path in inventory.get("files", {}).get("game_catalogs", [])
}
game_catalogs = sorted(GAME.glob("*.json"))
actual_game_catalogs = {path.name for path in game_catalogs}
if len(expected_game_catalogs) != 17 or actual_game_catalogs != expected_game_catalogs:
    fail(
        "game catalog inventory mismatch: "
        f"expected {sorted(expected_game_catalogs)}, found {sorted(actual_game_catalogs)}"
    )
for path in game_catalogs:
    try:
        with path.open(encoding="utf-8") as stream:
            json.load(stream)
    except (OSError, json.JSONDecodeError) as error:
        fail(f"invalid game catalog {path.relative_to(ROOT)}: {error}")

# Locale files are tracked in GTN2 rather than generated during the asset sync.
expected_locales = {
    Path(path).stem for path in inventory.get("files", {}).get("locales", [])
}
locale_files = sorted(LOCALES.glob("*.json"))
actual_locales = {path.stem for path in locale_files}
if len(expected_locales) != 23 or actual_locales != expected_locales:
    fail(
        "locale inventory mismatch: "
        f"expected {sorted(expected_locales)}, found {sorted(actual_locales)}"
    )
try:
    localization_source = APP_LOCALIZATIONS.read_text(encoding="utf-8")
except OSError as error:
    fail(f"AppLocalizations source is missing: {error}")
supported_locales = set(re.findall(r"\('([a-z]{2,3}(?:_[a-z]{2,3})?)',", localization_source))
if supported_locales != expected_locales:
    fail(
        "AppLocalizations supported locale IDs do not match bundled locale files: "
        f"supported {sorted(supported_locales)}, bundled {sorted(expected_locales)}"
    )
for path in locale_files:
    try:
        with path.open(encoding="utf-8") as stream:
            json.load(stream)
    except (OSError, json.JSONDecodeError) as error:
        fail(f"invalid locale JSON {path.relative_to(ROOT)}: {error}")

# Every pinned core Lua script must be present and registered exactly once.
expected_lua_files = {
    Path(path).relative_to("app/src/main/assets/scripts").as_posix()
    for path in inventory.get("files", {}).get("core_lua", [])
}
actual_lua_files = {
    path.relative_to(SCRIPTS).as_posix() for path in SCRIPTS.rglob("*.lua")
}
if len(expected_lua_files) != 4 or actual_lua_files != expected_lua_files:
    fail(
        "core Lua script inventory mismatch: "
        f"expected {sorted(expected_lua_files)}, found {sorted(actual_lua_files)}"
    )
try:
    script_manifest = json.loads((SCRIPTS / "manifest.json").read_text(encoding="utf-8"))
except (OSError, json.JSONDecodeError) as error:
    fail(f"Lua script manifest is invalid: {error}")
script_entries = script_manifest.get("scripts")
if (
    script_manifest.get("schemaVersion") != 1
    or script_manifest.get("hostApiVersion") != 1
    or not isinstance(script_entries, list)
):
    fail("Lua script manifest has an unsupported schema or host API")
registered_lua_files = [
    entry.get("file") for entry in script_entries if isinstance(entry, dict)
]
registered_lua_ids = [
    entry.get("id") for entry in script_entries if isinstance(entry, dict)
]
if (
    len(registered_lua_files) != 4
    or len(set(registered_lua_files)) != 4
    or set(registered_lua_files) != expected_lua_files
    or len(set(registered_lua_ids)) != 4
    or any(not isinstance(value, str) or not value for value in registered_lua_ids)
):
    fail("Lua manifest must register each pinned core script exactly once")

# Trait package content is copied from the pinned source at build time. The
# generated manifest must contain the same 320 stable IDs as GTN1 and Dart.
trait_definitions = sorted(TRAITS.glob("catalogs/**/trait.json"))
trait_rules = sorted(TRAITS.glob("catalogs/**/rules.json"))
trait_icons = sorted(TRAITS.glob("catalogs/**/icon.svg"))
trait_locales = sorted(TRAITS.glob("catalogs/**/locales/en.json"))
for label, paths in (
    ("trait definitions", trait_definitions),
    ("trait rule files", trait_rules),
    ("trait icons", trait_icons),
    ("English trait localizations", trait_locales),
):
    if len(paths) != 320:
        fail(f"expected 320 {label}, found {len(paths)}")

for path in TRAITS.rglob("*.json"):
    try:
        with path.open(encoding="utf-8") as stream:
            json.load(stream)
    except (OSError, json.JSONDecodeError) as error:
        fail(f"invalid trait data {path.relative_to(ROOT)}: {error}")

try:
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
except (OSError, json.JSONDecodeError) as error:
    fail(f"source manifest is invalid: {error}")

if manifest.get("sourceCommit") != "fe9cf567169e19059e0330d08769fe454336ef94":
    fail("asset source commit does not match the pinned GTN1 revision")
if manifest.get("bundledWebPlayImageCount", 0) < 13:
    fail("source manifest is missing Web Play SVG artwork")
if manifest.get("bundledGameCatalogCount") != 17:
    fail("source manifest game catalog count is not 17")
if manifest.get("bundledTraitAssetCount", 0) < 1300:
    fail("source manifest is missing the full trait asset bundle")

try:
    trait_manifest = json.loads(
        (TRAITS / "catalog-manifest.json").read_text(encoding="utf-8")
    )
    trait_id_map = json.loads(TRAIT_ID_MAP.read_text(encoding="utf-8"))
    builtin_source = BUILTIN_TRAIT_CATALOG.read_text(encoding="utf-8")
except (OSError, json.JSONDecodeError) as error:
    fail(f"trait catalog or stable ID map is invalid: {error}")

entries = trait_manifest.get("traits")
if (
    trait_manifest.get("schemaVersion") != 1
    or trait_manifest.get("sourceCommit") != "fe9cf567169e19059e0330d08769fe454336ef94"
    or trait_manifest.get("traitCount") != 320
    or not isinstance(entries, list)
    or len(entries) != 320
):
    fail("trait catalog manifest must contain exactly 320 entries from the pinned source")

manifest_ids = [entry.get("id") for entry in entries if isinstance(entry, dict)]
mapped_ids = [
    entry.get("sourceId")
    for entry in trait_id_map.get("entries", [])
    if isinstance(entry, dict)
]
dart_ids = re.findall(r'"id": "([^"]+)"', builtin_source)
if (
    trait_id_map.get("sourceCommit") != "fe9cf567169e19059e0330d08769fe454336ef94"
    or trait_id_map.get("count") != 320
    or len(mapped_ids) != 320
    or len(set(mapped_ids)) != 320
    or len(manifest_ids) != 320
    or len(set(manifest_ids)) != 320
    or len(dart_ids) != 320
    or len(set(dart_ids)) != 320
    or set(manifest_ids) != set(mapped_ids)
    or set(dart_ids) != set(mapped_ids)
):
    fail("trait package IDs, GTN1 stable ID map and Dart built-in IDs do not match exactly")

for entry in entries:
    for key in ("definitionPath", "rulesPath", "localizationPath", "iconPath"):
        relative = entry.get(key)
        if not isinstance(relative, str) or not (TRAITS / relative).is_file():
            fail(f"trait manifest entry {entry.get('id')} is missing {key}")

print(
    "GTN1 content verified: "
    f"{len(game_catalogs)} game catalogs, "
    f"{len(locale_files)} locales, "
    f"{len(expected_lua_files)} Lua scripts, "
    f"{len(trait_definitions)} trait definitions, "
    f"{len(trait_rules)} rule files, "
    f"{len(trait_icons)} icons and "
    f"{len(trait_locales)} English localizations."
)
