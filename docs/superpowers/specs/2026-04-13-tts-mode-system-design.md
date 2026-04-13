# TTS 모드 시스템 + 코드 수정 설계

## 1. 모드 시스템

### 러닝 모드 3가지

| 모드 | 진입 방식 | TTS 음성 | 호러 효과 |
|------|----------|---------|----------|
| 도플갱어 | 기록 상세 → "도전" 버튼 | Harry/Callum/Drill (설정) | 공포+비네트+점프스케어 |
| 마라토너 | 새 러닝 시작 시 모드 선택 | Drill 고정 | 없음 |
| 자유 러닝 | 새 러닝 시작 시 모드 선택 | Harry/Callum/Drill (설정) | 없음 |

## 2. 도플갱어 모드 변경사항

### 출발점 체크
- 원래 기록 시작점에서 200m 이내에서만 도전 가능
- 200m 밖이면 "기록한 장소 근처에서 시작해주세요" 안내

### 앞서고 있을 때 TTS (신규)
- 0~50m 앞섬 → `tts_ahead_close` (다크 톤)
- 50~150m 앞섬 → `tts_ahead_mid` (혼합 톤)
- 150m+ 앞섬 → `tts_ahead_far` (격려 톤)

### 전환 TTS (신규)
- 앞서다가 다시 뒤처질 때 → `tts_losing_lead`

### 패배 TTS (신규)
- 도전 패배 시 → `tts_defeated`

## 3. 자유 러닝 모드

- 시작 TTS: `tts_start_solo` (6변형 랜덤)
- 종료 TTS: `tts_end_solo` (6변형 랜덤)
- km 스플릿: 기존 flutter_tts 유지

## 4. 마라토너 모드

### 시작/종료
- 시작: `tts_marathon_start` (6변형 랜덤)
- 종료: `tts_marathon_end` (6변형 랜덤)

### 거리별 격려 + 러닝 지식
- 1,2,3,4,5,7,10,15,20km (9시점)
- 각 시점마다 4변형 랜덤 재생

### 페이스별 피드백
- 과거 평균 페이스 대비 비교
- 아주 빠름 (20%+ 빠름): 4변형
- 좋은 페이스 (비슷/약간 빠름): 4변형
- 느려지고 있음 (직전km 대비 하락): 4변형
- 많이 느림 (20%+ 느림): 4변형

## 5. 스타디움 피날레

- 설정에서 ON/OFF
- 목표 거리 또는 종료 직전 관중 함성 효과음
- 모든 모드에서 동작

## 6. 기존 TTS 영어 추가

- tts_start_en (3음성)
- tts_warning2_en (3음성)
- tts_danger2_en (3음성)
- tts_survived_en (3음성)

---

## TTS 대사 전체 목록

### A. 자유 러닝 — 시작 (6변형 × 3음성 × 2언어 = 36개)

| # | 한국어 | 영어 | Audio Tag |
|---|--------|------|-----------|
| 1 | 기록을 남겨. 달려. | Leave your mark. Run. | [commanding] |
| 2 | 준비됐지? 출발. | Ready? Go. | [stern] |
| 3 | 오늘의 너를 증명해. | Prove yourself today. | [commanding] |
| 4 | 달려. 생각은 나중에. | Run. Think later. | [firm] |
| 5 | 시작이 반이야. 가자. | Starting is half the battle. Let's go. | [warm] |
| 6 | 몸이 원하고 있어. 움직여. | Your body wants this. Move. | [calm] |

### B. 자유 러닝 — 종료 (6변형 × 3음성 × 2언어 = 36개)

| # | 한국어 | 영어 | Audio Tag |
|---|--------|------|-----------|
| 1 | 수고했어. 기록이 저장됐다. | Good work. Record saved. | [warm] |
| 2 | 오늘도 해냈어. 대단해. | You did it again. Impressive. | [warm] |
| 3 | 끝까지 뛰었어. 그게 다야. | You ran to the end. That's all that matters. | [calm] |
| 4 | 잘 뛰었어. 내일 또 보자. | Good run. See you tomorrow. | [friendly] |
| 5 | 오늘 기록, 기억해둬. | Remember today's record. | [commanding] |
| 6 | 멈추지 않았어. 그게 실력이야. | You didn't stop. That's strength. | [stern] |

### C. 마라토너 — 시작 (6변형 × 3음성 × 2언어 = 36개)

| # | 한국어 | 영어 | Audio Tag |
|---|--------|------|-----------|
| 1 | 오늘도 나왔군. 좋아, 같이 뛰자. | You showed up. Good. Let's run. | [commanding] |
| 2 | 마라톤은 한 발짝부터야. 시작하자. | A marathon starts with one step. Let's begin. | [calm] |
| 3 | 몸 상태 어때? 일단 천천히 가자. | How's your body? Let's start slow. | [warm] |
| 4 | 오늘의 목표는 어제보다 한 발 더. | Today's goal: one step more than yesterday. | [stern] |
| 5 | 좋아. 워밍업부터 가볍게. | Good. Easy warmup first. | [friendly] |
| 6 | 또 왔어? 꾸준하군. 가자. | Back again? Consistent. Let's go. | [commanding] |

