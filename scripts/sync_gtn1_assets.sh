#!/usr/bin/env bash
set -euo pipefail

GTN1_ROOT="${1:-gtn1-source}"
SOURCE_ROOT="$GTN1_ROOT/app/src/main/assets"
FONT_SOURCE="$SOURCE_ROOT/fonts"
WEB_SOURCE="$SOURCE_ROOT/web-play"
GAME_SOURCE="$SOURCE_ROOT/game"
TRAIT_SOURCE="$SOURCE_ROOT/traits"
FONT_DEST="assets/fonts"
IMAGE_DEST="assets/gtn1/web-play"
GAME_DEST="assets/game"
TRAIT_DEST="assets/gtn1/traits"
LICENSE_DEST="assets/gtn1/licenses"

required_fonts=(
  "Manrope-VariableFont_wght.ttf"
  "Inter-VariableFont_opsz,wght.ttf"
  "Inter-Italic-VariableFont_opsz,wght.ttf"
  "SpaceGrotesk-VariableFont_wght.ttf"
  "JetBrainsMono-VariableFont_wght.ttf"
  "JetBrainsMono-Italic-VariableFont_wght.ttf"
)

mkdir -p "$FONT_DEST" "$IMAGE_DEST" "$GAME_DEST" "$TRAIT_DEST"
if [[ ! -s "$GTN1_ROOT/GTN_APP_LOGO.png" ]]; then
  echo "Missing canonical GTN1 logo: $GTN1_ROOT/GTN_APP_LOGO.png" >&2
  exit 1
fi
cp "$GTN1_ROOT/GTN_APP_LOGO.png" "assets/gtn1/gtn-app-logo.png"
for font in "${required_fonts[@]}"; do
  if [[ ! -s "$FONT_SOURCE/$font" ]]; then
    echo "Missing required GTN1 font: $FONT_SOURCE/$font" >&2
    exit 1
  fi
  cp "$FONT_SOURCE/$font" "$FONT_DEST/$font"
done

# Preserve original font license notices when present.
find "$FONT_SOURCE" -maxdepth 1 -type f \( -iname 'OFL*' -o -iname '*license*' -o -iname '*copyright*' \) -exec cp {} "$FONT_DEST/" \;

if [[ ! -d "$WEB_SOURCE" ]]; then
  echo "Missing GTN1 Web Play asset directory: $WEB_SOURCE" >&2
  exit 1
fi

image_count=1
while IFS= read -r -d '' file; do
  relative="${file#"$WEB_SOURCE"/}"
  destination="$IMAGE_DEST/$relative"
  mkdir -p "$(dirname "$destination")"
  cp "$file" "$destination"
  image_count=$((image_count + 1))
done < <(find "$WEB_SOURCE" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.avif' -o -iname '*.gif' \) -print0)

# Ship every canonical gameplay catalog, not only the four initially ported catalogs.
if [[ ! -d "$GAME_SOURCE" ]]; then
  echo "Missing GTN1 game catalog directory: $GAME_SOURCE" >&2
  exit 1
fi
cp -a "$GAME_SOURCE/." "$GAME_DEST/"
game_catalog_count=$(find "$GAME_DEST" -maxdepth 1 -type f -name '*.json' | wc -l | tr -d ' ')
source_game_catalog_count=$(find "$GAME_SOURCE" -maxdepth 1 -type f -name '*.json' | wc -l | tr -d ' ')
if [[ "$game_catalog_count" -lt "$source_game_catalog_count" || "$source_game_catalog_count" -lt 17 ]]; then
  echo "Incomplete GTN1 game catalog bundle: found $game_catalog_count of $source_game_catalog_count catalogs." >&2
  exit 1
fi

# Keep the complete trait definition, rules, localization and icon assets available offline.
if [[ ! -d "$TRAIT_SOURCE" ]]; then
  echo "Missing GTN1 trait asset directory: $TRAIT_SOURCE" >&2
  exit 1
fi
rm -rf "$TRAIT_DEST"
mkdir -p "$TRAIT_DEST"
cp -a "$TRAIT_SOURCE/." "$TRAIT_DEST/"
trait_asset_count=$(find "$TRAIT_DEST" -type f | wc -l | tr -d ' ')
source_trait_asset_count=$(find "$TRAIT_SOURCE" -type f | wc -l | tr -d ' ')
if [[ "$trait_asset_count" -ne "$source_trait_asset_count" || "$trait_asset_count" -lt 1300 ]]; then
  echo "Incomplete GTN1 trait asset bundle: found $trait_asset_count of $source_trait_asset_count files." >&2
  exit 1
fi

# Preserve release notes and third-party notices used by About and license screens.
if [[ -f "$SOURCE_ROOT/changelogs.md" ]]; then
  cp "$SOURCE_ROOT/changelogs.md" "assets/gtn1/changelogs.md"
fi
if [[ -d "$SOURCE_ROOT/licenses" ]]; then
  rm -rf "$LICENSE_DEST"
  mkdir -p "$LICENSE_DEST"
  cp -a "$SOURCE_ROOT/licenses/." "$LICENSE_DEST/"
fi

cat > assets/gtn1/source-manifest.json <<EOF
{
  "sourceRepository": "ne0gl1tch20/GuessTheNumber",
  "sourceCommit": "fe9cf567169e19059e0330d08769fe454336ef94",
  "fontFamilies": ["Manrope", "Inter", "Space Grotesk", "JetBrains Mono"],
  "bundledWebPlayImageCount": $image_count,
  "bundledGameCatalogCount": $game_catalog_count,
  "bundledTraitAssetCount": $trait_asset_count
}
EOF

echo "Bundled ${#required_fonts[@]} GTN1 fonts, $image_count Web Play images, $game_catalog_count game catalogs and $trait_asset_count trait assets."
