# Shadow Run — Claude 작업 지침

## 머신 간 작업 교환: HANDOFF.md

이 프로젝트는 **Windows PC**와 **Mac** 두 머신에서 각각 Claude Code로 개발합니다.
- Windows: 주 개발 (코드 작성)
- Mac: iOS/watchOS 빌드·테스트·배포

### 세션 시작 시 반드시
1. `git pull`
2. `HANDOFF.md` 읽기
3. "## 최신" 블록에 **자기 앞으로 온 요청**이 있는지 확인
4. 있으면 수행 → 결과를 "## 최신"에 덧붙여 적고 → commit → push
5. 처리 완료된 이전 항목은 "## 이력"으로 이동

### 메시지 작성 형식
```
### YYYY-MM-DD HH:MM (From → To)
내용...
```
- From/To 는 `Windows` 또는 `Mac`
- 커밋 메시지: `chore: handoff <짧은 요약>`

### 현재 머신 식별
- 이 지시문을 읽는 Claude는 자신이 어느 머신인지 환경으로 판단:
  - `uname` 결과가 `Darwin` → Mac
  - Windows/WSL → Windows

---

## Mac Claude 가 자동 처리할 수 있는 일 (사용자 대신)

사용자가 귀찮아하는 배포·ASC 메타데이터 작업은 거의 전부 자동화돼있음. 다음 목록의 작업이 요청되면 **확인 없이 바로 실행**해도 됨 (이미 인프라 셋업 끝났고 사용자가 승인한 영역).

### 1. TestFlight 새 빌드 배포 (한 줄)

```bash
./scripts/deploy_testflight.sh              # pubspec build+1 자동
./scripts/deploy_testflight.sh 42           # 빌드 번호 명시
```

내부 동작: pubspec 버전 bump → `flutter build ipa --release` → `xcrun altool --validate-app` → `xcrun altool --upload-app`. 업로드 완료 시 Delivery UUID 출력.

### 2. 빌드 처리 상태 조회

```bash
./scripts/asc/check_build_status.rb         # 최근 10개
./scripts/asc/check_build_status.rb 13      # 특정 빌드
```

state 가 `PROCESSING` → `VALID` 이 되면 TestFlight 가능.

### 3. 외부 TestFlight 배포 (심사 제출)

```bash
./scripts/asc/submit_external_beta.rb       # 가장 최근 빌드
./scripts/asc/submit_external_beta.rb 13    # 특정 빌드
```

- 빌드를 외부 그룹 `ganzitester` (id `24a71662-f507-4276-8774-8c0a506006ce`, publicLinkEnabled=true) 에 할당
- Beta App Review 제출 (멱등 — 이미 제출됐으면 현재 상태만 출력)
- **외부 그룹 `ganzitester` 는 이미 Apple Beta Review 통과 상태** → 이후 빌드는 대부분 즉시~몇 시간 내 자동 승인. 큰 변화 없으면 재심사 없이 바로 테스터 배포됨
- 사용자는 주로 **외부 테스트** 사용 → 빌드 올린 뒤 이 스크립트까지 돌리는 게 기본 흐름

### 4. ASC REST API 작업 (공용 헬퍼)

`scripts/asc/_helpers.rb` 를 `require_relative '_helpers'` (또는 `/Users/pc/shadow/scripts/asc/_helpers`) 해서 API 바로 호출:
- `api(:get|:post|:patch|:delete, path, body)` — JWT 자동 생성·서명
- 상수: `APP_ID='6762060466'`, `KEY_ID`, `ISSUER_ID`, `KEY_PATH`

자주 쓰는 엔드포인트:
- `GET /v1/apps/{APP_ID}/inAppPurchasesV2` — IAP 목록
- `POST /v2/inAppPurchases` — IAP 생성 (NON_CONSUMABLE 등)
- `POST /v1/inAppPurchaseLocalizations` — 이름/설명 한/영
- `POST /v1/inAppPurchasePriceSchedules` — 가격 (`baseTerritory=KOR`)
- `POST /v1/inAppPurchaseAvailabilities` — 판매 지역 (175개국)
- `POST /v1/inAppPurchaseAppStoreReviewScreenshots` → 다단계 업로드 (reserve → PUT → PATCH commit)
- `PATCH /v1/betaBuildLocalizations/{id}` — TestFlight "What's New" 한/영
- `PATCH /v1/builds/{id}` — `usesNonExemptEncryption` 등 build 속성
- `POST /v1/betaAppReviewSubmissions` — 외부 심사 제출
- `POST /v1/builds/{id}/relationships/betaGroups` — 그룹 할당