### D. 마라토너 — 거리별 (9시점 × 4변형 × 3음성 × 2언어 = 216개)

#### 1km
| # | 한국어 | 영어 | Audio Tag |
|---|--------|------|-----------|
| 1 | 좋아, 처음 1킬로는 워밍업이야. 어깨 힘 빼고, 팔은 90도로 유지해. | First kilometer is warmup. Drop your shoulders, keep arms at 90 degrees. | [commanding] |
| 2 | 1킬로 통과. 몸이 풀리기 시작했어. | 1K done. Your body is loosening up. | [calm] |
| 3 | 1킬로. 아직 시작이야. 페이스 서두르지 마. | 1K. Still the beginning. Don't rush your pace. | [stern] |
| 4 | 첫 1킬로 좋아. 이 리듬 기억해. | First 1K, good. Remember this rhythm. | [warm] |

#### 2km
| # | 한국어 | 영어 | Audio Tag |
|---|--------|------|-----------|
| 1 | 호흡이 중요하다. 코로 들이쉬고, 입으로 내쉬어. 리듬을 만들어. | Breathing matters. In through the nose, out through the mouth. Find your rhythm. | [commanding] |
| 2 | 2킬로. 호흡이 안정되기 시작하는 구간이야. | 2K. This is where breathing stabilizes. | [calm] |
| 3 | 2킬로 지점. 상체를 곧게 세워. 허리가 구부러지면 폐가 좁아져. | 2K mark. Keep your torso upright. Slouching compresses your lungs. | [stern] |
| 4 | 좋아, 2킬로. 워밍업 끝. 이제부터 진짜야. | Good, 2K. Warmup done. Now it's real. | [commanding] |

#### 3km
| # | 한국어 | 영어 | Audio Tag |
|---|--------|------|-----------|
| 1 | 3킬로. 발 착지를 확인해. 발 중간으로 착지하면 무릎에 무리가 덜 가. | 3K. Check your footstrike. Midfoot landing reduces knee stress. | [commanding] |
| 2 | 3킬로 돌파. 좋은 흐름이야. 유지해. | 3K cleared. Good flow. Maintain it. | [warm] |
| 3 | 3킬로. 팔 스윙을 확인해. 좌우로 흔들지 말고, 앞뒤로. | 3K. Check your arm swing. Forward and back, not side to side. | [stern] |
| 4 | 여기서부터 리듬이 잡혀야 해. 3킬로, 잘하고 있어. | This is where rhythm locks in. 3K, doing well. | [calm] |

#### 4km
| # | 한국어 | 영어 | Audio Tag |
|---|--------|------|-----------|
| 1 | 시선은 전방 20미터. 고개 숙이면 폼이 무너진다. | Eyes 20 meters ahead. Drop your head, lose your form. | [commanding] |
| 2 | 4킬로. 목과 어깨 긴장 풀어. 힘 빼면 더 빨라져. | 4K. Release neck and shoulder tension. Relaxing makes you faster. | [calm] |
| 3 | 4킬로. 발목 힘 빼고 자연스럽게 굴려. | 4K. Relax your ankles and roll naturally. | [stern] |
| 4 | 잘 오고 있어. 4킬로. 몸이 기억하기 시작했어. | Coming along well. 4K. Your body is starting to remember. | [warm] |

#### 5km
| # | 한국어 | 영어 | Audio Tag |
|---|--------|------|-----------|
| 1 | 5킬로 돌파. 대단해. 여기서부터가 진짜 러닝이야. | 5K done. Impressive. Real running starts here. | [commanding] |
| 2 | 5킬로. 수분 보충 타이밍이야. 목 마르기 전에 마셔. | 5K. Time to hydrate. Drink before you're thirsty. | [stern] |
| 3 | 5킬로, 반을 넘겼어. 정신력 싸움이 시작된다. | 5K, past halfway. The mental game begins. | [calm] |
| 4 | 5킬로. 대부분 여기서 멈춰. 넌 계속 가고 있어. | 5K. Most people stop here. You're still going. | [warm] |

