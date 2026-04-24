#!/usr/bin/env python3
"""Shadow Run v30 — 테마별 오디오 자산 재생성.

3 테마(filmNoir=t2, editorial=t4, neoNoirCyber=t5) × (홈 BGM + 자유/마라톤/도플갱어 BGM + 5 signature SFX + 10 TTS line).

실행: ELEVENLABS_API_KEY=... python3 tools/regen_theme_audio_v30.py [stage]
stage: bgm | sfx | tts | all (default all)
"""

import os
import sys
import json
import time
import subprocess
import concurrent.futures
from pathlib import Path
import urllib.request
import urllib.error

API_KEY = os.environ["ELEVENLABS_API_KEY"]
BASE = "https://api.elevenlabs.io"
REPO = Path(__file__).resolve().parent.parent
ASSETS = REPO / "assets" / "audio"
THEMES_DIR = ASSETS / "themes"
SFX_DIR = ASSETS / "sfx"
TTS_DIR = ASSETS / "tts"
RAW_DIR = ASSETS / ".raw"
for d in (THEMES_DIR, SFX_DIR, TTS_DIR, RAW_DIR):
    d.mkdir(parents=True, exist_ok=True)

VOICES = {
    "noir": "BQOei2tk6QCBMHQWPhbj",      # Cedric
    "editorial": "MWUpoNpAY0rOQGP294mF",  # Clarice
    "cyber": "SAz9YHcvj6GT2YYXdXww",      # River
}

THEME_TO_T = {"noir": "t2", "editorial": "t4", "cyber": "t5"}


def http_post(path, body, timeout=600):
    req = urllib.request.Request(
        BASE + path,
        data=json.dumps(body).encode("utf-8"),
        headers={
            "xi-api-key": API_KEY,
            "Content-Type": "application/json",
            "Accept": "audio/mpeg",
        },
        method="POST",
    )
    last_err = None
    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, timeout=timeout) as r:
                return r.read(), r.status
        except urllib.error.HTTPError as e:
            body = e.read().decode("utf-8", "ignore")
            if e.code in (429, 500, 502, 503, 504):
                last_err = (e.code, body)
                time.sleep(5 * (attempt + 1))
                continue
            return None, (e.code, body)
        except Exception as e:
            last_err = str(e)
            time.sleep(3 * (attempt + 1))
    return None, last_err


def call_sfx(prompt, duration_s=None, loop=False):
    body = {"text": prompt, "model_id": "eleven_text_to_sound_v2"}
    if duration_s:
        body["duration_seconds"] = duration_s
    body["loop"] = loop
    return http_post("/v1/sound-generation", body, timeout=300)


def call_music(prompt, duration_ms):
    body = {
        "prompt": prompt,
        "music_length_ms": duration_ms,
        "force_instrumental": True,
    }
    return http_post("/v1/music", body, timeout=600)


def call_tts(text, voice_id):
    body = {
        "text": text,
        "model_id": "eleven_multilingual_v2",
        "voice_settings": {
            "stability": 0.55,
            "similarity_boost": 0.75,
            "style": 0.3,
            "use_speaker_boost": True,
        },
    }
    return http_post(f"/v1/text-to-speech/{voice_id}", body, timeout=180)


def loudnorm(src: Path, dst: Path, target_i=-23):
    cmd = [
        "ffmpeg", "-y", "-i", str(src),
        "-af", f"loudnorm=I={target_i}:TP=-2:LRA=11",
        "-ar", "44100", "-ac", "2", "-b:a", "128k",
        str(dst),
    ]
    r = subprocess.run(cmd, capture_output=True)
    if r.returncode != 0:
        print("ffmpeg FAIL:", r.stderr.decode("utf-8", "ignore")[-400:])
        return False
    return True


