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
new_build="${1:-$((cur_build + 1))}"

echo "=== version: $ver+$cur_build → $ver+$new_build ==="
sed -i '' "s/^version: .*/version: ${ver}+${new_build}/" pubspec.yaml

echo "=== flutter build ipa --release ==="
flutter build ipa --release

echo "=== xcrun altool --validate-app ==="
xcrun altool --validate-app --type ios -f "$IPA_PATH" \
  --apiKey "$KEY_ID" --apiIssuer "$ISSUER_ID"

echo "=== xcrun altool --upload-app ==="
xcrun altool --upload-app --type ios -f "$IPA_PATH" \
  --apiKey "$KEY_ID" --apiIssuer "$ISSUER_ID"

echo ""
echo "✓ 업로드 완료. Apple 처리 대기 중… (최대 20분)"

# 사용자는 항상 외부 테스터로 배포 — VALID 될 때까지 poll 한 뒤 외부 그룹에 자동 제출
SCRIPT_DIR="$(dirname "$0")"
for attempt in $(seq 1 40); do
  sleep 30
  state=$("${SCRIPT_DIR}/asc/check_build_status.rb" "${new_build}" 2>/dev/null | awk -v b="${new_build}" '$1==b {print $2; exit}')
  if [ "$state" = "VALID" ]; then
    echo "✓ 빌드 ${new_build} VALID — 외부 그룹 자동 제출"
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
