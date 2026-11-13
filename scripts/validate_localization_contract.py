#!/usr/bin/env python3
"""Fast GTN2 locale contract and hardcoded Flutter UI audit.

Structural locale failures fail CI. Missing translations and literal UI strings
are reported as migration debt because AppLocalizations intentionally falls
back to the canonical English catalog.
"""
from __future__ import annotations

import json
import re
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LOCALE_DIR = ROOT / "assets" / "locales"
SOURCE_DIR = ROOT / "lib"
EXPECTED = {
    "en_us": "en-US",
    "en_gb": "en-GB",
    "fil_ph": "fil-PH",
    "zh_cn": "zh-CN",
    "zh_tw": "zh-TW",
    "ja": "ja-JP",
    "ko": "ko-KR",
    "es": "es-ES",
    "fr": "fr-FR",
    "de": "de-DE",
    "it": "it-IT",
    "pt_pt": "pt-PT",
    "pt_br": "pt-BR",
    "ru": "ru-RU",
    "hi_in": "hi-IN",
    "id": "id-ID",
    "th": "th-TH",
    "vi": "vi-VN",
    "tr": "tr-TR",
    "pl": "pl-PL",
    "uk": "uk-UA",
    "nl": "nl-NL",
    "ar": "ar-SA",
}
METADATA_KEYS = {"locale_language", "locale_code", "locale_tag", "rtl"}
PLACEHOLDER = re.compile(
    r"%(?!%)(?:(?:\d+)\$)?[-+#0(]*\d*(?:\.\d+)?[a-zA-Z]"
)
LOOKUP = re.compile(r"\bAppLocalizations\.text\(\s*(['\"])([a-zA-Z0-9_]+)\1")
HARDCODED_PATTERNS = (
    ("Text", re.compile(r"\b(?:Text|SelectableText)\s*\(\s*(['\"])([^'\"\n]{2,})\1")),
    ("labelText", re.compile(r"\blabelText\s*:\s*(['\"])([^'\"\n]{2,})\1")),
    ("hintText", re.compile(r"\bhintText\s*:\s*(['\"])([^'\"\n]{2,})\1")),
    ("tooltip", re.compile(r"\btooltip\s*:\s*(['\"])([^'\"\n]{2,})\1")),
    ("semanticsLabel", re.compile(r"\bsemanticsLabel\s*:\s*(['\"])([^'\"\n]{2,})\1")),
)


def read_locale(path: Path) -> dict[str, object]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"{path.name}: locale root must be an object")
    return value


def placeholder_signature(value: object) -> Counter[str]:
    if not isinstance(value, str):
        return Counter()
    return Counter(PLACEHOLDER.findall(value))


def main() -> int:
    errors: list[str] = []
    warnings: list[str] = []
    locale_data: dict[str, dict[str, object]] = {}

    if not LOCALE_DIR.is_dir():
        print("ERROR: missing assets/locales directory")
        return 1

    actual_files = {path.stem for path in LOCALE_DIR.glob("*.json")}
    expected_files = set(EXPECTED)
    for code in sorted(expected_files - actual_files):
        errors.append(f"missing locale asset: {code}.json")
    for code in sorted(actual_files - expected_files):
        warnings.append(f"unregistered locale asset: {code}.json")

    for code, expected_tag in EXPECTED.items():
        path = LOCALE_DIR / f"{code}.json"
        if not path.is_file():
            continue
        try:
            data = read_locale(path)
        except (OSError, UnicodeError, json.JSONDecodeError, ValueError) as exc:
            errors.append(f"{path.name}: {exc}")
            continue
        locale_data[code] = data
        for key in ("locale_language", "locale_code", "locale_tag"):
            if not isinstance(data.get(key), str) or not data[key].strip():
                errors.append(f"{path.name}: missing or invalid {key}")
        if data.get("locale_tag") != expected_tag:
            errors.append(
                f"{path.name}: locale_tag must be {expected_tag!r}, "
                f"found {data.get('locale_tag')!r}"
            )

    baseline = locale_data.get("en_us")
    if baseline is None:
        errors.append("canonical English locale en_us.json could not be loaded")
        baseline = {}
    baseline_keys = set(baseline) - METADATA_KEYS

    missing_translations = 0
    placeholder_mismatches = 0
    for code, data in locale_data.items():
        if code == "en_us":
            continue
        keys = set(data) - METADATA_KEYS
        for key in sorted(keys - baseline_keys):
            warnings.append(f"{code}.json: key {key!r} is absent from en_us.json")
        missing = baseline_keys - keys
        missing_translations += len(missing)
        for key in sorted(keys & baseline_keys):
            if placeholder_signature(baseline.get(key)) != placeholder_signature(data.get(key)):
                placeholder_mismatches += 1
                warnings.append(f"{code}.json: placeholder mismatch for {key!r}")

    missing_lookup_keys: set[str] = set()
    hardcoded: list[tuple[str, int, str, str]] = []
    dart_files = sorted(SOURCE_DIR.rglob("*.dart"))
    for path in dart_files:
        relative = path.relative_to(ROOT).as_posix()
        if "/test/" in f"/{relative}":
            continue
        try:
            lines = path.read_text(encoding="utf-8").splitlines()
        except (OSError, UnicodeError) as exc:
            errors.append(f"{relative}: cannot read source: {exc}")
            continue
        for line_number, line in enumerate(lines, 1):
            for match in LOOKUP.finditer(line):
                key = match.group(2)
                if key not in baseline:
                    missing_lookup_keys.add(f"{relative}:{line_number}: {key}")
            for kind, pattern in HARDCODED_PATTERNS:
                for match in pattern.finditer(line):
                    value = match.group(2).strip()
                    static = re.sub(r"\$\{[^}]+\}|\$[A-Za-z_]\w*", "", value).strip()
                    if len(static) >= 2 and re.search(r"[A-Za-z]{2,}", static):
                        if not value.startswith(("http://", "https://", "assets/")):
                            hardcoded.append((relative, line_number, kind, value))

    if missing_lookup_keys:
        warnings.append(
            f"{len(missing_lookup_keys)} literal AppLocalizations.text key(s) "
            "are absent from en_us.json"
        )
    warnings.extend(
        f"missing locale lookup: {item}" for item in sorted(missing_lookup_keys)[:20]
    )

    print(
        f"Localization contract: {len(locale_data)}/{len(EXPECTED)} locale files, "
        f"{len(baseline_keys)} canonical keys."
    )
    print(
        f"Translation fallback coverage: {missing_translations} missing overlay "
        f"entries; placeholder mismatches: {placeholder_mismatches}."
    )
    print(
        f"Hardcoded Flutter UI audit: scanned {len(dart_files)} Dart files, "
        f"found {len(hardcoded)} candidate(s)."
    )
    for relative, line_number, kind, value in hardcoded[:30]:
        print(f"  - {relative}:{line_number}: [{kind}] {value}")
    if len(hardcoded) > 30:
        print(f"  - ... and {len(hardcoded) - 30} more candidates")

    if errors:
        print("Localization validation FAILED:")
        for error in errors:
            print(f"  - {error}")
        return 1

    print("Localization structural validation PASSED.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