#### 7km
| # | 한국어 | 영어 | Audio Tag |
|---|--------|------|-----------|
| 1 | 힘들 때 보폭을 줄여. 작은 보폭이 더 효율적이야. | When it gets hard, shorten your stride. Smaller steps are more efficient. | [commanding] |
| 2 | 7킬로. 엉덩이 근육을 써. 다리만으로 뛰면 금방 지쳐. | 7K. Use your glutes. Legs alone tire you fast. | [stern] |
| 3 | 7킬로. 중반 고비야. 여기서 무너지지 마. | 7K. Mid-run wall. Don't break here. | [firm] |
| 4 | 7킬로 통과. 네 몸은 이미 적응했어. 믿어. | 7K cleared. Your body has adapted. Trust it. | [warm] |

#### 10km
| # | 한국어 | 영어 | Audio Tag |
|---|--------|------|-----------|
| 1 | 10킬로. 너 지금 상위 10% 러너야. 멈추지 마. | 10K. You're in the top 10% of runners now. Don't stop. | [commanding] |
| 2 | 10킬로 돌파. 여기까지 온 건 실력이야. | 10K done. Getting here is skill, not luck. | [warm] |
| 3 | 10킬로. 다리가 무거울 거야. 정상이야. 계속 가. | 10K. Your legs feel heavy. That's normal. Keep going. | [calm] |
| 4 | 10킬로. 프로 선수들도 여기서 페이스 점검해. 너도 확인해봐. | 10K. Even pros check pace here. Check yours too. | [stern] |

#### 15km
| # | 한국어 | 영어 | Audio Tag |
|---|--------|------|-----------|
| 1 | 15킬로. 수분 보충 잊지 마. 목마를 때는 이미 늦은 거야. | 15K. Don't forget hydration. If you're thirsty, you're already late. | [stern] |
| 2 | 15킬로. 여기까지 뛰는 사람은 많지 않아. 자부심을 가져. | 15K. Not many run this far. Be proud. | [warm] |
| 3 | 15킬로. 코어에 힘 줘. 허리가 흔들리면 에너지 낭비야. | 15K. Engage your core. A wobbly torso wastes energy. | [commanding] |
| 4 | 15킬로 통과. 마라톤의 벽은 아직이야. 지금은 즐겨. | 15K cleared. The marathon wall is still ahead. Enjoy this. | [calm] |

#### 20km
| # | 한국어 | 영어 | Audio Tag |
|---|--------|------|-----------|
| 1 | 20킬로. 하프 마라톤 거리야. 넌 이미 대단한 러너야. | 20K. Half marathon distance. You're already a great runner. | [warm] |
| 2 | 20킬로. 여기서부터는 정신이 몸을 이끌어. 포기하지 마. | 20K. From here, mind leads body. Don't give up. | [commanding] |
| 3 | 20킬로. 글리코겐이 바닥나기 시작해. 에너지 보충 생각해. | 20K. Glycogen is running low. Consider refueling. | [stern] |
| 4 | 20킬로 돌파. 전설은 여기서 만들어져. | 20K done. Legends are made right here. | [excited] |

### E. 마라토너 — 페이스별 (4상황 × 4변형 × 3음성 × 2언어 = 96개)

#### 아주 빠름 (평소 대비 20%+ 빠름)
| # | 한국어 | 영어 | Audio Tag |
|---|--------|------|-----------|
| 1 | 미쳤어, 오늘 날아다니고 있어. | You're flying today. Unreal. | [excited] |
| 2 | 이 페이스 실화냐? 역대급이다. | Is this pace for real? This is historic. | [excited] |
| 3 | 지금 너 최고의 날이야. 기억해둬. | This is your best day. Remember it. | [warm] |
| 4 | 엔진이 완전히 걸렸어. 그대로 가. | Engine's fully fired up. Keep it. | [commanding] |

#### 좋은 페이스 (평소와 비슷하거나 약간 빠름)
| # | 한국어 | 영어 | Audio Tag |
|---|--------|------|-----------|
| 1 | 안정적이야. 이 리듬 유지해. | Steady. Hold this rhythm. | [calm] |
| 2 | 좋은 페이스야. 몸이 기억하고 있어. | Good pace. Your body remembers. | [warm] |
| 3 | 딱 좋아. 무리하지 말고 이대로. | Perfect. Don't push, just maintain. | [calm] |
| 4 | 꾸준함이 실력이야. 잘하고 있어. | Consistency is skill. You're doing well. | [warm] |

#### 느려지고 있음 (직전km 대비 페이스 하락)
| # | 한국어 | 영어 | Audio Tag |
|---|--------|------|-----------|
| 1 | 페이스 떨어지고 있어. 보폭을 줄여봐. | Pace is dropping. Try shorter strides. | [stern] |
| 2 | 느려지고 있다. 팔을 더 써봐. | You're slowing. Use your arms more. | [commanding] |
| 3 | 지금이 고비야. 여기서 버텨. | This is the wall. Push through. | [stern] |
| 4 | 힘들지? 호흡부터 다시 잡아. | Tough? Reset your breathing first. | [calm] |

