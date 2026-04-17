#!/usr/bin/env bash
# TestFlight 배포 원샷 스크립트.
# 사용: ./scripts/deploy_testflight.sh [build_number_optional]
#   - build_number 생략 시 pubspec.yaml 의 현재 값 +1
#   - build_number 지정 시 해당 값으로 고정

set -euo pipefail
cd "$(dirname "$0")/.."

KEY_ID='KQ46867WUN'
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
echo "✓ 업로드 완료. Apple 처리 5~20분 후 TestFlight 반영."
echo "  빌드 상태 확인:        scripts/asc/check_build_status.rb ${new_build}"
echo "  외부 테스트 제출:      scripts/asc/submit_external_beta.rb ${new_build}"