# ---------- BGM specs ----------
BGM_SPECS = {
    # (theme, slot): (api_kind, duration_s/ms, prompt)
    ("noir", "home"): ("sfx", 22,
        "Rainy 1940s private detective office ambience at midnight. Slow melancholic jazz: low-register tenor saxophone long tones, "
        "double bass pizzicato walking slowly, brushed snare drum hushed, vintage upright piano soft minor chords spaced out, "
        "continuous rain on windowpane, faint AM radio static and distant thunder rumble, vinyl crackle warmth. "
        "No melody hook, purely atmospheric, minor key, 65 BPM implied by bass. Seamless loop ambient."),
    ("noir", "freerun"): ("sfx", 22,
        "Solo midnight walk through rainy noir city streets. Muted trumpet ballad long tones, brushed drum kit 90 BPM steady pulse, "
        "upright double bass walking line, distant saxophone melody fragment, vintage piano minor chord every 8 bars, "
        "light rain on pavement, wet footstep reverb, vinyl warmth. Reflective melancholic mood, minor key. Seamless loopable ambient."),
    ("noir", "marathon"): ("music", 30000,
        "Dark big-band noir pursuit instrumental, 160 BPM, minor key. Pounding upright double bass walking at double time, "
        "hard-swinging stick drums with crash cymbal accents, raw tenor saxophone screaming stabs, muted trumpet blasts, "
        "vintage brass section staccato hits, piano comping in minor. Cinematic detective chase energy, raw 1940s jazz club warmth, "
        "escalating momentum, no vocals, no electronic sounds."),
    ("noir", "doppel"): ("music", 30000,
        "Tense noir chase score instrumental, 150 BPM, minor key dissonance. Heavy low brass stabs on downbeats, "
        "string section tremolo tension, pounding tympani hits, piercing high saxophone screams, relentless snare rolls, "
        "bowed contrabass tremolo, cinematic climax of a detective pursuit through rainy alleys, dread and paranoia, "
        "no vocals, no electronic elements."),

    ("editorial", "home"): ("sfx", 22,
        "Sophisticated high-fashion magazine cover ambient. Sparse pizzicato string quartet staccato notes, "
        "distant glassy synth pad sustained, soft sub-bass pulse every 4 bars, elegant staccato grand piano minor chord, "
        "subtle orchestral brass swell in distance, light shaker texture. Cold refined cinematic thriller mood, "
        "minor key, 80 BPM implied pulse, couture runway tension. Seamless loopable ambient."),
    ("editorial", "freerun"): ("sfx", 22,
        "Elegant cinematic walking run atmosphere, 95 BPM steady. Piano staccato motif repeating in minor key, "
        "pizzicato violin rhythmic ostinato, warm cello drone, subtle shaker percussion, distant glassy synth pad, "
        "occasional orchestral swell. Sophisticated editorial thriller pacing, Vogue runway mystery mood, no vocals. "
        "Seamless loopable ambient."),
    ("editorial", "marathon"): ("music", 30000,
        "Glossy orchestral thriller running score, 162 BPM, minor key. Driving pizzicato strings ostinato, "
        "pounding piano staccato in octaves, cinematic orchestral brass swells, powerful timpani and snare percussion, "
        "elegant dramatic chase energy, high-fashion couture runway thriller soundtrack, sophisticated intensity, "
        "no vocals, no electronic beats."),
    ("editorial", "doppel"): ("music", 30000,
        "Tense editorial thriller chase instrumental, 155 BPM, minor key climax. Urgent dissonant string stabs, "
        "sub-bass throb on downbeats, brass bursts, aggressive orchestral percussion, piano staccato urgency, "
        "pizzicato ostinato, cinematic dread of a shadow pursuing through a couture atrium. No vocals, no electronic sounds."),

    ("cyber", "home"): ("sfx", 22,
        "Neo-noir cyberpunk neon megacity rooftop ambient. Dark synthwave analog pad drone, deep sub-bass slow pulse every 4 bars, "
        "distant rain on neon signs, subtle arpeggiator glitch loop high end, vocoder whispered texture ghost, "
        "808 kick slow pulse, faint industrial clangs in distance, modular synth fragments. Blade Runner atmosphere, "
        "minor key, 70 BPM implied, cold and vast. Seamless loopable ambient."),
    ("cyber", "freerun"): ("sfx", 22,
        "Dark synthwave night walking tempo, 90 BPM steady. Warm analog bass sequence arpeggio, 808 kick steady pulse, "
        "filtered glitchy arpeggiator high end, vocoder pad texture layered, distant modular synth fragments, "
        "subtle rain. Minor key neon noir solo rooftop walk. Seamless loopable ambient, no vocals."),
    ("cyber", "marathon"): ("music", 30000,
        "Intense cybernetic marathon run instrumental, 165 BPM, minor key dystopian. Heavy 808 and distorted kick on every beat, "
        "pulsing analog acid bass synth, aggressive arpeggiator high end, modular synth stabs, vocoder chop textures, "
        "industrial percussion hits, sharp hi-hat 16ths, cold cyberpunk chase energy, Blade Runner meets Akira soundtrack, "
        "no vocals."),
    ("cyber", "doppel"): ("music", 30000,
        "Industrial cyberpunk chase instrumental, 155 BPM, minor key. Aggressive distorted 808 sub-bass, glitch stab hits, "
        "pounding metallic drums, vocoder scream fragments, modular noise bursts, sub-bass throbs, dissonant arpeggio patterns, "
        "alarm tones, dystopian doppelganger AI hunter pursuit through neon alleys, no vocals."),
}

