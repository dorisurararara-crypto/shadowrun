#!/usr/bin/env bash
# 새 3개 테마 BGM (.raw) → -23 LUFS 정규화 → themes/ 에 배치.
# 멱등: 이미 themes/ 에 동일 이름이 있으면 덮어씀.

set -euo pipefail
cd "$(dirname "$0")/.."

RAW=assets/audio/themes/.raw
OUT=assets/audio/themes

TARGETS=(
  t2_home_v1 t2_home_v2 t2_marathon_v1 t2_marathon_v2
  t4_home_v1 t4_home_v2 t4_marathon_v1 t4_marathon_v2
  t5_home_v1 t5_home_v2 t5_marathon_v1 t5_marathon_v2
)

ok=0
skip=0
missing=0
for name in "${TARGETS[@]}"; do
  src="$RAW/${name}.mp3"
  dst="$OUT/${name}.mp3"
  if [ ! -f "$src" ]; then
    echo "MISSING: $src"
    missing=$((missing + 1))
    continue
  fi
  echo "=> $name"
  ffmpeg -hide_banner -loglevel error -y -i "$src" \
    -af 'loudnorm=I=-23:TP=-2:LRA=11' \
    -ar 44100 -b:a 192k "$dst"
  ok=$((ok + 1))
done

echo
echo "완료: 정규화 $ok, 누락 $missing"
[ "$missing" -gt 0 ] && exit 1 || exit 0
