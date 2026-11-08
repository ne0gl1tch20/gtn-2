#!/usr/bin/env python3
"""Validate the pinned GTN1 content bundle before Flutter builds."""

from __future__ import annotations

import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
GAME = ROOT / "assets" / "game"
TRAITS = ROOT / "assets" / "gtn1" / "traits"
SCRIPTS = ROOT / "assets" / "gtn1" / "scripts"
MANIFEST = ROOT / "assets" / "gtn1" / "source-manifest.json"


def fail(message: str) -> None:
    print(f"GTN1 asset validation failed: {message}", file=sys.stderr)
    raise SystemExit(1)


game_catalogs = sorted(GAME.glob("*.json"))
if len(game_catalogs) != 17:
    fail(f"expected 17 game catalogs, found {len(game_catalogs)}")
for path in game_catalogs:
    try:
        with path.open(encoding="utf-8") as stream:
            json.load(stream)
    except (OSError, json.JSONDecodeError) as error:
        fail(f"invalid game catalog {path.relative_to(ROOT)}: {error}")

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
if manifest.get("bundledLuaScriptCount") != 4:
    fail("source manifest is missing the complete Lua script bundle")

try:
    script_catalog = json.loads(
        (SCRIPTS / "manifest.json").read_text(encoding="utf-8")
    )
except (OSError, json.JSONDecodeError) as error:
    fail(f"Lua script manifest is invalid: {error}")
if script_catalog.get("schemaVersion") != 1 or script_catalog.get("hostApiVersion") != 1:
    fail("unsupported Lua script catalog schema or host API version")
script_entries = script_catalog.get("scripts")
if not isinstance(script_entries, list) or not script_entries:
    fail("Lua script catalog has no registered scripts")
script_ids = [entry.get("id") for entry in script_entries if isinstance(entry, dict)]
if len(script_ids) != len(script_entries) or len(set(script_ids)) != len(script_ids):
    fail("Lua script catalog contains missing or duplicate IDs")
for entry in script_entries:
    relative = entry.get("file")
    if not isinstance(relative, str) or ".." in Path(relative).parts:
        fail(f"Lua script {entry.get('id')} has an invalid source path")
    script_path = SCRIPTS / relative
    if not script_path.is_file() or script_path.suffix != ".lua":
        fail(f"Lua script {entry.get('id')} is missing its source file")
    if entry.get("hostApiVersion") != 1:
        fail(f"Lua script {entry.get('id')} requires an unsupported host API version")

try:
    trait_manifest = json.loads(
        (TRAITS / "catalog-manifest.json").read_text(encoding="utf-8")
    )
except (OSError, json.JSONDecodeError) as error:
    fail(f"trait catalog manifest is invalid: {error}")

entries = trait_manifest.get("traits")
if trait_manifest.get("traitCount") != 320 or not isinstance(entries, list) or len(entries) != 320:
    fail("trait catalog manifest must contain exactly 320 entries")
ids = [entry.get("id") for entry in entries if isinstance(entry, dict)]
if len(ids) != 320 or len(set(ids)) != 320:
    fail("trait catalog manifest contains missing or duplicate stable IDs")
for entry in entries:
    for key in ("definitionPath", "rulesPath", "localizationPath", "iconPath"):
        relative = entry.get(key)
        if not isinstance(relative, str) or not (TRAITS / relative).is_file():
            fail(f"trait manifest entry {entry.get('id')} is missing {key}")

print(
    "GTN1 content verified: "
    f"{len(game_catalogs)} game catalogs, "
    f"{len(trait_definitions)} trait definitions, "
    f"{len(trait_rules)} rule files, "
    f"{len(trait_icons)} icons and "
    f"{len(trait_locales)} English localizations and "
    f"{len(list(SCRIPTS.rglob('*.lua')))} Lua scripts."
)