# ---------- SFX 15 signature specs ----------
SFX_SPECS = {
    # (theme, name): (duration_s, prompt)
    ("noir", "zippo_strike"): (1.6,
        "Classic brass Zippo lighter flick and flame ignition, crisp metallic click of the hinge then soft flame whoosh, "
        "vintage 1940s feel, intimate close-up foley, no music, single one-shot."),
    ("noir", "typewriter_stamp"): (1.3,
        "Single vintage typewriter key strike with carriage clack and tiny bell ding tail, mechanical and crisp, close-up, no music, one-shot."),
    ("noir", "revolver_cock"): (1.1,
        "Single revolver hammer cocking click, metallic precise, cinematic close-up sound design, dry room, no music, one-shot."),
    ("noir", "rain_splash"): (1.6,
        "Single heavy footstep splash into a deep rain puddle on pavement, wet splatter with long reverb tail, "
        "cinematic rainy noir night, no music, one-shot."),
    ("noir", "vintage_radio"): (1.8,
        "Brief 1940s vintage tube radio burst with static crackle and distant muted orchestra snippet cutting off abruptly, "
        "mono narrow-band frequency response, nostalgic noir feel, one-shot."),

    ("editorial", "camera_shutter"): (1.1,
        "Single professional DSLR camera shutter click with soft motor wind, crisp and mechanical, fashion shoot recording, "
        "clean clear foley, no music, one-shot."),
    ("editorial", "page_turn"): (1.5,
        "Single glossy magazine page turn with subtle paper flick and short elegant pizzicato string accent at the end, "
        "refined editorial one-shot, no music loop."),
    ("editorial", "champagne_pop"): (1.6,
        "Champagne bottle cork pop with brief fizzy release, celebratory and elegant, crystal-clean studio recording, one-shot."),
    ("editorial", "glass_clink"): (1.5,
        "Crystal champagne flute clink with short sustained shimmer and soft string resonance tail, sophisticated, one-shot."),
    ("editorial", "ink_splash"): (1.5,
        "Single wet ink splash on glossy paper with soft low string tremolo underneath, dramatic editorial accent, one-shot."),

    ("cyber", "system_boot"): (2.0,
        "Short system boot sequence: modular synth beeps ascending in pitch then vocoder chord swell resolving, "
        "Blade Runner terminal boot feel, no music loop, one-shot."),
    ("cyber", "data_pulse"): (1.5,
        "Digital data transmission pulse, short glitch chirps stepping down then a sub-bass drop tail, "
        "cyberpunk UI feedback, one-shot."),
    ("cyber", "proximity_alarm"): (1.8,
        "Cyberpunk proximity alarm: two rising synth beep pulses with sub-bass throb and brief static, Blade Runner AI warning, one-shot."),
    ("cyber", "system_cleared"): (1.5,
        "System cleared confirmation chord with vocoder shimmer rising then fading, sci-fi AI success chime, one-shot."),
    ("cyber", "error_static"): (1.7,
        "Glitch error buzz with descending vocoder drone and static crackle, cyberpunk system malfunction, one-shot."),
}

# ---------- TTS 30 lines ----------
TTS_LINES = {
    "noir": [
        ("start_run",        "어둠이 내렸다. 오늘 밤도 사건은 당신의 몫이야."),
        ("start_doppel",     "그림자가 따라붙었어. 따돌려, 천천히 숨을 쉬면서."),
        ("checkpoint_1km",   "일 킬로미터. 담배 한 대 필 여유는 있군."),
        ("near_shadow",      "놈이 바로 뒤야. 뛰어, 뒤돌아보지 말고."),
        ("critical",         "코앞이야. 지금 안 뛰면 끝장이다."),
        ("regained",         "한 블록 벌렸군. 숨 고르고 계속 가."),
        ("victory",          "사건 종결. 당신의 승리야."),
        ("defeat",           "케이스는 닫혔다. 다음 밤을 기약하지."),
        ("encourage_early",  "아직 밤은 길어. 페이스를 지켜."),
        ("encourage_late",   "마지막 골목이야. 끝까지 가."),
    ],
    "editorial": [
        ("start_run",        "오늘의 커버 스토리는 당신입니다. 시작하세요."),
        ("start_doppel",     "그림자가 취재를 시작했어요. 도망치세요."),
        ("checkpoint_1km",   "일 킬로미터. 헤드라인이 되기엔 충분한 거리예요."),
        ("near_shadow",      "뒤를 확인하지 마세요. 셔터 소리가 들립니다."),
        ("critical",         "화보의 클라이맥스. 지금이 결정적 순간입니다."),
        ("regained",         "간격이 벌어졌어요. 호흡을 유지하세요."),
        ("victory",          "완벽한 커버. 이번 호의 주인공입니다."),
        ("defeat",           "이번 이슈는 여기서 마감. 다음 호를 기대하세요."),
        ("encourage_early",  "아직 초반입니다. 우아하게 나아가세요."),
        ("encourage_late",   "마지막 페이지. 엔딩을 장식하세요."),
    ],
    "cyber": [
        ("start_run",        "시스템 온라인. 러닝 프로토콜을 시작합니다."),
        ("start_doppel",     "도플갱어 감지. 회피 기동을 개시하세요."),
        ("checkpoint_1km",   "체크포인트 일 킬로미터 통과. 시스템 정상."),
        ("near_shadow",      "근접 경보. 추적자가 오차 범위 안에 있습니다."),
        ("critical",         "위험. 충돌 직전. 즉시 가속하세요."),
        ("regained",         "거리 재확보. 안전 영역으로 복귀했습니다."),
        ("victory",          "미션 클리어. 추적자 신호가 소실되었습니다."),
        ("defeat",           "연결 종료. 시스템 셧다운."),
        ("encourage_early",  "초기 구간. 에너지를 비축하세요."),
        ("encourage_late",   "최종 구간. 모든 자원을 소모하세요."),
    ],
}


