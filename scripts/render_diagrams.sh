#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
SRC_DIR="$ROOT_DIR/docs/diagrams/src"
OUT_DIR="$ROOT_DIR/docs/diagrams/images"
OUT_PUML="$OUT_DIR/plantuml"
OUT_MMD="$OUT_DIR/mermaid"
OUT_ERD="$OUT_DIR/erd"

mkdir -p "$OUT_DIR" "$OUT_PUML" "$OUT_MMD" "$OUT_ERD"

render_plantuml() {
  local src="$1"
  local base
  base=$(basename "$src" .puml)
  local out="$OUT_PUML/${base}.png"
  curl -s -X POST --data-binary @"$src" "https://kroki.io/plantuml/png?backgroundColor=white" -o "$out"
  echo "Rendered PUML -> $(basename "$out")"
}

render_mermaid() {
  local src="$1"
  local base
  base=$(basename "$src" .mmd)
  local out="$OUT_MMD/${base}.png"
  curl -s -X POST --data-binary @"$src" "https://kroki.io/mermaid/png?backgroundColor=white" -o "$out"
  echo "Rendered MMD  -> $(basename "$out")"
}

render_erd() {
  local src="$1"
  local base
  base=$(basename "$src" .erd)
  local out="$OUT_ERD/${base}.png"
  curl -s -X POST --data-binary @"$src" "https://kroki.io/erd/png?backgroundColor=white" -o "$out"
  echo "Rendered ERD  -> $(basename "$out")"
}

count=0
shopt -s nullglob

for f in "$SRC_DIR"/*.puml; do
  render_plantuml "$f"
  count=$((count+1))
done

for f in "$SRC_DIR"/*.mmd; do
  render_mermaid "$f"
  count=$((count+1))
done

for f in "$SRC_DIR"/*.erd; do
  render_erd "$f"
  count=$((count+1))
done

echo "Done. ${count} diagrams rendered to:"
echo " - $OUT_PUML (PlantUML)"
echo " - $OUT_MMD (Mermaid)"
echo " - $OUT_ERD (ERD)"
