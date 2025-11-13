#!/bin/bash

set -e

export PATH="$HOME/.local/bin:$PATH"

if ! command -v d2 &> /dev/null; then
    echo "Error: d2 is not installed. Install it from https://d2lang.com"
    exit 1
fi

LAYOUT="${D2_LAYOUT:-elk}"

echo "Rendering D2 diagrams with layout engine: $LAYOUT"
echo "D2 version: $(d2 --version)"

mkdir -p docs/diagrams/svg

for d2_file in docs/diagrams/d2/*.d2; do
    filename=$(basename "$d2_file" .d2)
    svg_file="docs/diagrams/svg/${filename}.svg"
    
    echo "Rendering: $d2_file -> $svg_file"
    d2 --layout "$LAYOUT" --theme 200 --pad 20 --sketch=false "$d2_file" "$svg_file"
done

echo "✓ All diagrams rendered successfully!"
echo ""
echo "To use TALA layout engine (if available):"
echo "  D2_LAYOUT=tala ./scripts/render_d2.sh"