def gen_bgm(theme, slot):
    t = THEME_TO_T[theme]
    fname = f"{t}_{'chase' if slot == 'doppel' else slot}_v1.mp3"
    dst = THEMES_DIR / fname
    raw = RAW_DIR / f"{t}_{slot}_v1.raw.mp3"
    api, dur, prompt = BGM_SPECS[(theme, slot)]
    print(f"[BGM] {theme}/{slot} → {fname} ({api}, {dur}{'s' if api=='sfx' else 'ms'})")
    if api == "sfx":
        content, err = call_sfx(prompt, duration_s=dur, loop=True)
    else:
        content, err = call_music(prompt, dur)
    if content is None:
        print(f"  FAIL: {err}")
        return False
    raw.write_bytes(content)
    ok = loudnorm(raw, dst)
    return ok


def gen_sfx(theme, name):
    dur, prompt = SFX_SPECS[(theme, name)]
    fname = f"{THEME_TO_T[theme]}_{name}.mp3"
    dst = SFX_DIR / fname
    raw = RAW_DIR / f"sfx_{fname}.raw.mp3"
    print(f"[SFX] {theme}/{name} → {fname} ({dur}s)")
    content, err = call_sfx(prompt, duration_s=dur, loop=False)
    if content is None:
        print(f"  FAIL: {err}")
        return False
    raw.write_bytes(content)
    return loudnorm(raw, dst, target_i=-18)  # SFX slightly louder than BGM


def gen_tts(theme, name, text):
    voice = VOICES[theme]
    fname = f"{THEME_TO_T[theme]}_tts_{name}.mp3"
    dst = TTS_DIR / fname
    raw = RAW_DIR / f"tts_{fname}.raw.mp3"
    print(f"[TTS] {theme}/{name} → {fname}")
    content, err = call_tts(text, voice)
    if content is None:
        print(f"  FAIL: {err}")
        return False
    raw.write_bytes(content)
    return loudnorm(raw, dst, target_i=-16)  # TTS -16 LUFS (대화형)


def stage_bgm():
    tasks = [(t, s) for t in ("noir", "editorial", "cyber") for s in ("home", "freerun", "marathon", "doppel")]
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as ex:
        results = list(ex.map(lambda p: gen_bgm(*p), tasks))
    ok = sum(results)
    print(f"BGM done: {ok}/{len(tasks)}")
    return ok == len(tasks)


def stage_sfx():
    tasks = [(t, n) for t, n in SFX_SPECS.keys()]
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as ex:
        results = list(ex.map(lambda p: gen_sfx(*p), tasks))
    ok = sum(results)
    print(f"SFX done: {ok}/{len(tasks)}")
    return ok == len(tasks)


def stage_tts():
    tasks = [(theme, name, text) for theme, lines in TTS_LINES.items() for name, text in lines]
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as ex:
        results = list(ex.map(lambda p: gen_tts(*p), tasks))
    ok = sum(results)
    print(f"TTS done: {ok}/{len(tasks)}")
    return ok == len(tasks)


if __name__ == "__main__":
    stage = sys.argv[1] if len(sys.argv) > 1 else "all"
    ok = True
    if stage in ("bgm", "all"):
        ok &= stage_bgm()
    if stage in ("sfx", "all"):
        ok &= stage_sfx()
    if stage in ("tts", "all"):
        ok &= stage_tts()
    sys.exit(0 if ok else 1)
