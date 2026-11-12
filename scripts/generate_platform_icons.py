#!/usr/bin/env python3
"""Generate native launcher and Windows executable icons from the canonical GTN1 logo."""
from __future__ import annotations
import argparse
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "gtn1" / "gtn-app-logo.png"

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--android-only", action="store_true")
    parser.add_argument("--windows-only", action="store_true")
    args = parser.parse_args()
    if not SOURCE.is_file():
        raise SystemExit(f"Canonical GTN logo not found: {SOURCE}")
    image = Image.open(SOURCE).convert("RGBA")
    if not args.windows_only:
        for density, size in {"mdpi":48,"hdpi":72,"xhdpi":96,"xxhdpi":144,"xxxhdpi":192}.items():
            target = ROOT / "android/app/src/main/res" / f"mipmap-{density}"
            target.mkdir(parents=True, exist_ok=True)
            icon = image.resize((size, size), Image.Resampling.LANCZOS)
            icon.save(target / "ic_launcher.png")
            icon.save(target / "ic_launcher_round.png")
    if not args.android_only:
        target = ROOT / "windows/runner/resources"
        target.mkdir(parents=True, exist_ok=True)
        image.save(target / "app_icon.ico", format="ICO",
                   sizes=[(16,16),(24,24),(32,32),(48,48),(64,64),(128,128),(256,256)])
    print("Generated platform icons from assets/gtn1/gtn-app-logo.png")

if __name__ == "__main__":
    main()
