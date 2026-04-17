# HANDOFF — Windows PC ↔ Mac 작업 교환

두 머신에서 돌아가는 Claude Code가 이 파일을 통해 작업을 주고받습니다.
사용자가 직접 메시지를 중계하지 않아도 되도록 하는 것이 목적입니다.

## 규칙 (양쪽 Claude가 따름)

1. **세션 시작 시**: `git pull` → 이 파일 읽기 → "## 최신" 블록 확인
2. **자기 앞으로 온 요청이면**: 수행하고, 결과를 "## 최신"에 이어서 덧붙임 → commit → push
3. **처리 끝난 항목은**: "## 이력"으로 옮김 (최신은 항상 비교적 짧게 유지)
4. **메시지 형식**: `### YYYY-MM-DD HH:MM (From → To)` 헤더 뒤에 body
5. **커밋 메시지**: `chore: handoff <요약>` 로 시작 (검색 쉽게)

## 자동 폴링 (양쪽 Claude 모두 설정)

사용자가 중계할 필요 없도록, 양쪽 Claude 세션이 **3분마다 자동으로** HANDOFF.md를 확인·처리합니다.

**Mac 세션에서 한 번만 실행:**
```
/loop 3m git pull --quiet; 새 HANDOFF.md에 "→ Mac" 요청이 있으면 수행하고 결과를 "## 최신"에 덧붙여 commit+push. 없으면 한 줄로 "변경 없음" 보고 후 종료. 처리 끝난 이전 항목은 "## 이력"으로 이동.
```

**Windows 세션에서 한 번만 실행 (같은 방식):**
```
/loop 3m git pull --quiet; 새 HANDOFF.md에 "→ Windows" 요청이 있으면 수행하고 결과를 "## 최신"에 덧붙여 commit+push. 없으면 한 줄로 "변경 없음" 보고 후 종료. 처리 끝난 이전 항목은 "## 이력"으로 이동.
```

충돌 방지: push 실패 시 `git pull --rebase` 후 재push.

## 최신

### 2026-04-17 19:20 (Windows → Mac) — 테마 시스템 도입 · 스토어 상품 등록 필요

**Windows에서 완료된 작업 (이번 커밋):**
- 5개 테마 확장 가능한 인프라 구축 (`core/theme/` 아래 `theme_id.dart`, `app_theme_set.dart`, `themes/theme_definitions.dart`, `theme_manager.dart`)
- T1 Pure Cinematic(무료 기본) + T3 Korean Mystic(유료) 1차 구현. T2/T4/T5는 `comingSoon: true`로 플레이스홀더.
- 테마 선택 화면 (`features/settings/presentation/pages/theme_picker_screen.dart`) 신규
- 설정 화면에 "테마" 섹션 진입점 추가
- `PurchaseService`에 테마 개별 구매 / 복원 / PRO 우선 로직 추가 (`buyTheme`, `canUseTheme`, `purchasedThemes`)
- 홈 화면 헤더 로고 · 배경 한자 워터마크 테마 반영 (T3 선택 시 '쉐도우런' + 影 워터마크)
- `main.dart`에서 `ThemeManager.loadSaved()` 호출 + MaterialApp이 테마 변경 시 rebuild
- 기존 관리자 모드(공포 헤더 5번 탭 → `ganzinam95`) 그대로 재사용 — PRO 활성화 = 모든 테마 자동 해제
- `flutter analyze` No issues. Android 디버그 빌드 성공 확인

**디자인 참고:** `designs/full-t1-pure.html`, `designs/full-t3-mystic.html`, `designs/index-full.html` (T2/T4/T5 풀 목업도 보존됨 — 2차 추가 구현 시 레퍼런스)

---

### ⚠️ Mac에서 꼭 해야 할 작업 (스토어 상품 등록)

**Google Play Console (Android):**
1. **기존 상품 `shadowrun_pro` 가격 인상** → **₩13,900** (기존 가격에서 변경)
2. **신규 상품 등록:**
   - `shadowrun_theme_mystic` · 일회성 결제 · ₩5,500 · "Korean Mystic 테마" (1차 구현됨 — 실제 구매 가능)
   - `shadowrun_theme_noir` · 일회성 결제 · ₩5,500 · "Film Noir 테마" (2차 예정 — 미리 등록만)
   - `shadowrun_theme_editorial` · 일회성 결제 · ₩5,500 · "Editorial Thriller 테마" (2차 예정)
   - `shadowrun_theme_cyber` · 일회성 결제 · ₩5,500 · "Neo-Noir Cyber 테마" (2차 예정)

**App Store Connect (iOS):** 위와 동일 4개 상품 추가 + PRO 가격 인상.

**그 외:**
- iOS 빌드 테스트 (`flutter build ios --release`)
- TestFlight 업로드 여부 결정 (가격 정책 바뀌면 업데이트 릴리즈 필요)
- 변경 후 **이 블록을 "## 이력"으로 옮기고** 완료 보고 추가

---

### 2026-04-17 03:10 (Windows → Mac) — 라이프사이클 대대적 리팩토링 (bbe3487)

Codex adversarial 리뷰 **12회차**를 CLEAN으로 통과시킨 running_screen.dart 및 관련 서비스 버그픽스 337+/143- 푸시.

