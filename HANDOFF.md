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

### 2026-04-18 10:40 (Mac → Windows) — 백그라운드 오디오 코드측 보강 + iOS 빌드 OK

**Windows 03:30 요청(백그라운드 audio 끊김) 중 코드로 고칠 수 있는 부분 반영.**

**수정한 것 (`lib/main.dart`):**
- AudioSession category options을 **동적 분기**로 전환
  - 기본 (externalMusicMode=false): `AVAudioSessionCategoryOptions.none` — 앱이 iOS "primary audio app" 으로 선언 → 백그라운드 장시간 러닝 중 오디오 재생을 근거로 앱 유지 시간 연장
  - externalMusicMode=true: `AVAudioSessionCategoryOptions.mixWithOthers` — Spotify 등과 섞임
  - Android focus type도 동일하게 분기 (`gain` vs `gainTransientMayDuck`)
- `BgmPreferences.I.loadSaved()` 를 AudioSession 설정 **앞으로** 이동 → 세션이 저장된 외부음악 설정 반영
- `externalMusicMode` 토글 시 즉시 세션 재설정 (listener)
- `session.setActive(true)` 명시 호출
- `session.interruptionEventStream` 전역 구독 → interruption 종료 시 `setActive(true)` 로 세션 재활성화 (just_audio 내장 handleInterruptions=true 와 조합해 전화·알람 후 BGM 복원 안정성 ↑)

**이전 설정 문제:** `mixWithOthers`가 항상 켜져 있어 외부 음악을 안 쓰는 대부분 사용자도 non-primary audio app 취급 → 화면 꺼진 채 오래 달리면 iOS가 앱 suspension 을 허용하는 창이 생겨 BGM 끊김 가능. 이번 수정으로 **기본 러닝 시 BGM 장시간 지속성 개선** 예상.

**서비스 레벨 interruption 리스너는 추가 안 함:**
- `just_audio`는 기본 `handleInterruptions=true` — 플레이어 자체가 begin 시 자동 pause, ended 시 자동 resume
- main.dart 의 setActive(true) 훅이 세션 측 보강
- HorrorService/MarathonService 에 중복 구독은 **리스너 leak 위험**·복잡도만 늘어서 보류

**iOS 빌드 검증:**
```
flutter analyze → No issues found
flutter build ios --release --no-codesign → BUILD SUCCEEDED (59.4s, Runner.app 166.4MB)
```

**실기 검증은 사용자 테스트 필요 (Mac Claude가 직접 못 함):**
- ⚠️ 화면 끄고 5~10분 이상 러닝 → BGM 계속 나오는지
- ⚠️ 러닝 중 전화 받고 끊은 뒤 → BGM 자동 복원되는지
- ⚠️ 뺑뺑 돌기 (30m 이내 작은 원) → 거리 누적되는지 (Windows d1fa360 의 거리 기반 필터 수정 검증)
- ⚠️ 백그라운드 GPS 지속 — 상단 파란 바 유지되는지

**스토어 상품 등록 (19:20 요청)은 사용자 수동 필요:**
- Play Console / ASC: `shadowrun_pro` ₩13,900 로 가격 인상
- 신규 4개 상품 (`shadowrun_theme_mystic/noir/editorial/cyber` · ₩5,500) 등록
- Mac Claude 는 스토어 콘솔 접근 불가 → 사용자가 UI에서 직접 처리

**Windows 할 일:** 당장 없음. 실기 테스트 리포트 후 추가 대응 (만약 여전히 BGM 끊기면 `just_audio_background` 패키지 도입 검토).

## 이력

### 2026-04-18 03:30 (Windows → Mac) — iOS 백그라운드 audio·GPS 요청 → 코드측 처리됨
- 뺑뺑 돌기 (GPS 거리 기반 필터): Windows가 d1fa360 에서 처리
- 백그라운드 audio: Mac이 10:40 AudioSession 동적 분기 + setActive 훅으로 처리
- 백그라운드 GPS 지속·실기 검증: 사용자 테스트 대기

### 2026-04-17 19:20 (Windows → Mac) — 테마 시스템 도입 · 스토어 상품 등록 요청
- 테마 인프라(T1 Pure + T3 Mystic 1차) 구현 완료 — Windows 커밋
- iOS 빌드: Mac 이 release 빌드 성공 확인 (2026-04-18 10:40)
- 스토어 상품 등록 (Play Console / ASC): **사용자 수동 작업 남음** — `shadowrun_pro` ₩13,900 + 4개 테마 상품 ₩5,500

### 2026-04-17 03:10 (Windows → Mac) — 라이프사이클 대대적 리팩토링 (bbe3487)
running_screen + services 버그픽스 11건 (GPS silent data loss, NaverMap stale cache, pause BGM 상태머신, vehicle auto-pause, watch/health race, AnimationController dispose race, jumpscare timer, watch terminal state, HR dropout, use-after-dispose, marathon TTS 중복). Codex 12회차 CLEAN, flutter analyze 깨끗. Mac 빌드 검증 완료 (01:15 블록 + 10:40 재확인).

### 2026-04-17 01:15 (Mac → Windows) — Runner + ShadowRunWatch 빌드 성공
CocoaPods xcodeproj 패치(objectVersion 70), project.pbxproj 수정(파일 등록·entitlements·Watch INFOPLIST 키), Runner/Watch entitlements 신규, SceneDelegate iOS 13 호환, Combine import. 커밋 f649c12.



### 2026-04-17 (Mac → Windows) — 파일 푸시 요청
Windows에서 커밋 428a977로 19개 파일 푸시 완료.

### 2026-04-17 (Windows → Mac) — Watch companion 파일 전달
Mac이 파일 수신 확인, Info.plist HealthKit 키 추가. GUI 작업(Xcode 파일 등록, Capability) + CocoaPods 업그레이드는 사용자 대기 중.
