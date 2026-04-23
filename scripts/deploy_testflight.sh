#!/usr/bin/env bash
# TestFlight 배포 원샷 스크립트.
# 사용: ./scripts/deploy_testflight.sh [build_number_optional]
#   - build_number 생략 시 pubspec.yaml 의 현재 값 +1
#   - build_number 지정 시 해당 값으로 고정

set -euo pipefail
cd "$(dirname "$0")/.."

KEY_ID='JSGU6J4JN4'
ISSUER_ID='5269abe3-03f1-46a9-a37c-35d950758714'
IPA_PATH='build/ios/ipa/shadowrun.ipa'

current=$(grep -E '^version:' pubspec.yaml | sed -E 's/version: ([0-9.]+)\+([0-9]+)/\1\+\2/')
ver=$(echo "$current" | cut -d+ -f1)
cur_build=$(echo "$current" | cut -d+ -f2)

# ASC 에 이미 올라간 최대 빌드 번호 조회 (v19 같은 버전 충돌 방어).
# Apple 은 같은 버전 번호 재업로드 거부 → 로컬 pubspec 과 무관하게 ASC 최대 +1 보장.
SCRIPT_DIR="$(dirname "$0")"
asc_max=$("${SCRIPT_DIR}/asc/check_build_status.rb" 2>/dev/null | awk 'NR==2 {print $1}')
if [ -n "$asc_max" ] && [ "$asc_max" -eq "$asc_max" ] 2>/dev/null; then
  safe_build=$((asc_max + 1))
  next_default=$((cur_build + 1))
  [ "$safe_build" -gt "$next_default" ] && next_default="$safe_build"
else
  next_default=$((cur_build + 1))
fi
new_build="${1:-$next_default}"

# 명시 지정된 번호도 ASC 에 이미 있으면 abort.
if [ -n "$asc_max" ] && [ "$new_build" -le "$asc_max" ]; then
  # 해당 번호가 실제로 ASC 에 존재하는지 검증 (missing number 일 수도)
  existing=$("${SCRIPT_DIR}/asc/check_build_status.rb" "$new_build" 2>/dev/null | awk -v b="$new_build" '$1==b {print; exit}')
  if [ -n "$existing" ]; then
    echo "❌ 빌드 번호 ${new_build} 은 이미 ASC 에 존재: ${existing}"
    echo "   ASC 최대 빌드: ${asc_max}. 최소 $((asc_max + 1)) 이상 써야 함."
    exit 1
  fi
fi

echo "=== version: $ver+$cur_build → $ver+$new_build (ASC max=${asc_max:-?}) ==="
sed -i '' "s/^version: .*/version: ${ver}+${new_build}/" pubspec.yaml

echo "=== flutter build ipa --release (build-number=${new_build} 명시) ==="
# pubspec sed 만으로는 Flutter 빌드 캐시 때문에 이전 build-number 가 그대로 ipa 에 박힐 수 있음.
# Apple 이 "previous: N" 으로 중복 거부하는 것을 막기 위해 --build-number 로 강제 지정.
flutter build ipa --release --build-number "${new_build}" --build-name "${ver}"

echo "=== xcrun altool --validate-app ==="
xcrun altool --validate-app --type ios -f "$IPA_PATH" \
  --apiKey "$KEY_ID" --apiIssuer "$ISSUER_ID"

echo "=== xcrun altool --upload-app ==="
xcrun altool --upload-app --type ios -f "$IPA_PATH" \
  --apiKey "$KEY_ID" --apiIssuer "$ISSUER_ID"

upload_ts=$(date +%s)
echo ""
echo "✓ 업로드 완료. Apple 처리 대기 중… (최대 20분)"

# 사용자는 항상 외부 테스터로 배포 — VALID 될 때까지 poll 한 뒤 외부 그룹에 자동 제출.
# 주의: poll 은 반드시 "방금 upload 한 빌드" 를 대상으로 해야 함. ASC 에 이미 같은 번호가
# 있었다면 기존 빌드의 VALID 를 오인할 위험이 있어 uploadedDate 를 함께 검증한다.
for attempt in $(seq 1 40); do
  sleep 30
  row=$("${SCRIPT_DIR}/asc/check_build_status.rb" "${new_build}" 2>/dev/null | awk -v b="${new_build}" '$1==b {print; exit}')
  state=$(echo "$row" | awk '{print $2}')
  uploaded=$(echo "$row" | awk '{print $4}')
  # uploadedDate 가 upload 시각보다 10분 이상 이전이면 기존 빌드 오인 → abort
  if [ -n "$uploaded" ]; then
    uploaded_ts=$(date -jf "%Y-%m-%dT%H:%M:%S%z" "${uploaded/%-[0-9][0-9]:[0-9][0-9]/-0700}" +%s 2>/dev/null || echo 0)
    if [ "$uploaded_ts" -gt 0 ] && [ $((upload_ts - uploaded_ts)) -gt 600 ]; then
      echo "❌ 빌드 ${new_build} 의 uploadedDate($uploaded) 가 방금 업로드 시각보다 훨씬 이전."
      echo "   이미 ASC 에 기존 빌드가 있어 내 업로드가 중복 거부된 상태. 다음 번호로 재시도."
      exit 2
    fi
  fi
  if [ "$state" = "VALID" ]; then
    echo "✓ 빌드 ${new_build} VALID (uploaded=$uploaded) — 외부 그룹 자동 제출"
    "${SCRIPT_DIR}/asc/submit_external_beta.rb" "${new_build}"
    echo ""
    echo "✓ 외부 테스터 배포 완료 (Beta Review 통과된 그룹이라 대부분 즉시 반영)"
    exit 0
  fi
  echo "  [${attempt}/40] state=${state:-unknown}, 30s 뒤 재확인"
done

echo "⚠️ 20분 지나도 VALID 안 됨. 나중에 수동으로:"
echo "  ${SCRIPT_DIR}/asc/submit_external_beta.rb ${new_build}"
exit 1
