#!/usr/bin/env bash
set -euo pipefail

GTN1_ROOT="${1:-gtn1-source}"
SOURCE_ROOT="$GTN1_ROOT/app/src/main/assets"
FONT_SOURCE="$SOURCE_ROOT/fonts"
WEB_SOURCE="$SOURCE_ROOT/web-play"
FONT_DEST="assets/fonts"
IMAGE_DEST="assets/gtn1/web-play"

required_fonts=(
  "Manrope-VariableFont_wght.ttf"
  "Inter-VariableFont_opsz,wght.ttf"
  "Inter-Italic-VariableFont_opsz,wght.ttf"
  "SpaceGrotesk-VariableFont_wght.ttf"
  "JetBrainsMono-VariableFont_wght.ttf"
  "JetBrainsMono-Italic-VariableFont_wght.ttf"
)

mkdir -p "$FONT_DEST" "$IMAGE_DEST"
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

cat > assets/gtn1/source-manifest.json <<EOF
{
  "sourceRepository": "ne0gl1tch20/GuessTheNumber",
  "sourceCommit": "fe9cf567169e19059e0330d08769fe454336ef94",
  "fontFamilies": ["Manrope", "Inter", "Space Grotesk", "JetBrains Mono"],
  "bundledImageCount": $image_count
}
EOF

echo "Bundled ${#required_fonts[@]} GTN1 fonts and $image_count image assets."