주의:
- 스크린샷 권장 치수 **1242×2208 PNG** (그 이하는 `IMAGE_INCORRECT_DIMENSIONS` 반려)
- IAP 설명 영문 **45자 이내** (한국어는 더 여유)
- price point ID 는 **상품별로 다름** — 각 IAP 의 `/pricePoints?filter[territory]=KOR` 로 개별 조회 필요

### 5. Xcode 프로젝트 수정 (Ruby xcodeproj gem)

CocoaPods 에 포함된 xcodeproj 1.27.0 + claide 사용. 로딩 스니펫:

```ruby
GEMS='/opt/homebrew/Cellar/cocoapods/1.16.2_2/libexec/gems'
Dir["#{GEMS}/*/lib"].each { |p| $LOAD_PATH.unshift(p) }
require 'xcodeproj'
proj = Xcodeproj::Project.open('/Users/pc/shadow/ios/Runner.xcodeproj')
```

round-trip save 해도 `PBXFileSystemSynchronizedRootGroup` (Xcode 16 신기능) 포함 원본 보존됨 (검증됨).

수정 패턴:
- 빌드 세팅: `target.build_configurations.each { |c| c.build_settings['KEY'] = VALUE }`
- 타겟 의존성: `target.add_dependency(other_target)`
- Embed 페이즈: `target.new_copy_files_build_phase('Embed Watch Content')`
- 페이즈 순서: `target.build_phases.delete(x); insert(idx, x)` — **`Embed Watch Content` 는 `Embed Frameworks` 직후에 둬야 함** (`[CP]` Pods 스크립트 뒤에 두면 "Cycle inside Runner" 에러)

### 6. 코드 수정 → 빌드 → 배포 전체 파이프라인

Flutter/Swift 코드 수정 후:
```bash
flutter analyze
./scripts/deploy_testflight.sh
./scripts/asc/submit_external_beta.rb
```

---

## 이미 셋업된 자격증명 · 식별자

| 항목 | 값 |
|---|---|
| ASC API Key 파일 | `~/.appstoreconnect/private_keys/AuthKey_KQ46867WUN.p8` (chmod 600, git 제외) |
| Key ID | `KQ46867WUN` |
| Issuer ID | `5269abe3-03f1-46a9-a37c-35d950758714` |
| Team ID | `Q6H9HCTK6W` |
| App ID (ASC) | `6762060466` |
| Bundle ID (iOS) | `com.ganziman.shadowrun` |
| Bundle ID (Watch) | `com.ganziman.shadowrun.watchkitapp` |
| 외부 테스트 그룹 (통과됨) | `ganzitester` / `24a71662-f507-4276-8774-8c0a506006ce` |
| 내부 테스트 그룹 | `ganzitester` (internal) / `ebf97879-0e74-4f82-abf1-20e62c801dd4` |

---

## 아직 자동화 안 된 것 (필요 시 사용자 허락 받고 셋업)

- **Google Play Console**: service account JSON 키 받으면 Play Developer API 로 동일한 수준 자동화 가능
- **App Store 정식 심사 제출** (TestFlight 가 아닌 App Store 본 심사): 스크린샷·앱 설명·키워드 등 metadata 준비가 비자동
- **IAP 심사 스크린샷 실제 인앱 캡처**: 지금은 플레이스홀더 (브랜드+상품명+가격만). 실기에서 구매 화면 캡처 후 교체 필요
- **ASC 연락처 이메일 오타**: `dorisurararara@gamil.com` (gmail 의 `g` 빠짐) — 사용자가 ASC UI 에서 고쳐야 함

---

## 사용자가 "TestFlight 에 올려줘" 했을 때 기본 동작

별 말 없으면:
1. `./scripts/deploy_testflight.sh` (버전 +1)
2. VALID 될 때까지 `check_build_status.rb` 로 기다림 (또는 몇 분 후 재시도)
3. `./scripts/asc/submit_external_beta.rb` 로 외부 배포까지
4. HANDOFF.md "## 최신" 에 결과 기록 + commit + push
