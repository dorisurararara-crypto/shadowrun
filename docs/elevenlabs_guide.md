# ElevenLabs 완전 레퍼런스 가이드 (한국어)

> 최신 확인 일자: **2026-04-23**
> 대상 프로젝트: Shadow Run (Flutter / 한국어 공포 러닝 앱)
> 목적: TTS 대량 생성, SFX/BGM 생성, Music 생성, Voice 관리 — 이 문서 하나로 모두 해결
> 출처: ElevenLabs 공식 문서 (`elevenlabs.io/docs/*`, `help.elevenlabs.io`), `elevenlabs-python` SDK, 공식 블로그, 커뮤니티 정리글(2026-04 기준)

---

## 목차

1. [인증 및 공통 규약](#1-인증-및-공통-규약)
2. [Text-to-Speech (TTS)](#2-text-to-speech-tts)
3. [Sound Effects (SFX / BGM)](#3-sound-effects-sfx--bgm)
4. [Music Generation (Eleven Music)](#4-music-generation-eleven-music)
5. [Voice Cloning / Voice Design](#5-voice-cloning--voice-design)
6. [기타 API (Dubbing, STT, Voice Changer, Agents, History)](#6-기타-api-dubbing-stt-voice-changer-agents-history)
7. [Python 실전 템플릿](#7-python-실전-템플릿)
8. [요금 / 크레딧 계산표](#8-요금--크레딧-계산표)
9. [실전 체크리스트 & 함정](#9-실전-체크리스트--함정)
10. [빠른 참조 (Cheat Sheet)](#10-빠른-참조-cheat-sheet)
11. [커버 범위 / 검증되지 않은 영역](#11-커버-범위--검증되지-않은-영역)

---

## 1. 인증 및 공통 규약

### 1.1 Base URL

```
https://api.elevenlabs.io
```

WebSocket 엔드포인트(TTS 스트리밍 입력):

```
wss://api.elevenlabs.io/v1/text-to-speech/{voice_id}/stream-input
```

### 1.2 API 키 발급

1. [elevenlabs.io](https://elevenlabs.io) 로그인 → 우측 상단 프로필 → **My Account** → **API Keys**
2. `Create API Key` 클릭. 다음을 지정할 수 있음.
   - **Scope 제한**: 접근 허용 엔드포인트 선택(TTS/STT/Voices/Agents 등).
   - **Credit quota**: 이 키에 할당할 월 크레딧 상한.
3. 생성된 키는 **한 번만** 노출됨. 안전하게 저장.

### 1.3 인증 헤더

ElevenLabs 는 **`xi-api-key`** 헤더 하나로 인증한다. Bearer 토큰 아님.

```http
POST /v1/text-to-speech/{voice_id} HTTP/1.1
Host: api.elevenlabs.io
xi-api-key: <YOUR_API_KEY>
Content-Type: application/json; charset=utf-8
```

Python SDK 는 내부적으로 동일한 헤더를 붙인다.

```python
from elevenlabs.client import ElevenLabs
client = ElevenLabs(api_key="xi-...")
```

### 1.4 환경변수 관례

ElevenLabs 는 공식적으로 **`ELEVENLABS_API_KEY`** 이름을 사용한다. 이 프로젝트의 기존 스크립트(`scripts/generate_bgm.py`, `scripts/generate_tts.py` 등) 와도 같은 이름을 사용한다.

```bash
# ~/.zshrc 또는 프로젝트 루트 .env
export ELEVENLABS_API_KEY="xi-..."
```

`python-dotenv` 사용 시:

```python
import os
from dotenv import load_dotenv
load_dotenv()
API_KEY = os.environ["ELEVENLABS_API_KEY"]
```

### 1.5 응답 메타데이터 헤더

TTS/SFX 호출 후 응답 헤더에서 크레딧 사용량과 요청 추적 정보가 반환된다.

| 헤더 | 설명 |
|------|------|
| `x-character-count` | 이번 요청에서 처리된 character 수 (TTS 만 해당) |
| `request-id` | 고유 요청 ID. 장애 리포트 시 필요 |

Python SDK 는 `with_raw_response` 로 원시 응답을 얻어야 헤더 접근이 가능.

### 1.6 Rate Limit (동시 요청 한도)

TTS 기준 **동시(concurrent) 요청** 한도는 구독 티어별로 다르다.

| 티어 | Concurrent |
|------|-----------|
| Free | 2 |
| Starter | 3 |
| Creator | 5 |
| Pro | 10 |
| Scale | 15 |
| Business | 15 |
| Enterprise | 협의 |

- Agents Platform / STT 는 별도 한도가 적용됨.
- **Burst pricing**: 주 한도의 **최대 3배**(최대 300 동시 호출)까지 일시적으로 허용되며, 초과 분은 **2배 요금**으로 과금된다.
- 429 `rate_limit_error` 가 뜨면 **지수 백오프** (1s → 2s → 4s → 8s …) 로 재시도.

### 1.7 에러 코드 & 재시도 전략

모든 에러 body 는 아래 형태.

```json
{
  "detail": {
    "type": "rate_limit_error",
    "code": "concurrent_limit_exceeded",
    "message": "Concurrent request limit exceeded.",
    "request_id": "req_...",
    "param": null
  }
}
```

| 코드 | 의미 | 재시도? | 처리 |
|------|------|---------|------|
| 400 | `validation_error` / `invalid_request` — 잘못된 body/파라미터 | ❌ | 요청을 수정. JSON 문법·필수 필드 확인. |
| 401 | `authentication_error` — API 키 누락/오타 | ❌ | `xi-api-key` 헤더 이름·값 검증. |
| 403 | `authorization_error` — 권한/구독 부족 | ❌ | 키 scope, 구독 티어 확인. |
| 404 | 리소스 없음 (예: voice_id 오타) | ❌ | `GET /v2/voices` 로 ID 확인. |
| 422 | 스키마 위반 — field 타입/범위 | ❌ | 에러 `detail` 의 `loc` 경로 참조. |
| 429 | `rate_limit_exceeded` / `concurrent_limit_exceeded` | ✅ | 지수 백오프. 동시 요청 감소. |
| 500 | 서버 내부 오류 | ✅ (단, 3회 이내) | 동일 요청 그대로 재시도. 지속되면 `request-id` 로 지원 문의. |
| 503 | 일시적 서비스 불가 | ✅ | 백오프 후 재시도. |

**재시도 권장 패턴** (3회, 지수 백오프):

```python
import time, random
def with_retry(fn, tries=3, base=1.0):
    last_err = None
    for i in range(tries):
        try:
            return fn()
        except Exception as e:
            last_err = e
            if i == tries - 1:
                raise
            sleep = base * (2 ** i) + random.random() * 0.5
            time.sleep(sleep)
    raise last_err
```

### 1.8 크레딧 시스템 개요

크레딧은 API 서비스마다 소비 단위가 다르다. (상세는 [§8](#8-요금--크레딧-계산표))

- **TTS**: 문자(character) 당. 모델별 배수(Flash/Turbo = 0.5, Multilingual v2 / English v1 = 1.0, Eleven v3 = 1.0).
- **SFX (Sound Effects)**: 초당 40 크레딧 (duration 지정 시).
- **Music**: 초당 ~100 크레딧(추정. API 가격표 기준 분당 $0.30).
- **Voice Changer (STS)**: 처리된 오디오 **1분당 1,000 크레딧**.
- **STT (Scribe)**: 시간 단위(분단위 과금).
- **Conversational AI (Agents)**: **분당 ~1,000 크레딧**.
- **Voice Cloning (IVC)**: **0 크레딧** (슬롯 제한 존재).
- **Voice Design**: **1,000 크레딧 / 저장** (미리듣기는 무료 시도 가능, 단 변동 있음 — ⚠️ 확인 필요).

### 1.9 출처

- <https://elevenlabs.io/docs/api-reference/authentication>
- <https://help.elevenlabs.io/hc/en-us/articles/27562020846481-What-are-credits>
- <https://help.elevenlabs.io/hc/en-us/articles/14312733311761-How-many-Text-to-Speech-requests-can-I-make-and-can-I-increase-it>
- <https://help.elevenlabs.io/hc/en-us/articles/19571824571921-API-Error-Code-429>
- <https://elevenlabs.io/docs/eleven-api/resources/errors>

---

## 2. Text-to-Speech (TTS)

### 2.1 엔드포인트

| 엔드포인트 | 용도 |
|-----------|------|
| `POST /v1/text-to-speech/{voice_id}` | 단일 오디오 파일 생성 (octet-stream) |
| `POST /v1/text-to-speech/{voice_id}/stream` | HTTP 스트리밍 응답 (text/event-stream) |
| `POST /v1/text-to-speech/{voice_id}/with-timestamps` | 오디오 + 문자별 타임스탬프 JSON |
| `POST /v1/text-to-speech/{voice_id}/stream/with-timestamps` | 스트리밍 + 타임스탬프 |
| `GET /v1/models` | 사용 가능 모델 목록 조회 |
| `GET /v2/voices` | 보이스 목록 (검색·페이지네이션) |

### 2.2 요청 Body 전체 스키마

**필수**

- `text` *(string)* — 합성할 텍스트.

**선택**

| 필드 | 타입 | 기본값 | 설명 |
|------|------|-------|------|
| `model_id` | string | `eleven_multilingual_v2` | [§2.3 참조](#23-모델-전수-비교) |
| `language_code` | string | `null` | ISO 639-1 (ex: `"ko"`). Flash/Turbo v2.5 에서 언어 강제. v3 는 자동 감지. |
| `voice_settings` | object | 보이스 기본값 | `{ stability, similarity_boost, style, use_speaker_boost, speed }` |
| `pronunciation_dictionary_locators` | array | `null` | 최대 3개. 사용자 정의 발음 사전 적용. |
| `seed` | int | `null` | 0~4294967295. 동일 시드면 결정적 출력. |
| `previous_text` | string | `null` | 바로 앞 문맥 텍스트. 톤·억양 연속성. |
| `next_text` | string | `null` | 바로 뒤 문맥 텍스트. |
| `previous_request_ids` | array[string] | `null` | 최대 3개. 이전 request_id 참조 (연속 생성의 정합성). |
| `next_request_ids` | array[string] | `null` | 최대 3개. |
| `apply_text_normalization` | `"auto"|"on"|"off"` | `auto` | 숫자·약어 정규화. |
| `apply_language_text_normalization` | bool | `false` | 언어별 정규화. |
| `use_pvc_as_ivc` | bool | `false` | PVC 보이스를 IVC 모드로 쓸 때. |

### 2.3 쿼리 파라미터

| 파라미터 | 기본값 | 설명 |
|---------|-------|------|
| `output_format` | `mp3_44100_128` | [§2.5 참조](#25-output_format-전수) |
| `optimize_streaming_latency` | `0` | 0=기본, 1≈−50%, 2≈−75%, 3=최대, 4=최대+정규화 비활성 |
| `enable_logging` | `true` | `false` 시 zero-retention(엔터프라이즈 전용) |

### 2.4 모델 전수 비교

| 모델 ID | 지원 언어 | 최대 문자 | 지연 시간 | 크레딧/문자 | 권장 용도 |
|---------|----------|----------|----------|------------|-----------|
| `eleven_v3` (alpha) | 70+ | 5,000 | ~1–2s | **1.0** | 감정 표현·드라마·내레이션·오디오태그. 실시간 부적합. |
| `eleven_multilingual_v2` | 29 | 10,000 | ~1–2s | **1.0** | 프리미엄 품질 더빙·오디오북·캐릭터. 한국어 안정. |
| `eleven_flash_v2_5` | 32 | 40,000 | **~75ms** | **0.5** | 실시간 에이전트·챗봇·대량 배치. |
| `eleven_flash_v2` | English only | 40,000 | ~75ms | 0.5 | 영어 전용 초저지연. |
| `eleven_turbo_v2_5` | 32 | 40,000 | ~250–300ms | 0.5 | Flash v2.5 대체 권장 (동일 품질·약간 높은 지연). |
| `eleven_turbo_v2` | English only | 40,000 | ~250ms | 0.5 | 구형. Flash v2 권장. |
| `eleven_english_v2` | English only | 5,000 | ~1s | 1.0 | 레거시. |
| `eleven_monolingual_v1` (= `eleven_english_v1`) | English only | 5,000 | ~1s | 1.0 | 레거시. |

**언어별 추천**

- **한국어 (Shadow Run 주 언어)**: `eleven_multilingual_v2` 가 가장 안정적. `eleven_v3` 도 한국어 가능하나 감정 태그 위주일 때 효과. Flash v2.5 는 짧고 명확한 안내음에 적합하나 장문에서는 억양 이질감 있음 (커뮤니티 보고).
- **영어 내레이션**: `eleven_v3` (몰입·감정) 또는 `eleven_multilingual_v2`.
- **실시간 에이전트**: `eleven_flash_v2_5`.

**모델별 기본 voice_settings 권장치** (커뮤니티/공식 best practice 종합)

| 목적 | stability | similarity_boost | style | use_speaker_boost |
|------|-----------|------------------|-------|-------------------|
| 한국어 긴 내레이션 (multilingual_v2) | 0.50–0.60 | 0.75 | 0.0 | true |
| 한국어 짧은 경고/알림 (Shadow Run 스타일) | 0.30–0.40 | 0.85–0.95 | 0.0–0.2 | true |
| 캐릭터 감정 연기 (v3) | 0.30 (Creative) / 0.50 (Natural) / 0.75 (Robust) | 0.75 | 0.3–0.5 | true |
| 실시간 에이전트 (flash v2.5) | 0.50 | 0.75 | 0.0 | false |

### 2.5 output_format 전수

요청별로 다음 중 하나를 쿼리스트링으로 지정.

**MP3**

- `mp3_22050_32`, `mp3_24000_48`
- `mp3_44100_32`, `mp3_44100_64`, `mp3_44100_96`, `mp3_44100_128` (**기본값**), `mp3_44100_192`

**PCM** (WAV 원시)

- `pcm_8000`, `pcm_16000`, `pcm_22050`, `pcm_24000`, `pcm_32000`, `pcm_44100`, `pcm_48000`

**WAV** (헤더 포함)

- `wav_8000`, `wav_16000`, `wav_22050`, `wav_24000`, `wav_32000`, `wav_44100`, `wav_48000`

**Opus**

- `opus_48000_32`, `opus_48000_64`, `opus_48000_96`, `opus_48000_128`, `opus_48000_192`

**전화 코덱**

- `ulaw_8000`, `alaw_8000`

**주의**

- `pcm_44100` 이상은 **Pro 이상 티어** 필요.
- `mp3_44100_192` 는 **Creator 이상**.
- WAV 는 PCM + 헤더. 편집 파이프라인에 유리. 파일이 약 10 배 크다는 점 유의.

### 2.6 Voice 선택

**(A) Pre-made default voices** (전체 계정 기본 제공, 영어 기준 최적화되나 다국어 작동)

| 이름 | voice_id | 성별 | 특징 |
|------|---------|------|------|
| Rachel | `21m00Tcm4TlvDq8ikWAM` | F | 젊음, 미국, 차분 |
| Bella | `EXAVITQu4vr4xnSDxMaL` | F | 젊음, 미국 |
| Antoni | `ErXwobaYiN019PkySvjV` | M | 미국, 편안 |
| Adam | `pNInz6obpgDQGcFmaJgB` | M | 중년, 미국, 깊음 |
| Brian | `nPczCjzI2devNBz1zQrb` | M | 중년, 미국, 깊음 (Shadow Run 기존 사용) |
| Daniel | `onwK4e9ZLuTAKqWW03F9` | M | 중년, 영국, 깊음 |
| Charlie | `IKne3meq5aSn9XLyUdCD` | M | 중년, 호주, 캐주얼 |
| Alice | `Xb7hH8MSUJpSbSDYk0k2` | F | 중년, 영국, 자신감 |
| Emily | `LcfcDJNUP1GQjkzn1xUU` | F | 젊음, 미국, 차분 |
| George | `JBFqnCBsd6RMkjVDRZzb` | M | 중년, 영국, 따뜻 |

> ⚠️ 확인 필요: ElevenLabs 는 수시로 default voices 를 교체/은퇴시킨다. 실제 사용 전 `GET /v2/voices?voice_type=default` 로 현재 라이브러리 확인 권장.

**(B) 한국어 추천 voices** (elevenlabs.io/text-to-speech/korean 페이지 기준)

- **Hyuk** — "Cold and Clear" (중저음 남성, 시리어스한 호러 내레이션에 적합)
- **Anna Kim** — "Tender, Calm and Clear" (여성, 부드러움)
- **Bin** — "Measured and Serious" (남성, 진중)
- **Hyunbin** — "Diplomatic, Clear and Measured" (남성, 안내방송형)
- **Selly Han** — "Warm, Calm and Steady" (여성, 따뜻)

> 위 5개는 Voice Library 에 등록된 커뮤니티 voice 라 **voice_id 는 각자 계정에서 `GET /v2/voices?search=Hyuk` 로 조회 후 My Voices 에 추가해야 사용 가능**하다.

**(C) Voice Library 검색**

```bash
curl "https://api.elevenlabs.io/v2/voices?search=Korean&page_size=50" \
  -H "xi-api-key: $ELEVENLABS_API_KEY"
```

응답은 `voices[].voice_id`, `name`, `category`, `labels`, `preview_url` 포함.

### 2.7 voice_settings 파라미터 해설

| 필드 | 범위 | 의미 |
|------|------|------|
| `stability` | 0.0–1.0 | 낮을수록 **표현력↑·일관성↓**. 높을수록 단조로움. 한국어 장문은 **0.50–0.60** 권장. |
| `similarity_boost` | 0.0–1.0 | 원본 보이스 유사도. 기본 **0.75**. 너무 높이면(0.95+) 아티팩트/지직. |
| `style` | 0.0–1.0 | 스타일 과장도. 기본 **0.0**. v3 alpha 는 0.3–0.5 가 드라마틱. |
| `use_speaker_boost` | bool | 특정 보이스의 특성 강조. 기본 true. 약간의 추가 지연. |
| `speed` | 0.7–1.2 | 재생 속도. 1.0 = 기본. 0.9 = 무게감·불안, 1.1 = 긴박. (v3/v2 후기 버전에서 지원) |

### 2.8 발음 사전 (Pronunciation Dictionaries)

고유명사·브랜드명·외래어 발음을 강제하려면 사전 업로드 후 locator 로 참조.

```python
client.pronunciation_dictionaries.create_from_rules(
    rules=[
        {"string_to_replace": "Shadow Run", "alias": "섀도우 런"},
        {"string_to_replace": "KM", "alias": "킬로미터"},
    ],
    name="shadowrun_ko"
)
```

호출 시:

```python
"pronunciation_dictionary_locators": [
    {"pronunciation_dictionary_id": "pd_...", "version_id": "v1"}
]
```

### 2.9 Eleven v3 Audio Tags

`eleven_v3` 모델은 **대괄호 태그**를 텍스트 안에 삽입해 감정/반응/이펙트를 지시할 수 있다.

**카테고리별 태그 (비공식 집계, 공식 지원 범위는 계속 확장)**

- **감정**: `[happy]`, `[sad]`, `[angry]`, `[excited]`, `[nervous]`, `[curious]`, `[mischievously]`, `[sorrowful]`, `[happily]`
- **전달**: `[whispers]` / `[whispering]`, `[shouts]` / `[shouting]`, `[speaking softly]`, `[sarcastic]`, `[calm]`
- **비언어 반응**: `[laughs]`, `[chuckles]`, `[giggles]`, `[sighs]`, `[gasps]`, `[crying]`, `[clears throat]`, `[snorts]`
- **신체 상태**: `[out of breath]`, `[coughs]`, `[shivering]`
- **악센트**: `[French accent]`, `[Korean accent]`, `[British accent]`, `[robotic voice]`
- **사운드 이펙트** (환경음): `[gunshot]`, `[explosion]`, `[clapping]`, `[door creaks]`, `[thunder]`
- **대화 흐름**: 중단·겹침·망설임 — 실험적. 다중 화자 대화에서 화자별 태그 할당 가능.

**사용 예시**

```text
[whispering] 뒤에 뭔가 있어... [gasps] 저거 봤어?
```

**주의사항**

- **stability 0.3–0.5 (Natural/Creative)** 에서만 태그가 잘 작동. 0.75(Robust) 에서는 태그를 무시하는 경향.
- 보이스의 원래 성격과 **상충하는 태그**(예: 속삭이는 보이스에 `[shouts]`)는 품질 저하.
- 여러 태그 겹치기 가능(예: `[angry][whispers]`) — 조합은 실험 필요.
- `<break time="1.5s" />` SSML 은 **v2.x 이하**만 지원. v3 는 `...` (ellipsis), 태그, 텍스트 구조로 pause 처리.

### 2.10 긴 텍스트 처리 전략

- 한 번에 **모델 최대 문자수 이하**로 분할. 문장 경계로 나눈다.
- 각 조각에 `previous_text` 와 `next_text` 를 붙여 **문맥 연속성** 유지.
- 더 강력한 정합성: `previous_request_ids` 로 바로 앞 요청 ID 를 묶는다 (최대 3개).
- 스트리밍 앱(TTS → 스피커): 문장 단위 200–500 자 청크가 WebSocket/HTTP 스트리밍 모두 적합.

### 2.11 출처

- <https://elevenlabs.io/docs/api-reference/text-to-speech/convert>
- <https://elevenlabs.io/docs/api-reference/text-to-speech/stream>
- <https://elevenlabs.io/docs/api-reference/text-to-speech/convert-with-timestamps>
- <https://elevenlabs.io/docs/overview/capabilities/text-to-speech>
- <https://elevenlabs.io/docs/overview/capabilities/text-to-speech/best-practices>
- <https://elevenlabs.io/docs/overview/models>
- <https://help.elevenlabs.io/hc/en-us/articles/17883183930129-What-models-do-you-offer-and-what-is-the-difference-between-them>
- <https://elevenlabs.io/blog/v3-audiotags>
- <https://elevenlabs.io/text-to-speech/korean>
- <https://www.webfuse.com/elevenlabs-cheat-sheet>

---

## 3. Sound Effects (SFX / BGM)

### 3.1 엔드포인트

```
POST /v1/sound-generation
```

**Content-Type**: `application/json`
**응답**: `application/octet-stream` (이진 오디오)

### 3.2 요청 Body

| 필드 | 타입 | 기본값 | 범위 | 설명 |
|------|------|-------|------|------|
| `text` | string | — | **최대 450자** | 영어 프롬프트 권장. 한국어 프롬프트는 품질 저하(커뮤니티 합의). |
| `model_id` | string | `eleven_text_to_sound_v2` | — | v2 는 loop 지원. |
| `duration_seconds` | number? | `null` (자동) | **0.5–30** | v2 기준. v1 시절 22초 제한은 **폐지**. |
| `prompt_influence` | number? | `0.3` | 0.0–1.0 | 높을수록 프롬프트 문자 그대로, 낮을수록 창의적 해석. |
| `loop` | bool | `false` | — | `eleven_text_to_sound_v2` 에서만 동작. 이음매 없이 반복 가능한 clip. |

### 3.3 쿼리 파라미터

- `output_format` — TTS 와 동일 리스트. 게임/BGM 에 `pcm_44100` 또는 `mp3_44100_192` 권장.

### 3.4 크레딧 비용

- `duration_seconds` 지정 시 **초당 40 크레딧** (공식 확인, 2026-04 기준).
- `duration_seconds` 미지정(자동) 시에도 모델이 결정한 길이 × 40 크레딧/초로 과금 (⚠️ 정책이 업데이트될 수 있어 확인 필요).

### 3.5 프롬프트 작성 원칙 (공식 + 커뮤니티)

1. **구체성**: 재료·크기·환경·거리·시간 전개를 명시.
   - 나쁨: `"scary sound"`
   - 좋음: `"low sub-bass drone building slowly over 10 seconds in a cavernous reverberant hall, distant high-pitched metallic scrape at the end"`
2. **오디오 산업 용어**: `whoosh`, `braam`, `impact`, `one-shot`, `ambience`, `drone`, `foley`, `stinger`, `riser`.
3. **환경/공간**: `"in a large cathedral"` vs `"in a small wooden room"` — 잔향 차이.
4. **시간 전개**: `"starts quietly, builds, then crashes"`.
5. **피해야 할 것**:
   - 모호한 감정어만(`"epic"`, `"cool"`) — 사운드로 환산 불가.
   - 복수의 독립 이벤트를 한 프롬프트에 나열 (→ 짧은 생성에서 섞여버림).
   - 한국어 프롬프트 (품질 저하).

### 3.6 Shadow Run 용 프롬프트 레시피

#### 카테고리 1: 러닝 앰비언스 (평화 / 긴장 / 추격)

```text
Peaceful:
Gentle birds chirping in a forest with light wind blowing through leaves, peaceful morning nature sounds, ambient outdoor running atmosphere

Tension (low):
Low tension strings with wind, dark ambient atmosphere, something watching from the shadows, subtle dread building

Chase (close):
Rapid heartbeat with heavy ragged breathing very close, running footsteps right behind you, panic and terror, being hunted

Critical:
Extreme panic sounds, distorted heartbeat, growling and metal scraping, heavy breathing on your neck, about to be caught by monster

Mystic safe:
Ambient pad with soft Korean bamboo flute (daegeum) long notes, reverb-heavy, mysterious misty mountain atmosphere, no percussion
```

#### 카테고리 2: Footsteps / Foley

```text
Heavy running footsteps on wet pavement, consistent rhythm, slight echo, professional foley recording
Stealthy barefoot footsteps on wooden floor, slow and cautious, faint creaks
Gravel crunch running footsteps, outdoor forest trail, steady pace
Metal grating footsteps in an abandoned factory, reverberant
Snow crunching footsteps, slow, cold winter night, subtle wind
```

#### 카테고리 3: Heartbeat / Breath

```text
Single deep heartbeat thump, isolated, bass-heavy
Slow calm heartbeat loop at 60 BPM, resting state
Fast panicked heartbeat at 140 BPM with subtle ringing in ears
Heart pounding in chest with sharp intake of breath, terror moment
Calm steady breathing through nose, yoga meditation rhythm
```

#### 카테고리 4: Wind / Weather

```text
Soft wind blowing through bare tree branches, autumn evening, minimal leaves
Howling wind through a cracked window, horror ambience
Heavy rain on a tin roof, steady and soothing, no thunder
Thunder rumble distant, building intensity over 10 seconds, summer storm approaching
Blizzard wind with snow hitting a wooden door, desolate winter
```

#### 카테고리 5: Horror Drone / Stinger

```text
Low sub-bass horror drone building over 15 seconds, cavernous echo, no melody
Sudden horror stinger, violin screech high pitch, impact with reverb tail, jump scare
Dissonant string cluster sustained, crescendo, cinematic horror
Metallic scrape and groan, rusty iron gate opening in a haunted hall
Whispered voices layered in reverse, unintelligible, occult atmosphere
```

#### 카테고리 6: Korean Traditional

```text
Solo Korean daegeum bamboo flute, long sustained notes, ambient pad, meditative mountain temple
Traditional Korean jing gong struck slowly with long decay, ceremonial, reverberant hall
Buk drum solo, slow powerful strikes, Korean folk percussion
Gayageum string plucks, arpeggiated pattern, peaceful Korean traditional melody
Ambient pad with distant pansori vocal, minimal, mystical Korean forest
```

#### 카테고리 7: UI / 게임 피드백 (짧은 clip)

```text
Short mechanical click, metal latch unlocking, clean futuristic UI button press
Single deep taiko drum hit, boomy resonant war drum, intimidating
Crystal bell chime notification, clean single tone, milestone reached
Glass shattering and cracking, mirror breaking into pieces, sudden and startling
Race start air horn blast, loud powerful starting signal, 1 second only
```

### 3.7 길이 확장 기법 (22/30 초 초과)

공식 API 는 **최대 30초** 이므로 그 이상은 클라이언트 측 조합이 필수.

- **반복 재생**: `loop=true` 로 생성한 10–15초 clip 을 게임 엔진/플레이어가 반복. 이음매 없이 루프되므로 BGM/앰비언스 에 최적.
- **Variant 교차 재생**: 같은 프롬프트로 `seed` 만 바꿔 3–5개 생성 → 랜덤 플레이로 지루함 방지.
- **ffmpeg concat**: 서로 이어지는 여러 clip 을 생성(예: intro 5s → loop 15s × N → outro 5s) 후 `ffmpeg -f concat -i list.txt -c copy out.mp3`.
- **crossfade**: ffmpeg `acrossfade=d=2` 필터로 2초 교차 페이드.

### 3.8 후처리 (ffmpeg 권장)

Shadow Run BGM 파이프라인에 이미 적용 중인 패턴.

**Loudness normalization (EBU R128 → 게임용 -23 LUFS)**

```bash
ffmpeg -i in.mp3 -af "loudnorm=I=-23:LRA=7:TP=-2.0:linear=true" -ar 44100 -b:a 192k out.mp3
```

- `I=-23`: 방송 표준. 게임 BGM 에 과도하게 눌릴 수 있음.
- 게임/모바일 앱에서 헤드폰 중심 청취라면 **-18 LUFS** 또는 **-16 LUFS** 로 덜 눌러도 됨.
- YouTube/스트리밍 매칭은 -14 LUFS.

**True Peak 제한**

- `TP=-2.0` (-2 dBTP) 로 모바일 기기 / AAC 인코딩 후 클리핑 방지.

**저주파 컷 (러닝 앱 환경에서 진동·걸음 간섭 제거)**

```bash
ffmpeg -i in.mp3 -af "highpass=f=80,loudnorm=I=-18:TP=-2.0" out.mp3
```

**클리핑 감지 + 정규화 (2-pass)**

```bash
# 1st pass: 측정
ffmpeg -i in.mp3 -af loudnorm=I=-18:TP=-2.0:print_format=json -f null -

# 2nd pass: 측정값으로 정확히 normalize
ffmpeg -i in.mp3 -af "loudnorm=I=-18:TP=-2.0:measured_I=<값>:measured_TP=<값>:measured_LRA=<값>:measured_thresh=<값>:offset=<값>:linear=true" out.mp3
```

### 3.9 출처

- <https://elevenlabs.io/docs/api-reference/text-to-sound-effects/convert>
- <https://elevenlabs.io/docs/overview/capabilities/sound-effects>
- <https://help.elevenlabs.io/hc/en-us/articles/25735604945041-How-do-I-prompt-for-sound-effects>
- <https://promptomania.com/models/elevenlabs/elevenlabs-sfx>
- <https://audio-generation-plugin.com/elevenlabs-mastering-sound-effect-prompts/>
- <https://elevenlabs.io/sound-effects>
- ffmpeg loudnorm: <http://k.ylo.ph/2016/04/04/loudnorm.html>

---

## 4. Music Generation (Eleven Music)

> **상태**: 일반 제공(GA). **유료 구독자만** API 사용 가능 (Starter 이상).
> 상업적 라이선스 포함 (Starter+).

### 4.1 엔드포인트

| 엔드포인트 | 용도 |
|-----------|------|
| `POST /v1/music` | 곡 생성(prompt 또는 composition_plan). 응답은 octet-stream(오디오). |
| `POST /v1/music/detailed` | 위와 동일하지만 multipart 응답으로 메타데이터(가사 포함) 반환. |
| `POST /v1/music/plan` | `composition_plan` JSON 만 생성 (오디오 없음). 플랜 검토·수정에 사용. |

### 4.2 요청 Body (`/v1/music`)

| 필드 | 타입 | 기본값 | 설명 |
|------|------|-------|------|
| `prompt` | string | — | 간단 프롬프트. `composition_plan` 와 **상호 배타**. |
| `composition_plan` | object | — | 상세 플랜. [§4.4](#44-composition_plan-구조) |
| `music_length_ms` | int | `null` | **3,000 – 600,000** (3초–10분). prompt 모드에서 유효. |
| `model_id` | string | `music_v1` | 현재 단일 모델. |
| `seed` | int | `null` | 재현성. |
| `force_instrumental` | bool | `false` | 가사 없이 기악만. |
| `respect_sections_durations` | bool | `true` | 섹션 duration 엄격 준수. |
| `store_for_inpainting` | bool | `false` | 후속 inpainting 용 저장 (엔터프라이즈). |
| `sign_with_c2pa` | bool | `false` | C2PA 인증 서명 부착. |

`/v1/music/detailed` 는 추가로 `with_timestamps: bool` 필드 지원.

### 4.3 쿼리 파라미터

- `output_format` — mp3/pcm/wav/opus. 음악은 `mp3_44100_192` 또는 `pcm_44100` 권장.

### 4.4 composition_plan 구조

```json
{
  "positive_global_styles": ["cinematic", "orchestral", "dark", "tense", "100 BPM", "D minor"],
  "negative_global_styles": ["electronic beats", "pop vocals"],
  "sections": [
    {
      "section_name": "Intro",
      "positive_local_styles": ["soft strings", "distant piano", "reverb heavy"],
      "negative_local_styles": ["drums", "brass"],
      "duration_ms": 15000,
      "lines": []
    },
    {
      "section_name": "Build",
      "positive_local_styles": ["tremolo strings", "low brass swell", "heartbeat percussion"],
      "negative_local_styles": [],
      "duration_ms": 20000,
      "lines": []
    },
    {
      "section_name": "Chase",
      "positive_local_styles": ["driving ostinato strings", "taiko drums", "dissonant brass"],
      "negative_local_styles": ["melodic"],
      "duration_ms": 30000,
      "lines": []
    }
  ]
}
```

**제약**

- 최대 **30 섹션**.
- 각 섹션 **3초–120초**.
- 총 길이 **3초–10분**.
- 스타일 배열 섹션당 **최대 50개**.
- 가사(`lines`) 섹션당 **최대 30줄**, 줄당 **200자**.
- 스타일(`*_styles`)은 **영어**로 작성. 가사(`lines`)는 **어떤 언어든** 가능 (한국어 가능).

### 4.5 가격 / 크레딧

- API 공식 가격표: **$0.30 / 분** (약 100 크레딧/초에 해당).
- 최소 3초 호출해도 길이만큼 과금.
- 플랜 생성(`/v1/music/plan`) 자체는 오디오 생성이 아니므로 오디오 크레딧 과금 없음 (단 LLM 계열 내부 소비 — ⚠️ 확인 필요).

### 4.6 Sound Effects vs Music API 의사결정

| 요구 사항 | 추천 API |
|-----------|---------|
| 22–30초 미만 앰비언스/루프 BGM | Sound Effects + `loop=true` |
| UI 효과음·foley·stinger | Sound Effects |
| 30초 이상 + 구조(인트로/빌드/드롭/아웃트로) 필요 | Music |
| 장르·BPM·조성 지정 필요 | Music |
| 가사·보컬 필요 | Music |
| 저렴한 비용(러닝 앰비언스 대량) | Sound Effects (초당 40 < 음악 초당 100) |
| Shadow Run 테마별 긴 BGM(2–5분) | Music |

### 4.7 출처

- <https://elevenlabs.io/docs/api-reference/music/compose>
- <https://elevenlabs.io/docs/api-reference/music/compose-detailed>
- <https://elevenlabs.io/docs/overview/capabilities/music>
- <https://elevenlabs.io/docs/eleven-api/guides/how-to/music/composition-plans>
- <https://elevenlabs.io/pricing/api>

---

## 5. Voice Cloning / Voice Design

### 5.1 Instant Voice Cloning (IVC)

**엔드포인트**: `POST /v1/voices/add`  (Content-Type: `multipart/form-data`)

**필수 파라미터**

- `name` — 이 보이스의 표시 이름.
- `files` — 샘플 오디오 파일 배열.

**선택 파라미터**

- `description` — 문자열.
- `labels` — JSON 문자열 또는 object (`{"language":"ko","gender":"male","age":"adult"}`).
- `remove_background_noise` — bool. 기본 false.

**응답**

```json
{"voice_id": "...", "requires_verification": false}
```

**샘플 요구사항 (공식)**

- **품질**: 깨끗한 단일 화자, 배경음/BGM 없음, 스튜디오 또는 품질 좋은 콘덴서 마이크.
- **형식**: MP3 192 kbps 이상, WAV 44.1 kHz 권장.
- **길이**: **1–5분** 권장. 최소 1분. 2–3분이 최적.
- **내용**: 자연스러운 평상 대화 톤. 낭독 연기 너무 과장 금지.
- **언어**: 클로닝 대상 언어와 동일 언어 샘플 권장 (한국어 보이스는 한국어 샘플).

**크레딧**

- **생성 자체는 무료** (크레딧 0).
- 구독 티어별 IVC **슬롯** 상한.
  - Starter 이상부터 IVC 가능.
  - Creator: 30 슬롯.
  - Pro 이상: 더 많음. ⚠️ 정확 슬롯 수 확인 필요 — 대시보드 참조.

### 5.2 Professional Voice Cloning (PVC)

공식 UI 중심. API 생성은 기본적으로 불가 (엔터프라이즈 파이프라인 존재). 워크플로:

1. 대시보드 → Voices → `Add Voice` → `Professional Cloning`.
2. **30분 이상** (이상적 2–3시간) 깨끗한 음성 샘플 업로드.
3. 본인 확인(verification statement) 녹음 — 스크립트 낭독.
4. 학습 대기: **최대 수시간~며칠**.
5. 완료 후 `voice_id` 발급, 모든 TTS 엔드포인트에서 사용 가능.

**요구 구독**: **Creator 이상**.
**결과 품질**: IVC 보다 크게 우수. 감정 표현 범위·스타일 안정성·긴 텍스트 일관성 모두 향상.
**크레딧**: 사용(TTS 호출) 시에만 과금, 학습/보유 자체는 무료.

### 5.3 Voice Design

프롬프트로 **완전히 새로운 가상 보이스** 생성.

**엔드포인트**: `POST /v1/text-to-voice/design`

**주요 파라미터**

| 필드 | 타입 | 기본값 | 설명 |
|------|------|-------|------|
| `voice_description` | string | **필수** | 예: "middle-aged korean male, raspy, serious, low pitch, slightly accented" |
| `text` | string? | null | 미리듣기 용 샘플 텍스트. **100–1,000자** 권장. |
| `auto_generate_text` | bool | `false` | true 면 description 기반 자동 생성. |
| `model_id` | string | `eleven_multilingual_ttv_v2` | `eleven_ttv_v3` 도 선택 가능. |
| `loudness` | number | `0.5` | -1.0–1.0 |
| `seed` | int? | null | 재현성. |
| `guidance_scale` | number | `5` | description 충실도. 1–20. |
| `should_enhance` | bool | `false` | description 문구 자체를 AI 가 개선. |
| `stream_previews` | bool | `false` | 스트리밍. |

**응답**

```json
{
  "previews": [
    {"audio_base_64": "...", "generated_voice_id": "...", "media_type": "audio/mpeg", "duration_secs": 5.2, "language": "ko"}
  ],
  "text": "샘플 텍스트"
}
```

미리듣기 3개 후보가 반환됨. 마음에 드는 voice 를 **저장**(`POST /v1/text-to-voice`)하면 `voice_id` 가 영구 할당되어 TTS 호출 가능.

**크레딧**: 저장 시 1 보이스당 소모 (⚠️ 정확 수치는 플랜별·정책별 변동 — 공식 대시보드 표기 확인).

### 5.4 출처

- <https://elevenlabs.io/docs/api-reference/voices/ivc/create>
- <https://elevenlabs.io/docs/api-reference/text-to-voice/design>
- <https://help.elevenlabs.io/hc/en-us/articles/13440435385105-What-files-do-you-accept-for-voice-cloning>
- <https://help.elevenlabs.io/hc/en-us/articles/13416206830097-Are-there-any-tips-to-get-good-quality-cloned-voices>
- <https://elevenlabs.io/docs/creative-platform/voices/voice-cloning/professional-voice-cloning>

---

## 6. 기타 API (Dubbing, STT, Voice Changer, Agents, History)

### 6.1 Dubbing

**엔드포인트**: `POST /v1/dubbing`

- **지원 언어**: 32개 (영어, 스페인어, 프랑스어, 독일어, 일본어, 중국어, 아랍어, 한국어 등).
- **입력**: 비디오 파일(mp4) 또는 오디오 파일.
- **과정**: 음성 인식(내부 STT) → 번역(내부 LLM) → 대상 언어 합성 → (비디오라면) 립싱크 조정.

**크레딧 / 가격** (API 기준)

| 옵션 | 가격 |
|------|------|
| Dubbing v1 + watermark | $0.33 / 분 |
| Dubbing v1 no watermark | $0.50 / 분 |

**크레딧 절감 팁**: 전체 클립 대신 선택 구간만 더빙. 세그먼트 단위 재생성.

### 6.2 Speech-to-Text (Scribe v2)

**엔드포인트**: `POST /v1/speech-to-text`

| 기능 | 설명 |
|------|------|
| 언어 | **90+ 개** |
| 정확도 | 98%+ (ElevenLabs 자체 벤치) |
| 실시간 지연 | ~150ms (Scribe v2 Realtime) |
| Keyterm prompting | 배치 모드 최대 1,000 항목, 항목당 50자 |
| Entity detection | 최대 56 범주 |
| Multichannel | 최대 5 채널 |
| Verbatim toggle | 필러 단어 제거 가능 |

**응답 구조**

```json
{
  "language_code": "ko",
  "language_probability": 0.99,
  "text": "...",
  "words": [
    {"text": "안녕", "start": 0.0, "end": 0.4, "type": "word", "speaker_id": "spk_0"}
  ]
}
```

**가격** (API)

- Scribe v1/v2: **$0.22 / 시간**
- Scribe v2 Realtime: **$0.39 / 시간**

### 6.3 Voice Changer (Speech-to-Speech, STS)

**엔드포인트**: `POST /v1/speech-to-speech/{voice_id}`

- **모델**: `eleven_multilingual_sts_v2` (29개 언어) 또는 `eleven_english_sts_v2`.
- **입력**: 원본 오디오 파일.
- **출력**: 지정 voice 로 변환된 오디오. 감정·톤·타이밍 보존.
- **최대 세그먼트 길이**: 5분.
- **크레딧**: 처리된 오디오 **1분당 1,000 크레딧**.

### 6.4 Conversational AI (Agents Platform)

에이전트(음성 챗봇) 전용 엔드포인트 군. 주요 URL:

- `GET /v1/convai/agents` — 에이전트 목록
- `POST /v1/convai/agents/create` — 에이전트 생성
- `GET /v1/convai/agents/{agent_id}` — 상세
- `PATCH /v1/convai/agents/{agent_id}` — 수정
- `WS /v1/convai/conversation?agent_id=...` — 실시간 대화 WebSocket

**핵심 개념**

- **LLM 선택**: GPT-4o / Gemini / Claude 연동 가능 (에이전트 설정에서 선택).
- **Voice**: ElevenLabs TTS 보이스 1개 지정.
- **Tools**: webhook/함수 호출 등록.
- **Phone**: Twilio / SIP 통합으로 전화 연결.

**크레딧**

- **분당 ~1,000 크레딧** (15분 대화 ≈ 15,000 크레딧 기준 역산).
- Creator 이상에서 usage-based 과금 옵션.
- **Burst pricing**: 동시 통화 한도 3배까지 (최대 300) 허용, 2배 요율.

### 6.5 History

| 엔드포인트 | 용도 |
|-----------|------|
| `GET /v1/history` | 생성 이력 목록 |
| `GET /v1/history/{history_item_id}` | 단건 상세 |
| `GET /v1/history/{history_item_id}/audio` | 오디오 다운로드 |
| `DELETE /v1/history/{history_item_id}` | 삭제 |
| `POST /v1/history/download` | 여러 항목 일괄 다운로드 (zip) |

**쿼리 파라미터**

- `voice_id` — 특정 보이스만
- `start_after_history_item_id` — 페이지네이션
- `page_size` — 기본 100

### 6.6 Projects (장문 오디오북/영상)

- `POST /v1/projects/add` — 프로젝트 생성(대본, 책)
- `POST /v1/projects/{project_id}/convert` — 변환
- `GET /v1/projects/{project_id}` — 상태 조회
- `GET /v1/projects/{project_id}/snapshots/.../audio` — 렌더된 오디오

Creator 이상에서 GUI 와 함께 사용. API 로는 대량 오디오북 자동화에 적합.

### 6.7 Models / User

| 엔드포인트 | 용도 |
|-----------|------|
| `GET /v1/models` | 사용 가능 모델 동적 조회 |
| `GET /v1/user` | 계정 정보(크레딧 잔량 포함) |
| `GET /v1/user/subscription` | 구독 정보·크레딧 상세 |

**크레딧 잔량 체크 (스크립트 도입부에 강력 권장)**

```python
info = client.user.subscription.get()
print("remaining credits:", info.character_count - info.character_limit)
```

### 6.8 출처

- <https://elevenlabs.io/docs/overview/capabilities/voice-changer>
- <https://elevenlabs.io/docs/overview/capabilities/dubbing>
- <https://elevenlabs.io/docs/overview/capabilities/speech-to-text>
- <https://elevenlabs.io/docs/api-reference/history>
- <https://elevenlabs.io/pricing/api>

---

## 7. Python 실전 템플릿

이 프로젝트의 기존 스크립트(`scripts/generate_bgm.py`, `scripts/generate_sfx.py`, `scripts/generate_tts.py`) 와 동일한 스타일로 작성. 표준 라이브러리만 쓰는 버전과 `elevenlabs-python` SDK 버전을 모두 제공.

### 7.1 공통 유틸 (재사용)

```python
# scripts/_elevenlabs_common.py
"""ElevenLabs 공통 헬퍼: 환경변수 로드, 재시도, 크레딧 체크."""
import os, json, time, random, urllib.request, urllib.error

ENDPOINT = "https://api.elevenlabs.io"
API_KEY = os.environ.get("ELEVENLABS_API_KEY", "")
assert API_KEY, "ELEVENLABS_API_KEY 환경변수가 설정되지 않았습니다."

DEFAULT_HEADERS = {
    "xi-api-key": API_KEY,
    "Content-Type": "application/json; charset=utf-8",
}

def post_json(path: str, body: dict, *, query: dict | None = None,
              accept: str = "application/octet-stream", timeout: int = 120) -> bytes:
    """바이너리 응답용 POST. 재시도 포함."""
    url = ENDPOINT + path
    if query:
        url += "?" + "&".join(f"{k}={v}" for k, v in query.items() if v is not None)
    data = json.dumps(body).encode("utf-8")
    headers = {**DEFAULT_HEADERS, "Accept": accept}

    last_err = None
    for attempt in range(3):
        try:
            req = urllib.request.Request(url, data=data, headers=headers)
            with urllib.request.urlopen(req, timeout=timeout) as resp:
                return resp.read()
        except urllib.error.HTTPError as e:
            body_s = e.read().decode("utf-8", errors="ignore")
            if e.code in (429, 500, 502, 503):
                sleep = (2 ** attempt) + random.random()
                print(f"  [{e.code}] retry in {sleep:.1f}s: {body_s[:120]}")
                time.sleep(sleep)
                last_err = e
                continue
            raise RuntimeError(f"HTTP {e.code}: {body_s[:500]}") from e
        except Exception as e:
            last_err = e
            time.sleep(2 ** attempt)
    raise RuntimeError(f"요청 실패(3회): {last_err}")

def check_credits() -> int:
    """구독 / 잔량 크레딧 반환."""
    req = urllib.request.Request(
        ENDPOINT + "/v1/user/subscription",
        headers={"xi-api-key": API_KEY, "Accept": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        info = json.loads(resp.read())
    remaining = info["character_limit"] - info["character_count"]
    print(f"[credits] {remaining:,} / {info['character_limit']:,} 남음")
    return remaining
```

### 7.2 TTS — 단일 호출 (requests 대신 stdlib)

```python
# scripts/example_tts_single.py
"""단일 한국어 TTS 생성."""
import os
from _elevenlabs_common import post_json

VOICE_ID = "nPczCjzI2devNBz1zQrb"   # Brian (Shadow Run 기본)
MODEL_ID = "eleven_multilingual_v2"

def tts(text: str, out_path: str,
        *, stability=0.5, similarity_boost=0.85, style=0.0,
        use_speaker_boost=True, output_format="mp3_44100_128"):
    body = {
        "text": text,
        "model_id": MODEL_ID,
        "voice_settings": {
            "stability": stability,
            "similarity_boost": similarity_boost,
            "style": style,
            "use_speaker_boost": use_speaker_boost,
        },
    }
    audio = post_json(
        f"/v1/text-to-speech/{VOICE_ID}", body,
        query={"output_format": output_format},
    )
    with open(out_path, "wb") as f:
        f.write(audio)
    print(f"OK {out_path} ({len(audio)/1024:.1f} KB)")

if __name__ == "__main__":
    tts("그림자가 깨어났습니다. 달리세요.", "assets/audio/tts_start.mp3",
        stability=0.45, similarity_boost=0.85)
```

### 7.3 TTS — SDK 버전

```python
# scripts/example_tts_sdk.py
"""elevenlabs-python SDK 사용 예제."""
import os
from elevenlabs.client import ElevenLabs
from elevenlabs import VoiceSettings

client = ElevenLabs(api_key=os.environ["ELEVENLABS_API_KEY"])

audio = client.text_to_speech.convert(
    voice_id="nPczCjzI2devNBz1zQrb",
    model_id="eleven_multilingual_v2",
    text="그림자가 깨어났습니다. 달리세요.",
    output_format="mp3_44100_128",
    voice_settings=VoiceSettings(
        stability=0.45, similarity_boost=0.85, style=0.0, use_speaker_boost=True,
    ),
)
with open("assets/audio/tts_start.mp3", "wb") as f:
    for chunk in audio:
        f.write(chunk)
```

### 7.4 SFX 배치 생성 (병렬 + 재시도)

```python
# scripts/example_sfx_batch.py
"""SFX 여러 개를 세마포어로 동시성 제한하며 배치 생성."""
import os, time
from concurrent.futures import ThreadPoolExecutor, as_completed
from _elevenlabs_common import post_json

OUTDIR = "assets/audio/sfx"
os.makedirs(OUTDIR, exist_ok=True)

# (파일명, prompt, duration_seconds, prompt_influence)
SFX = [
    ("sfx_chase_close.mp3",
     "Rapid heartbeat with heavy ragged breathing very close, running footsteps right behind you, panic terror",
     15.0, 0.3),
    ("sfx_heartbeat_single.mp3",
     "Single deep heartbeat thump, isolated bass",
     1.0, 0.5),
    ("sfx_mystic_ambient.mp3",
     "Ambient pad with distant Korean bamboo flute daegeum long sustained notes, misty mountain temple",
     15.0, 0.3),
]

def generate_one(item):
    filename, prompt, duration, influence = item
    out_path = os.path.join(OUTDIR, filename)
    if os.path.exists(out_path):
        return (filename, "SKIP")

    body = {
        "text": prompt,
        "duration_seconds": duration,
        "prompt_influence": influence,
        "model_id": "eleven_text_to_sound_v2",
    }
    audio = post_json("/v1/sound-generation", body)
    with open(out_path, "wb") as f:
        f.write(audio)
    return (filename, f"OK {len(audio)//1024}KB")

# Starter/Creator 기준 동시 3–5개가 안전. Pro 이상에서만 8+
MAX_CONCURRENT = 3

def main():
    results = []
    with ThreadPoolExecutor(max_workers=MAX_CONCURRENT) as ex:
        futures = {ex.submit(generate_one, it): it[0] for it in SFX}
        for fut in as_completed(futures):
            name = futures[fut]
            try:
                fn, status = fut.result()
                print(f"{fn}: {status}")
                results.append((fn, status))
            except Exception as e:
                print(f"{name}: FAIL - {e}")

if __name__ == "__main__":
    main()
```

### 7.5 Music 생성 템플릿

```python
# scripts/example_music.py
"""Eleven Music - composition_plan 기반 Shadow Run 테마 BGM 생성."""
import json, os
from _elevenlabs_common import post_json

OUTDIR = "assets/audio/bgm_music"
os.makedirs(OUTDIR, exist_ok=True)

PLAN_CHASE = {
    "positive_global_styles": [
        "cinematic", "orchestral horror", "100 BPM", "D minor",
        "no vocals", "korean traditional percussion influence"
    ],
    "negative_global_styles": ["electronic beats", "pop", "upbeat"],
    "sections": [
        {
            "section_name": "Intro",
            "positive_local_styles": ["soft strings tremolo", "distant piano", "reverb heavy"],
            "negative_local_styles": ["drums"],
            "duration_ms": 15000,
            "lines": []
        },
        {
            "section_name": "Build",
            "positive_local_styles": ["heartbeat percussion", "low brass swell", "dissonant strings"],
            "negative_local_styles": [],
            "duration_ms": 20000,
            "lines": []
        },
        {
            "section_name": "Chase",
            "positive_local_styles": [
                "driving string ostinato", "taiko drums", "buk drum accents",
                "brass hits", "relentless 16th notes"
            ],
            "negative_local_styles": ["melodic resolution"],
            "duration_ms": 45000,
            "lines": []
        },
        {
            "section_name": "Fade",
            "positive_local_styles": ["sparse strings", "fade out", "final heartbeat"],
            "negative_local_styles": ["drums"],
            "duration_ms": 10000,
            "lines": []
        }
    ]
}

def compose(plan: dict, out_path: str,
            force_instrumental=True, output_format="mp3_44100_192"):
    body = {
        "composition_plan": plan,
        "model_id": "music_v1",
        "force_instrumental": force_instrumental,
    }
    audio = post_json("/v1/music", body, query={"output_format": output_format}, timeout=300)
    with open(out_path, "wb") as f:
        f.write(audio)
    print(f"OK {out_path} ({len(audio)/1024:.1f} KB)")

if __name__ == "__main__":
    compose(PLAN_CHASE, os.path.join(OUTDIR, "bgm_chase_90s.mp3"))
```

### 7.6 에러 핸들링 데코레이터

```python
# scripts/_retry_decorator.py
import functools, time, random

def retry(tries=3, backoff=1.0, retry_on=(429, 500, 502, 503)):
    def deco(fn):
        @functools.wraps(fn)
        def wrapped(*args, **kwargs):
            last = None
            for i in range(tries):
                try:
                    return fn(*args, **kwargs)
                except Exception as e:
                    msg = str(e)
                    code = None
                    for c in retry_on:
                        if f"HTTP {c}" in msg or f" {c} " in msg:
                            code = c; break
                    if code is None or i == tries - 1:
                        raise
                    sleep = backoff * (2 ** i) + random.random() * 0.5
                    print(f"  retry #{i+1} after {sleep:.1f}s ({code}): {msg[:120]}")
                    time.sleep(sleep)
                    last = e
            raise last
        return wrapped
    return deco
```

### 7.7 `.env` 로드 (python-dotenv)

```python
# scripts/_load_env.py
"""프로젝트 루트 .env 자동 로드."""
import os
from pathlib import Path

def load_env():
    root = Path(__file__).resolve().parent.parent
    env = root / ".env"
    if not env.exists():
        return
    for line in env.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        os.environ.setdefault(k.strip(), v.strip().strip('"').strip("'"))

load_env()
```

### 7.8 Shadow Run 파이프라인 (BGM + 후처리)

```python
# scripts/example_full_bgm_pipeline.py
"""SFX 생성 → ffmpeg loudnorm → assets/audio/bgm/ 배치."""
import os, subprocess, tempfile
from _elevenlabs_common import post_json

BGMS = [
    ("bgm_chase_close.mp3",
     "Rapid heartbeat with heavy ragged breathing, running footsteps right behind you, panic terror",
     15.0, 0.3),
]

FINAL_DIR = "assets/audio/bgm"
os.makedirs(FINAL_DIR, exist_ok=True)

def normalize(in_path: str, out_path: str, I=-18.0, TP=-2.0, LRA=7.0):
    subprocess.run([
        "ffmpeg", "-y", "-i", in_path,
        "-af", f"highpass=f=80,loudnorm=I={I}:TP={TP}:LRA={LRA}:linear=true",
        "-ar", "44100", "-b:a", "192k",
        out_path,
    ], check=True, capture_output=True)

def main():
    for filename, prompt, dur, infl in BGMS:
        final_path = os.path.join(FINAL_DIR, filename)
        if os.path.exists(final_path):
            print(f"SKIP {filename}")
            continue
        with tempfile.NamedTemporaryFile(suffix=".mp3", delete=False) as tmp:
            raw = post_json("/v1/sound-generation", {
                "text": prompt, "duration_seconds": dur, "prompt_influence": infl,
                "model_id": "eleven_text_to_sound_v2",
            })
            tmp.write(raw)
            tmp_path = tmp.name
        try:
            normalize(tmp_path, final_path)
            print(f"OK {filename} (normalized -18 LUFS)")
        finally:
            os.unlink(tmp_path)

if __name__ == "__main__":
    main()
```

---

## 8. 요금 / 크레딧 계산표

### 8.1 구독 티어 (2026-04 기준, USD 월 요금)

| 티어 | 월 요금 | 월 크레딧 | 동시 TTS | 상업 라이선스 | 주요 기능 |
|------|--------|----------|---------|-------------|----------|
| Free | $0 | 10,000 | 2 | ❌ | TTS, STT, SFX, 3 프로젝트 |
| Starter | $5–$6 | 30,000 | 3 | ✅ | IVC, Music API 사용, 20 프로젝트 |
| Creator | $22 (프로모 $11 첫달) | 100,000 (이전 121k 표기) | 5 | ✅ | PVC, 192 kbps |
| Pro | $99 | 500,000 (표기 600k) | 10 | ✅ | 44.1 kHz PCM |
| Scale | $330 (이전 $299) | 2,000,000 (표기 1.8M) | 15 | ✅ | 팀 3석 + 전문 음성 3 |
| Business | $990 | 11,000,000 (표기 6M) | 15 | ✅ | 팀 10석, 저지연 TTS |
| Enterprise | 협의 | 협의 | 협의+ | ✅ | SLA, zero-retention |

> ⚠️ ElevenLabs 는 분기마다 크레딧 량·가격을 조정한다. 위 수치는 2026-04-23 기준 공식/정리 글 종합. **결제 전 반드시** pricing 페이지에서 현행 수치 확인.

### 8.2 API 별 단가 (API 가격 페이지 기준)

| 서비스 | 단가 |
|--------|------|
| TTS Flash / Turbo v2.5 | $0.05 / 1,000자 |
| TTS Multilingual v2 / v3 | $0.10 / 1,000자 |
| STT Scribe v2 (배치) | $0.22 / 시간 |
| STT Scribe v2 Realtime | $0.39 / 시간 |
| Music | $0.30 / 분 |
| Sound Effects | $0.12 / 생성 (duration 미지정 시 평균) — duration 지정 시 초당 40 크레딧 |
| Dubbing v1 (워터마크) | $0.33 / 분 |
| Dubbing v1 (no watermark) | $0.50 / 분 |
| Conversational AI | ≈ 1,000 크레딧 / 분 |

### 8.3 모델별 TTS 문자당 크레딧

| 모델 | Self-serve 플랜 | Enterprise |
|------|-----------------|-----------|
| Flash v2, Flash v2.5, Turbo v2, Turbo v2.5 | **0.5 크레딧/자** | 0.5–1.0 |
| Multilingual v2, English v1, Multilingual v1 | **1.0 크레딧/자** | 1.0 |
| Eleven v3 | **1.0 크레딧/자** | 1.0 |

> ⚠️ Voice Library 의 일부 **공유 voice** 는 **추가 multiplier** 가 붙는다 (프리미엄 보이스). voice 상세 화면에서 확인 가능.

### 8.4 "30,000 크레딧으로 할 수 있는 일" (Starter 티어 예시)

가정: Shadow Run 의 전형적 자산 길이.

| 작업 | 단가 | 수량 | 크레딧 |
|------|------|------|-------|
| TTS 한국어 경고문 평균 30자 × 100개 (Multilingual v2) | 30 | 100 | 3,000 |
| TTS 한국어 내레이션 평균 200자 × 20개 (Multilingual v2) | 200 | 20 | 4,000 |
| SFX 평균 15초 × 20개 (40 c/s) | 600 | 20 | 12,000 |
| Music 30초 × 3곡 (100 c/s) | 3,000 | 3 | 9,000 |
| 합계 | | | **28,000** |

거의 한 달 분 Starter 크레딧을 소진. → **Shadow Run 프로젝트는 Creator (100k) 이상 권장.**

### 8.5 출처

- <https://elevenlabs.io/pricing>
- <https://elevenlabs.io/pricing/api>
- <https://help.elevenlabs.io/hc/en-us/articles/27562020846481-What-are-credits>
- <https://bigvu.tv/blog/elevenlabs-pricing-2026-plans-credits-commercial-rights-api-costs/>
- <https://smallest.ai/blog/elevenlabs-pricing-explained-plans-limits-hidden-costs-calculator>
- <https://flexprice.io/blog/elevenlabs-pricing-breakdown>

---

## 9. 실전 체크리스트 & 함정

### 9.1 문자/크레딧 계산 실수 방지

- **공백·문장부호 포함**: 모든 character 가 카운트. 한국어 1자 = 1 character. (Flash/Turbo 는 0.5x 배수.)
- 한국어 조사·어미 감소를 위해 스크립트에서 **중복 텍스트 제거** + **템플릿 재사용**.
- **미리 계산**: `len(text)` 합계 × 모델 배수 → 호출 전 잔량 점검.

```python
def estimate_cost(text: str, model_id: str) -> int:
    mult = 0.5 if "flash" in model_id or "turbo" in model_id else 1.0
    return int(len(text) * mult)
```

### 9.2 긴 오디오 — 끊어 요청하고 이어 붙이기

- TTS 5,000자 초과(v3) 또는 10,000자 초과(v2) 는 나눠야 함.
- **문장 경계**(`. `, `? `, `! `, `\n\n`) 에서 분할. 어절 중간 금지.
- 이어붙일 때 `previous_text` / `next_text` 로 문맥 공유.
- 오디오 concat: `ffmpeg -f concat -safe 0 -i list.txt -c copy out.mp3` (목록 파일 포맷 `file '...'`).

### 9.3 품질 검증 (LUFS, TP, 스펙트럼)

```bash
# 통합 라우드니스 + True Peak 측정
ffmpeg -i out.mp3 -af "loudnorm=I=-18:TP=-2.0:print_format=json" -f null - 2>&1 | tail -20

# 스펙트로그램 시각화 (Sonic Visualizer, ffmpeg)
ffmpeg -i out.mp3 -lavfi showspectrumpic=s=1024x512 spec.png
```

- **피크 클리핑** 확인: `measured_TP` 가 0.0 을 넘으면 재처리.
- **LUFS 과도**(-8 이상) → 귀 피로. -18~-14 권장.
- **스펙트럼 80 Hz 이하** 가 과한 BGM 은 모바일 스피커에서 진동만 나므로 `highpass=f=80` 권장.

### 9.4 저작권 / 이용 약관 핵심

- 상업적 사용: **Starter 이상** 구독 필요.
- 생성물 저작권: 사용자에게 귀속(약관 § Commercial Terms).
- **엔드유저에 대한 고지**: 기본 ElevenLabs 워터마크 없음. 단 Dubbing API 저가 옵션은 워터마크 포함.
- **음성 클로닝 금지 사례**: 본인 허락 없는 타인 목소리, 공인·정치인 사칭, 범죄 유도 콘텐츠. IVC 시 자동 검증(verification statement) 요구.
- **C2PA 서명**: Music API `sign_with_c2pa=true` 로 AI 생성 오디오 출처 증명. 플랫폼 검증 대응.

### 9.5 한국어 사용 시 자주 나오는 이슈

- **숫자 읽기**: "5km" → "오 킬로미터" 정확히 읽히지 않는 경우 발생. 대안: **사전에 "5킬로미터"로 풀어쓰기** 또는 Pronunciation Dictionary 사용. `apply_text_normalization=on` 도 시도.
- **영어 차용어**: "GPS", "앱", "러닝" — 원음 그대로 잘 읽지만 "RPM" 같은 약자는 **"알 피 엠"** 식으로 띄어쓰기 필요한 경우 있음.
- **감정 과장**: Multilingual v2 는 한국어에서 stability<0.4 로 내리면 **억양이 과하게 흔들리며 여성·중성화** 경향. **0.45–0.55** 안정.
- **장문의 억양 리듬**: 문단이 길어질수록 기계적 반복 리듬 발생. **문장별 분할 + previous_text 로 이어 생성** 이 가장 자연스러움.
- **v3 한국어 audio tag**: `[whispering]`, `[angry]` 등 태그는 **영어로 작성**해야 인식됨. 한국어로 `[속삭임]` 쓰면 텍스트로 읽어버림.

### 9.6 한국어 SFX 프롬프트 — 영어로 쓰는 이유

- ElevenLabs SFX 모델은 **영어 코퍼스 중심** 학습. 한국어 프롬프트는:
  - 알 수 없는 토큰 → 무작위 결과.
  - 한국어 의성어("쿵쾅", "부스럭") 는 해석되지 않음 → **영어 표현("thud", "rustle") 로 번역**.
- 한국적 소리(국악기)를 원할 땐 **영어로 악기명 지정**:
  - 대금 → `Korean daegeum bamboo flute`
  - 가야금 → `Korean gayageum zither plucked strings`
  - 북 → `Korean buk drum deep`
  - 징 → `Korean jing gong ceremonial`

### 9.7 호출 전 체크리스트

- [ ] `ELEVENLABS_API_KEY` 환경변수 설정 확인
- [ ] `check_credits()` 로 잔량 점검
- [ ] `voice_id` 가 실제 접근 가능한지 `GET /v2/voices?voice_ids=...` 로 확인
- [ ] 프롬프트/텍스트 길이가 모델 최대값 이내
- [ ] output_format 이 구독 티어에서 허용 (Pro 이상만 pcm_44100+)
- [ ] 출력 디렉터리 존재 (`os.makedirs(..., exist_ok=True)`)
- [ ] 동시 요청 수가 티어 한도 이내 (ThreadPoolExecutor `max_workers`)
- [ ] 결과물 LUFS/TP 측정 후 필요 시 `loudnorm` 적용
- [ ] 버전관리 대상 파일(voice_id, 프롬프트) 커밋

### 9.8 출처

- <https://elevenlabs.io/docs/overview/capabilities/text-to-speech/best-practices>
- <https://help.elevenlabs.io/hc/en-us/sections/14163158308369-API>
- <https://wiki.tnonline.net/w/Blog/Audio_normalization_with_FFmpeg>

---

## 10. 빠른 참조 (Cheat Sheet)

### 10.1 기본 헤더

```http
xi-api-key: $ELEVENLABS_API_KEY
Content-Type: application/json; charset=utf-8
Accept: application/octet-stream
```

### 10.2 엔드포인트 요약

| 목적 | Method | Path |
|------|--------|------|
| TTS | POST | `/v1/text-to-speech/{voice_id}` |
| TTS 스트리밍 | POST | `/v1/text-to-speech/{voice_id}/stream` |
| TTS 타임스탬프 | POST | `/v1/text-to-speech/{voice_id}/with-timestamps` |
| TTS WebSocket | WSS | `/v1/text-to-speech/{voice_id}/stream-input` |
| SFX | POST | `/v1/sound-generation` |
| Music (간단) | POST | `/v1/music` |
| Music (상세) | POST | `/v1/music/detailed` |
| Music Plan | POST | `/v1/music/plan` |
| Voices 목록 | GET | `/v2/voices` |
| Voice 상세 | GET | `/v1/voices/{voice_id}` |
| IVC 생성 | POST | `/v1/voices/add` |
| Voice Design | POST | `/v1/text-to-voice/design` |
| STT | POST | `/v1/speech-to-text` |
| STS (Voice Changer) | POST | `/v1/speech-to-speech/{voice_id}` |
| Dubbing | POST | `/v1/dubbing` |
| History | GET | `/v1/history` |
| Models | GET | `/v1/models` |
| 구독/잔량 | GET | `/v1/user/subscription` |

### 10.3 파라미터 기본값

```json
{
  "model_id": "eleven_multilingual_v2",
  "voice_settings": {
    "stability": 0.5,
    "similarity_boost": 0.75,
    "style": 0.0,
    "use_speaker_boost": true,
    "speed": 1.0
  },
  "output_format": "mp3_44100_128",
  "optimize_streaming_latency": 0,
  "apply_text_normalization": "auto"
}
```

SFX 기본값:

```json
{
  "model_id": "eleven_text_to_sound_v2",
  "duration_seconds": null,
  "prompt_influence": 0.3,
  "loop": false
}
```

### 10.4 실전 프롬프트 5선 (Shadow Run 바로 사용 가능)

```text
1. 추격 임박 (15s, 0.3):
   "Rapid heartbeat with heavy ragged breathing very close, running footsteps right behind you, panic and terror, being hunted"

2. 미스틱 안전 (15s, 0.3, loop=true):
   "Ambient pad with distant Korean daegeum bamboo flute long sustained notes, misty mountain temple, peaceful mysterious atmosphere"

3. 마라토너 응원 (10s, 0.3):
   "Light upbeat footsteps on pavement with subtle synth pad, motivational running atmosphere, steady rhythm, outdoor morning jog"

4. 도플갱어 각성 (5s, 0.4):
   "Low sub-bass horror drone starting quietly, sudden dissonant string stinger at the end, cavernous reverb, jump scare"

5. 생존 클리어 (3s, 0.5):
   "Short triumphant orchestral fanfare, brass swell with reverb, heroic achievement unlocked, 2 seconds only, cinematic"
```

### 10.5 최소 호출 예 (curl)

```bash
# TTS
curl -X POST "https://api.elevenlabs.io/v1/text-to-speech/nPczCjzI2devNBz1zQrb?output_format=mp3_44100_128" \
  -H "xi-api-key: $ELEVENLABS_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"text":"그림자가 깨어났습니다.","model_id":"eleven_multilingual_v2","voice_settings":{"stability":0.5,"similarity_boost":0.85}}' \
  -o tts_start.mp3

# SFX
curl -X POST "https://api.elevenlabs.io/v1/sound-generation" \
  -H "xi-api-key: $ELEVENLABS_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"text":"Rapid heartbeat with heavy breathing","duration_seconds":10,"prompt_influence":0.3}' \
  -o sfx_chase.mp3

# Music
curl -X POST "https://api.elevenlabs.io/v1/music?output_format=mp3_44100_192" \
  -H "xi-api-key: $ELEVENLABS_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"prompt":"dark orchestral horror chase theme, no vocals","music_length_ms":60000,"force_instrumental":true}' \
  -o bgm_chase.mp3

# Voices 검색
curl "https://api.elevenlabs.io/v2/voices?search=Korean&page_size=50" \
  -H "xi-api-key: $ELEVENLABS_API_KEY" | jq '.voices[] | {name, voice_id, labels}'
```

---

## 11. 커버 범위 / 검증되지 않은 영역

### 11.1 이 문서로 커버되는 기능

- ✅ 인증, base URL, 헤더, 환경변수 관례
- ✅ Rate limit (티어별 동시 요청), 429/500 재시도 전략
- ✅ 에러 코드 (400/401/403/404/422/429/500/503) 처리
- ✅ TTS 모든 엔드포인트 (convert / stream / with-timestamps)
- ✅ TTS 모델 전수 (v3 / multilingual v2 / flash v2.5 / turbo v2.5 / legacy)
- ✅ 모델별 지원 언어·지연·최대 문자·크레딧 배수
- ✅ 전체 `output_format` 목록 (mp3/pcm/wav/opus/ulaw/alaw)
- ✅ `voice_settings` 파라미터 전체 범위·의미
- ✅ v3 Audio Tags 사용법 + 카테고리별 예시
- ✅ Pre-made default voices 10개 voice_id
- ✅ 한국어 Voice Library 추천 5개
- ✅ Pronunciation Dictionary 사용법
- ✅ Sound Effects 엔드포인트·파라미터·크레딧 (초당 40)
- ✅ SFX 프롬프트 레시피 7 카테고리 × 5개 = 35개 (Shadow Run 지향)
- ✅ SFX 길이 확장(loop, variant, ffmpeg concat)
- ✅ ffmpeg loudnorm 후처리 (1-pass / 2-pass)
- ✅ Music API (compose, compose-detailed, plan)
- ✅ `composition_plan` JSON 전체 스키마 + 예제
- ✅ Sound Effects vs Music 의사결정 매트릭스
- ✅ IVC / PVC / Voice Design 엔드포인트·샘플 요구사항·구독 요구
- ✅ Dubbing / STT / Voice Changer / Conversational AI 개요 + 가격
- ✅ History / Projects / Models / User 유틸 엔드포인트
- ✅ Python 실전 템플릿 7개 (공통 유틸, TTS stdlib/SDK, SFX 배치, Music, 재시도 데코, env 로더, 파이프라인)
- ✅ 구독 티어 6단계 + API 별 단가표
- ✅ 크레딧 계산 예시 (30k Starter 시나리오)
- ✅ 한국어 특화 함정 (숫자 읽기, 억양, SFX 영어 프롬프트 당위)
- ✅ 호출 전 체크리스트 9항목
- ✅ Cheat Sheet + curl 최소 호출 예

### 11.2 불확실 / 검증되지 않은 영역 (⚠️)

- **구독별 정확한 크레딧 수치**: Creator/Pro/Scale 은 정보 소스에 따라 100k vs 121k, 500k vs 600k, 1.8M vs 2M 표기 차이 존재. **결제 전 반드시 [pricing 페이지](https://elevenlabs.io/pricing) 직접 확인**.
- **Voice Design 저장 비용**: 공식 숫자를 본 문서 조사 범위에서 재확인하지 못함. 대시보드 표기 기준.
- **IVC 슬롯 수**: 티어별 정확 슬롯 수 (Creator 30 외 Pro/Scale) 는 공식 문서에서 한 줄로 요약된 표를 찾지 못함.
- **Music API `/v1/music/plan` 크레딧 여부**: 오디오 생성 없이 LLM 내부 처리만이라 무료일 가능성 높으나 공식 명시 확인 필요.
- **Scribe v2 크레딧 환산**: "시간당 $X" 가격은 확인되었으나 이것이 몇 크레딧에 해당하는지 환산표 명시 없음.
- **Conversational AI 크레딧 정확치**: "분당 약 1,000 크레딧" 은 제3자 정리 글 기준. 공식 환산 테이블에서 재확인 권장.
- **Audio Tags 공식 전체 목록**: v3 는 아직 alpha 단계이며 태그 목록은 공식 문서화가 부분적. 위 카테고리 집계는 블로그 + 커뮤니티 실험 결과. 실사용 시 **테스트 제너레이션으로 태그 작동 여부를 개별 검증** 권장.
- **한국어 프리메이드 voice 의 voice_id**: Hyuk, Anna Kim 등은 Voice Library 커뮤니티 voice 라 **계정에 추가해야** voice_id 가 안정적으로 노출됨. 직접 조회 필요.
- **`default` pre-made voice 라이브러리 변경**: ElevenLabs 는 주기적으로 default 라인업을 교체(기존 Clyde, Jeremy 등 사라짐). 운영 스크립트에서는 **voice_id 를 상수 파일로 분리**하고, 주기적으로 `GET /v2/voices?voice_type=default` 로 존재 여부 검증 권장.
- **Agents Platform REST 엔드포인트 상세**: `/v1/convai/*` 군은 본 조사에서 고수준 정보만 확보. 에이전트 생성 body 스키마는 별도 참조 필요.

### 11.3 다음에 이 문서를 업데이트해야 하는 시점

- ElevenLabs 가 새 TTS/Music 모델 릴리스 (예: Eleven v3 GA, Music v2)
- 구독 가격 · 크레딧 개편 발표
- Audio Tags 공식 목록 페이지 공개
- 한국어 추가 보이스 / 한국어 전용 모델 출시
- Shadow Run 프로젝트에서 새 API (예: Dubbing, Agents) 도입 결정

---

**문서 버전**: 1.0 (2026-04-23)
**작성 기반**: 공식 `elevenlabs.io/docs/*`, `help.elevenlabs.io`, 공식 블로그 (v3-audiotags), 커뮤니티 정리 (webfuse cheatsheet, promptomania, audio-generation-plugin), `elevenlabs-python` GitHub README, 공식 pricing 페이지.
**Shadow Run 연결**: `scripts/generate_bgm.py`, `scripts/generate_sfx.py`, `scripts/generate_tts.py` 의 현행 스타일을 유지하도록 설계.
