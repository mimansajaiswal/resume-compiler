#!/usr/bin/env bash
set -euo pipefail

RAW_NAME="$(sed -nE 's/^  name:[[:space:]]*"?([^"]+)"?/\1/p' resume.yml | head -n1)"
if [ -n "$RAW_NAME" ]; then
  FIRST_NAME="$(echo "$RAW_NAME" | awk '{print $1}')"
  LAST_NAME="$(echo "$RAW_NAME" | awk '{print $NF}')"
  if [ "$FIRST_NAME" = "$LAST_NAME" ]; then
    NAME_STEM="$FIRST_NAME"
  else
    NAME_STEM="${FIRST_NAME}${LAST_NAME}"
  fi
  NAME_STEM="$(echo "$NAME_STEM" | tr -cd '[:alnum:]')"
fi
if [ -z "${NAME_STEM:-}" ]; then
  NAME_STEM="Resume"
fi

LAST_UPDATED="$(git log -1 --date=format:'%B %-d, %Y' --format=%ad -- resume.yml 2>/dev/null || true)"
if [ -z "$LAST_UPDATED" ]; then
  LAST_UPDATED="$(date '+%B %-d, %Y')"
fi

OUT_MAIN="${NAME_STEM}_Resume.pdf"
OUT_S="${NAME_STEM}_Resume_S.pdf"
OUT_B="${NAME_STEM}_Resume_B.pdf"
OUT_N="${NAME_STEM}_Resume_N.pdf"
OUT_DIR="artifacts"
mkdir -p "$OUT_DIR"

typst compile --input "last_updated=${LAST_UPDATED}" resume.typ "$OUT_DIR/$OUT_MAIN"
typst compile --input "last_updated=${LAST_UPDATED}" resume-short.typ "$OUT_DIR/$OUT_S"
typst compile --input "last_updated=${LAST_UPDATED}" resume-with-bibtex.typ "$OUT_DIR/$OUT_B"
typst compile --input "last_updated=${LAST_UPDATED}" resume-no-js.typ "$OUT_DIR/$OUT_N"

echo "Built:"
echo "  $OUT_DIR/$OUT_MAIN"
echo "  $OUT_DIR/$OUT_S"
echo "  $OUT_DIR/$OUT_B"
echo "  $OUT_DIR/$OUT_N"
