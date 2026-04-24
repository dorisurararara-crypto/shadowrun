# Shadow Run v31 실 사용자 꼼꼼 테스트 계획서

**목표**: 표면적 "화면 전환 완료" 를 넘어 **게임 메커닉 / 데이터 정확성 / 시각 요소 / 오디오 발동 타이밍** 까지 하나하나 검증. 사용자 입장 "실제로 작동하고 재미있는가" 를 증명.

작성: 2026-04-24. v31 build.

## 테스트 레이어

| 레이어 | 내용 | 현황 |
|---|---|---|
| L1 빌드 smoke | analyze / debug build / install | ✅ 통과 |
| L2 화면 렌더 | 각 테마 × 각 화면 크래시 없음 | ✅ 5 × 6 = 30/30 (25 + 자유러닝 PoC + 도플갱어) |
| L3 네비게이션 flow | 홈→prepare→running→result | 🟡 신규 3 테마 × 3 모드 = 9/9 / 기존 pure·mystic 홈 CTA 매핑 미완 |
| L4 오디오 이벤트 발동 | signature SFX / TTS 정확 파일 재생 | 🟡 **start** 이벤트만 검증. near/critical/checkpoint/regained/victory/defeat 는 미검증 |
| L5 게임 메커닉 | 도플갱어 추격 상태 전환, threat 변화, km 체크포인트, pace 비교 | ❌ |
| L6 시각 요소 | 지도 마커(플레이어/도플갱어), 테마 UI 디테일 | ❌ (screenshot 만 수집) |
| L7 데이터 정확성 | distance_m / duration_s / avg_pace / calories 계산 | ❌ |
| L8 설정·기록·분석 상호작용 | 각 버튼·토글·필터 동작 | ❌ |

## A. 도플갱어 모드 꼼꼼 (신규 3 테마 → 기존 2 테마 확장)

| ID | 항목 | 검증 방법 | 자동화 |
|---|---|---|---|
| A1 | 세션 시작 직후 `_shadowInitialLeadM=200` (그림자 200m 리드) | `RunningService` debugPrint 추가 → 로그에서 `shadowInitialLead=200` 확인 | 🟢 |
| A2 | GPS 재생 시 플레이어/도플갱어 상대 이동 | 30s 간 `pacemakerPoint` 로그 추출, 거리 감소 확인 | 🟢 |
| A3 | ThreatLevel 전환 순서: aheadFar→aheadMid→aheadClose→warningFar→warningClose→dangerFar→dangerClose→critical | `HorrorService._currentLevel` 전환 debugPrint 추가 | 🟢 |
| A4 | 각 전환 시 테마 TTS near_shadow/critical/regained 발동 | `[ThemeTts] play event=X` 로그 확인 | 🟢 |
| A5 | 각 전환 시 SfxService.themeNearShadow 발동 | `[SfxTheme] themeNearShadow` 로그 | 🟢 |
| A6 | BGM 변화: 초기→chase_mid→chase_critical | `_pickBgmFile` 반환값 로그 → `chase_mid/chase_critical` 변화 | 🟢 |
| A7 | 잡힘 (caught): `challenge_result='lose'` | DB runs 테이블 확인 | 🟢 |
| A8 | Result 화면 진입 + defeat TTS | `[ThemeTts] play event=defeat` + screenshot | 🟢 |
| A9 | 탈출 (escape): `challenge_result='win'` + victory TTS | DB 확인 + 로그 | 🟢 |
| A10 | 지도 stickFigure(플레이어) + shadow marker 표시 | screenshot 육안 (md5 비교로 변화만 확증) | 🟡 |

## B. 자유 러닝 꼼꼼 (신규 3 테마)

| ID | 항목 | 검증 방법 | 자동화 |
|---|---|---|---|
| B1 | distance_m 계산 정확성 (GPS 4 waypoints ≈ 2km) | DB `runs.distance_m` > 0 + 기대치 ±10% | 🟢 |
| B2 | 1km 첫 통과: themeCheckpoint SFX + checkpoint_1km TTS | `[SfxTheme] themeCheckpoint` + `[ThemeTts] play event=checkpoint_1km` | 🟢 |
| B3 | 5km 통과: encourage_early TTS (marathon 한정으로 구현됨, freerun 에 없음 확인 필요) | 로그 미발생이면 구현 누락 → 코드 수정 | 🟢 |
| B4 | 10km 통과: encourage_late TTS | 위와 동일 | 🟢 |
| B5 | 러닝 종료: victory TTS + doorClose SFX | 로그 확인 | 🟢 |

## C. 전설의 마라토너 꼼꼼 (신규 3 테마)

| ID | 항목 | 자동화 |
|---|---|---|
| C1 | Legend runner 페이스 연동 (킵초게 2:52/km 등) | 🟢 DB / 로그 |
| C2 | 페이스 비교 음성 ("더 빠름/느림") | 🟢 |
| C3 | km 체크포인트 음성 (분:초 포함) | 🟢 |
| C4 | 결승 victory | 🟢 |

## D. 설정/기록/분석 상호작용 (5 테마)

| ID | 항목 | 자동화 |
|---|---|---|
| D1 | 설정 → 언어 ko/en 전환 즉시 UI 반영 | 🟢 DB + hierarchy 재덤프 |
| D2 | 설정 → 테마 picker 에서 테마 변경 후 홈 즉시 반영 | 🟢 |
| D3 | 기록 → 스와이프 삭제 (Dismissible) | 🟡 Maestro swipe |
| D4 | 기록 → 롱프레스 이름 편집 | 🟡 |
| D5 | 기록 → tap → Result 진입 | 🟢 |
| D6 | 분석 → PRO off (is_pro=false) 시 lock 오버레이 | 🟢 DB + screenshot |
| D7 | 분석 → PRO on 시 차트 렌더 | 🟢 |

## E. 알려진 제한 & 전제

- Maestro `tapOn` 이 composite GestureDetector 에서 실제 hit test 위치와 어긋날 수 있음 (경험: noir 자유러닝 flaky).
- Flutter viewport 밖 위젯은 semantic tree 에 미포함 → mystic 홈 freerun 카드처럼 스크롤 필요.
- 시각 요소(지도 마커 위치, 애니메이션) 자동 단위 검증 불가 → screenshot 보관 후 사용자 육안.
- pure/mystic 홈 도플갱어·마라톤 CTA 매핑은 기존 테마 UI 관련, v30 검증 범위 밖.

## 실행 순서 (현재 세션)

1. ✅ 계획서 저장 + 커밋
2. 🔲 RunningService / HorrorService 에 debug print 추가 (A1, A3, A6 준비)
3. 🔲 도플갱어 긴 시뮬레이션 flow (A1~A9) — 러닝 90초 유지해서 threat 전환 관찰
4. 🔲 자유 러닝 (B1~B5): 3 테마 × 2km 러닝 → DB 검증
5. 🔲 마라톤 (C1~C4): 3 테마 × 2km × legend 선택 → 로그 검증
6. 🔲 설정/기록/분석 상호작용 (D1~D7)
7. 🔲 발견된 이슈 수정 → 재검증

## 향후 세션

- pure/mystic 홈 CTA 스크롤/매핑 문제 해결 (Flutter widget scroll 컨트롤 개선 or Maestro 좌표 기반 tap)
- L6 시각 요소 자동화 (이미지 diff 기반)
- TestFlight 실기 cross-check (배포 빌드는 AX 비활성이라 자동화 불가, 사용자 수동)