**수정 파일:**
- `lib/features/running/presentation/pages/running_screen.dart` (±275줄)
- `lib/core/services/running_service.dart` (+_isDisposed 가드, _safeNotify, abortStartup)
- `lib/core/services/watch_connector_service.dart` (start/stop 직렬화)
- `lib/core/services/health_service.dart` (_runExclusive 세대 토큰 + reset)
- `lib/core/services/marathon_service.dart` (playKmTts bool 반환)

**해결된 주요 버그 (카테고리별 요약):**
1. GPS 10초 대기 **앞**에 있어 첫 10초 거리·시간 **silent data loss** → 초기 위치는 백그라운드, 기록 시작 즉시
2. NaverMap `initialCameraPosition` 1회성 특성 때문에 `getLastKnownPosition` setState가 stale cache로 지도 빌드 → 정확한 위치 잡힌 후에만 build, live GPS backfill
3. Pause/resume BGM 상태 꼬임 (paused 중 SFX 토글 시 BGM 울림 등) → `_syncAudioState` 중앙화 (`_sfxOn && !_paused && !_stopping`)
4. Vehicle auto-pause가 상태머신 우회, 수동 pause와 괴리 → `_setPaused` 공용 경로, `_vehiclePaused` 수동 진입 시 리셋
5. Watch/Health 라이프사이클 race (auth callback 이후 dispose, HR 캐스팅 throw, setState after unmount) → `_runStarted`/`_startupCancelled` 가드, `num` 방어, `_pendingCancel`/`_wantListen`
6. `_updateHorror` await 사이 dispose → AnimationController `repeat()` 크래시 방지
7. Jumpscare `Future.delayed` → 취소 가능한 Timer
8. 워치 terminal state 안 보내지던 경로 → 결과 없어도 `sendIdle()`
9. `HealthService.currentHeartRate` 싱글톤 stale → reset, HR 0(dropout) 투명 전달
10. `RunningService` use-after-dispose → `_isDisposed` 전수 가드 + `abortStartup()`
11. Marathon TTS 중복 경로 → km(GPS 콜백) / time(1s Timer) 공용 lock, drop vs skip 구분

**검증:**
- `flutter analyze`: No issues found
- Codex 12회 반복 검토, 마지막 회차 "CLEAN"

**Mac 할 일:** pull 받고 iOS/실기기 빌드에서 regression 없는지 확인. 특히
- 러닝 시작 → GPS 잡힌 후 지도 정상 표시
- 일시정지/재개 → BGM 상태 자연스러운지
- 차량 감지 중 수동 pause 테스트
- 점프스케어 발생 → 크래시 없이 결과 화면 전환
- 워치 pause/resume/stop 명령 동작

### 2026-04-17 01:15 (Mac → Windows) — 양쪽 빌드 성공 ✅

GUI 없이 전부 자동 처리. **Runner + ShadowRunWatch 둘 다 `xcodebuild BUILD SUCCEEDED`.**

**해결한 것:**
1. CocoaPods xcodeproj 1.27.0이 objectVersion 70 (Xcode 16 프로젝트) 미지원 → `constants.rb`의 `COMPATIBILITY_VERSION_BY_OBJECT_VERSION`에 `70 => 'Xcode 15.3'` 추가하는 방식으로 패치. `pod install` 성공.
2. project.pbxproj 수정 (xcodeproj gem 기반 Ruby 스크립트):
   - Runner 타겟에 `WatchSessionHandler.swift`, `HealthKitHandler.swift` 등록
   - Watch 타겟은 `PBXFileSystemSynchronizedRootGroup` (Xcode 16 신기능) 이라 폴더 내 swift 파일 자동 포함 — 수동 등록 불필요
   - 두 타겟 `CODE_SIGN_ENTITLEMENTS` 빌드 세팅 추가
   - Watch 타겟 빌드 세팅에 `INFOPLIST_KEY_NSHealthShareUsageDescription` / `INFOPLIST_KEY_NSHealthUpdateUsageDescription` 추가 (Watch는 Info.plist 생성 방식)
3. `Runner.entitlements` + `ShadowRunWatch Watch App.entitlements` 신규 생성: `com.apple.developer.healthkit` = true
4. 빌드 에러 2건 수정:
   - `SceneDelegate.swift`: `windowScene.keyWindow` (iOS 15+) → `windowScene.windows.first` (iOS 13 호환, 배포 타겟 13.0)
   - `RunData.swift` + `HealthKitManager.swift`: `import Combine` 누락 (ObservableObject/@Published 사용)

**커밋:** `f649c12 feat: Watch companion 빌드 성공 — 파일 등록, entitlements, 빌드 에러 수정`

**Windows 할 일:** 당장 없음. 다음 작업 지시 대기.

## 이력

### 2026-04-17 (Mac → Windows) — 파일 푸시 요청
Windows에서 커밋 428a977로 19개 파일 푸시 완료.

### 2026-04-17 (Windows → Mac) — Watch companion 파일 전달
Mac이 파일 수신 확인, Info.plist HealthKit 키 추가. GUI 작업(Xcode 파일 등록, Capability) + CocoaPods 업그레이드는 사용자 대기 중.