#### 많이 느림 (평소 대비 20%+ 느림)
| # | 한국어 | 영어 | Audio Tag |
|---|--------|------|-----------|
| 1 | 멈추지 마. 느려도 뛰고 있으면 된다. | Don't stop. Slow is still running. | [stern] |
| 2 | 걷고 싶지? 30초만 더 버텨봐. | Want to walk? Give me 30 more seconds. | [commanding] |
| 3 | 포기는 없어. 한 발만 더 내밀어. | No quitting. One more step. | [stern] |
| 4 | 느린 게 부끄러운 게 아니야. 멈추는 게 부끄러운 거야. | Slow isn't shameful. Stopping is. | [commanding] |

### F. 마라토너 — 종료 (6변형 × 3음성 × 2언어 = 36개)

| # | 한국어 | 영어 | Audio Tag |
|---|--------|------|-----------|
| 1 | 수고했다. 오늘 뛴 만큼 내일 더 강해진다. 스트레칭 잊지 마. | Good work. Every run makes you stronger. Don't skip the stretch. | [warm] |
| 2 | 끝까지 완주했다. 이게 진짜 실력이야. | You finished the whole thing. That's real strength. | [commanding] |
| 3 | 잘 뛰었어. 쿨다운 5분, 스트레칭 10분. 회복이 훈련이야. | Good run. 5 minutes cooldown, 10 minutes stretching. Recovery is training. | [stern] |
| 4 | 대단해. 오늘 네 몸이 한 단계 올라갔어. | Impressive. Your body leveled up today. | [warm] |
| 5 | 수고했어. 단백질 30분 안에 섭취해. 근회복에 중요해. | Good work. Get protein within 30 minutes. Key for muscle recovery. | [stern] |
| 6 | 오늘도 해냈군. 내일 또 보자. | You did it again. See you tomorrow. | [friendly] |

### G. 도플갱어 — 앞서고 있을 때 (3단계 × 3음성 × 2언어 = 18개)

| 파일명 | 한국어 | 영어 | Audio Tag |
|--------|--------|------|-----------|
| tts_ahead_close | 그림자가 뒤처지고 있어... 하지만 아직 가까워. | The shadow's falling behind... but it's still close. | [whispers] |
| tts_ahead_mid | 그림자가 멀어지고 있어. 이 페이스 유지해. | The shadow is fading. Hold this pace. | [calm] |
| tts_ahead_far | 완전히 따돌렸어. 새 기록이다, 계속 가! | You've left it behind. New record, keep going! | [excited] |

### H. 도플갱어 — 전환 (1개 × 3음성 × 2언어 = 6개)

| 파일명 | 한국어 | 영어 | Audio Tag |
|--------|--------|------|-----------|
| tts_losing_lead | 그림자가 다시 다가온다. 속도 올려. | The shadow is catching up again. Pick it up. | [urgent] |

### I. 도플갱어 — 패배 (1개 × 3음성 × 2언어 = 6개)

| 파일명 | 한국어 | 영어 | Audio Tag |
|--------|--------|------|-----------|
| tts_defeated | 패배했습니다. | You lost. | [deadpan] |

### J. 기존 TTS 영어 추가 (4개 × 3음성 = 12개)

기존 한국어 대사의 영어 버전 생성 필요:
- tts_start_en
- tts_warning2_en
- tts_danger2_en
- tts_survived_en

---

## Voice Settings

| 설정 | 값 |
|------|---|
| model_id | eleven_v3 |
| stability | 0.7 |
| similarity_boost | 0.8 |
| style | 0.4 |
| speed | 0.9 |

## 음성 ID

| 이름 | ID |
|------|---|
| Harry | SOYHLrjzK2X1ezoPC6cr |
| Callum | N2lVS1w4EtoT3dr4eOWO |
| Drill Sergeant | DGzg6RaUqxGRTHSBjfgF |

## 파일 네이밍 규칙

- 기본(Harry): `{name}.mp3`
- Callum: `{name}_callum.mp3`
- Drill: `{name}_drill.mp3`
- 영어: `{name}_en.mp3`
- 영어+Callum: `{name}_en_callum.mp3`
- 영어+Drill: `{name}_en_drill.mp3`
- 변형: `{name}_{n}.mp3` (n = 1~6)

## 코드 수정 사항

1. 모드 선택 UI: 새 러닝 시작 시 도플갱어/마라토너/자유러닝 선택
2. horror_service.dart: 앞서고 있을 때 3단계 + 전환 TTS
3. marathon_service.dart: 마라토너 모드 전용 서비스 (신규)
4. running_service.dart: 출발점 200m 체크
5. running_screen.dart: 모드별 TTS 분기 + 패배 TTS
6. settings_screen.dart: 스타디움 피날레 ON/OFF 토글
7. 페이스 비교 로직: DB에서 과거 평균 페이스 조회 후 비교
