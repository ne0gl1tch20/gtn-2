#!/usr/bin/env python3
"""Generate a stable Flutter-readable index for the complete GTN1 trait catalog."""

from __future__ import annotations

import json
from pathlib import Path
import sys


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("usage: generate_trait_manifest.py <traits-directory>")
    root = Path(sys.argv[1]).resolve()
    entries = []
    seen: set[str] = set()
    for definition_path in sorted(root.glob("catalogs/*/*/trait.json")):
        definition = json.loads(definition_path.read_text(encoding="utf-8"))
        trait_id = definition.get("id")
        catalog_id = definition.get("catalogId")
        package_folder = definition.get("packageFolder")
        if not all(isinstance(value, str) and value for value in (trait_id, catalog_id, package_folder)):
            raise SystemExit(f"Invalid trait identity in {definition_path}")
        if trait_id in seen:
            raise SystemExit(f"Duplicate trait ID: {trait_id}")
        seen.add(trait_id)
        package = definition_path.parent
        required = {
            "definition": package / "trait.json",
            "rules": package / "rules.json",
            "localization": package / "locales" / "en.json",
            "icon": package / "icon.svg",
        }
        missing = [str(path.relative_to(root)) for path in required.values() if not path.is_file()]
        if missing:
            raise SystemExit(f"{trait_id} is missing required package files: {', '.join(missing)}")
        entries.append(
            {
                "id": trait_id,
                "catalogId": catalog_id,
                "packageFolder": package_folder,
                "category": definition.get("category", "UNKNOWN"),
                "visibility": definition.get("visibility", "VISIBLE"),
                "titleKey": definition.get("titleKey"),
                "descriptionKey": definition.get("descriptionKey"),
                "definitionPath": required["definition"].relative_to(root).as_posix(),
                "rulesPath": required["rules"].relative_to(root).as_posix(),
                "localizationPath": required["localization"].relative_to(root).as_posix(),
                "iconPath": required["icon"].relative_to(root).as_posix(),
            }
        )
    if len(entries) != 320:
        raise SystemExit(f"Expected 320 GTN1 traits, found {len(entries)}")
    output = {
        "schemaVersion": 1,
        "sourceRepository": "ne0gl1tch20/GuessTheNumber",
        "sourceCommit": "fe9cf567169e19059e0330d08769fe454336ef94",
        "traitCount": len(entries),
        "traits": entries,
    }
    (root / "catalog-manifest.json").write_text(
        json.dumps(output, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Generated trait manifest for {len(entries)} stable IDs.")


if __name__ == "__main__":
    main()
