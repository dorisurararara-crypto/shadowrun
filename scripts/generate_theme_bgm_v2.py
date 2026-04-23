"""
ElevenLabs Music API 로 신규 3개 테마 BGM 생성.

대상 테마:
  - Film Noir (T2)       → t2_home_v1/v2, t2_marathon_v1/v2
  - Editorial (T4)       → t4_home_v1/v2, t4_marathon_v1/v2
  - Neo-Noir Cyber (T5)  → t5_home_v1/v2, t5_marathon_v1/v2

사용법:
    export $(grep -v '^#' .env | xargs)
    python3 scripts/generate_theme_bgm_v2.py

크레딧 예상: 30초 × 12 트랙 × 100 c/s = 36,000 크레딧.
출력: assets/audio/themes/.raw/ (정규화 전 원본), 이후 ffmpeg 로 -23 LUFS 정규화하여 themes/ 로 배치.
"""
import urllib.request
import urllib.error
import json
import os
import sys
import time

API_KEY = os.environ.get('ELEVENLABS_API_KEY', '')
if not API_KEY:
    print('ERROR: ELEVENLABS_API_KEY 환경변수 필요', file=sys.stderr)
    sys.exit(1)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUTDIR = os.path.join(ROOT, 'assets', 'audio', 'themes')
RAW_DIR = os.path.join(OUTDIR, '.raw')
os.makedirs(OUTDIR, exist_ok=True)
os.makedirs(RAW_DIR, exist_ok=True)

TRACKS = [
    # ============================================================
    # Film Noir (T2) — 1940s detective mood. Cream/brass/wine.
    # Cormorant Garamond italic / Oswald caps 폰트 톤과 어울리게.
    # ============================================================
    ('t2_home_v1.mp3',
     'Slow 1940s film noir jazz ambient instrumental for standby home screen. '
     'Upright acoustic double bass slow walking line, brushed jazz drums barely audible, '
     'smoky muted trumpet solitary phrases far back in mix, '
     'soft felt piano chord stabs with long reverb, distant rain ambience texture. '
     'Classic detective mood, late night empty office, cigarette smoke. '
     'No vocals, no harsh elements, no horror. '
     '70 BPM, D minor, Cormorant-era noir like Maltese Falcon or Chinatown. '
     'Clean mix, target -23 LUFS, instrumental only.'),

    ('t2_home_v2.mp3',
     'Classic film noir instrumental ambient for detective app home screen. '
     'Upright bass slow legato, brushed snare ghost notes, '
     'solo clarinet bluesy phrase in lower register, '
     'warm felt piano minor 7th chords, light vinyl crackle texture. '
     'Cool, smoky, mysterious mood, 1940s jazz noir. '
     'No drums on downbeat, no vocals, no scary elements. '
     '65 BPM, A minor blues, classic noir film score palette. '
     'Clean -23 LUFS mix, instrumental only.'),

    ('t2_marathon_v1.mp3',
     'Driving neo-noir jazz instrumental for marathon running pace. '
     'Walking upright bass at 160 BPM, brushed drum kit tight groove with ride cymbal, '
     'muted trumpet staccato motif, piano minor arpeggios urgent drive, '
     'baritone saxophone long notes for tension without horror. '
     'Neo-noir chase film score but positive and motivating, cinematic pursuit energy. '
     'No horror, no fear, no vocals. '
     '160 BPM, G minor, like modern noir film scores Dark City or Sin City. '
     'Clean tight mix, -23 LUFS target, instrumental only.'),

    ('t2_marathon_v2.mp3',
     'Urgent cinematic noir jazz instrumental for long-distance running. '
     'Fast walking bass line, tight brushed snare pattern 160 BPM, '
     'Hammond organ sustained chords, muted trumpet repeating motif, '
     'subtle vibraphone punctuation, dark piano triplet runs. '
     'Sense of drive and pursuit in detective movie chase, not slasher. '
     'No vocals, no screams, no extreme dynamics. '
     '160 BPM, E minor, modern neo-noir film score. '
     'Clean mix, -23 LUFS, instrumental only.'),

    # ============================================================
    # Editorial Thriller (T4) — GQ magazine cover style. Red/black/white.
    # Playfair Display 900 italic logo. Sophisticated + tense.
    # ============================================================
    ('t4_home_v1.mp3',
     'Sophisticated modern orchestral and minimal electronica ambient instrumental. '
     'Dark string pad sustained, subtle piano single high notes with long reverb, '
     'soft analog synth pulse slow breath, warm sub-bass drone, '
     'distant felt timpani roll for drama, tiny glass percussion accent. '
     'Magazine cover intro mood, high-end editorial thriller podcast opener. '
     'Refined, tense but controlled, absolutely not horror. '
     '80 BPM, D minor, like Trent Reznor minimal score or modern editorial documentary. '
     'No vocals, no drums. Clean -23 LUFS mix, instrumental only.'),

    ('t4_home_v2.mp3',
     'Modern cinematic editorial instrumental ambient for thriller app home. '
     'Slow piano solo motif with tape noise, muted string ensemble swells, '
     'soft synth arpeggio slowly evolving, warm bass drone. '
     'Sophisticated, intellectual thriller mood, feels expensive and restrained. '
     'Controlled tension, not fear. No vocals, no drums, no horror. '
     '75 BPM, A minor, like Johan Johannsson or Max Richter film scores. '
     'Clean mix, -23 LUFS target, instrumental only.'),

    ('t4_marathon_v1.mp3',
     'Driving modern cinematic electronic orchestral instrumental for marathon running. '
     'Pulsing synth bass on each downbeat, low string ostinato repeating motif, '
     'tight modern drum kit at 160 BPM with crisp snare on 2 and 4, '
     'piano urgent staccato pattern, tension strings rising. '
     'Modern thriller score drive, editorial chase not slasher. '
     'Sense of pursuit, tension, driving forward motion. '
     'No vocals, no horror, no screams. '
     '160 BPM, E minor, like modern Netflix thriller score. '
     'Clean mix, -23 LUFS, instrumental only.'),

    ('t4_marathon_v2.mp3',
     'Tense modern orchestral electronic instrumental running pace 160 BPM. '
     'Driving synth bass, tight programmed drums, staccato string ostinato, '
     'modern piano cluster stabs, brass swells for building momentum, '
     'subtle electronic pulse layered. '
     'High-end thriller chase score, refined energy not panic. '
     'No vocals, no extreme frequencies, instrumental only. '
     '160 BPM, G minor, editorial thriller TV score like Bodyguard or The Night Manager. '
     'Clean mix, -23 LUFS target.'),

    # ============================================================
    # Neo-Noir Cyber (T5) — Blade Runner. Red neon + cyan.
    # Playfair italic + JetBrains Mono. Synthwave / vaporwave noir.
    # ============================================================
    ('t5_home_v1.mp3',
     'Blade Runner inspired dark synthwave ambient instrumental for cyber app home. '
     'Slow analog synth pad sustained long notes with chorus and reverb, '
     'warm sub-bass drone at tonic, arpeggiated digital synth slow 16th notes, '
     'distant electronic cityscape wind and rain, occasional metallic ting. '
     'Neon-lit rainy cyberpunk city at night, Vangelis style, melancholic futurism. '
     'No drums, no beat, no vocals, no fear. '
     '75 BPM, D minor, like Vangelis Blade Runner or Cliff Martinez Drive. '
     'Clean mix, -23 LUFS, instrumental only.'),

    ('t5_home_v2.mp3',
     'Dark synthwave instrumental ambient for neo-noir cyberpunk app home screen. '
     'Analog synth pad wide stereo, soft lo-fi tape-warped piano chord tones, '
     'pulsing sub-bass slow whole notes, glassy bell synth high sparkle, '
     'distant thunder and neon buzz texture. '
     'Blade Runner 2049 mood, future-noir meditation, red-cyan contrast. '
     'No drums, no vocals, no horror. '
     '70 BPM, A minor, like Hans Zimmer 2049 score or Com Truise. '
     'Clean mix, -23 LUFS target, instrumental only.'),

    ('t5_marathon_v1.mp3',
     'Driving synthwave cyberpunk instrumental for marathon pace running. '
     'Pulsing analog synth bassline at 160 BPM, gated reverb snare on 2 and 4, '
     'arpeggiated digital synth lead motif, pad chord progression, '
     'classic 80s electronic drum kit. '
     'Futuristic chase energy, neon city motorcycle pursuit, not horror. '
     'Drive and motion, cyberpunk thriller. '
     'No vocals, no extreme frequencies. '
     '160 BPM, E minor, like Drive 2011 score Kavinsky or Carpenter Brut. '
     'Clean mix, -23 LUFS, instrumental only.'),

    ('t5_marathon_v2.mp3',
     'Propulsive synthwave instrumental for long-distance running tempo. '
     'Dark synth bass ostinato, tight electronic drums 160 BPM, '
     'sawtooth synth lead melody repeated motif, pad sustained chord, '
     'industrial percussion accents on bar transitions. '
     'Blade Runner chase scene energy, futuristic pursuit, determination and drive. '
     'No horror, no vocals, no panic. '
     '160 BPM, G minor, like Perturbator or modern synthwave cinematic. '
     'Clean mix, -23 LUFS target, instrumental only.'),
]


def generate_track(filename, prompt, retries=3):
    raw_path = os.path.join(RAW_DIR, filename)
    if os.path.exists(raw_path) and os.path.getsize(raw_path) > 50000:
        print(f'  SKIP (raw 존재): {filename}')
        return True

    body = json.dumps({
        'prompt': prompt,
        'music_length_ms': 30000,
        'model_id': 'music_v1',
        'force_instrumental': True,
    }).encode('utf-8')

    url = 'https://api.elevenlabs.io/v1/music?output_format=mp3_44100_192'

    for attempt in range(retries):
        try:
            req = urllib.request.Request(url, data=body, headers={
                'xi-api-key': API_KEY,
                'Content-Type': 'application/json',
            })
            t0 = time.time()
            with urllib.request.urlopen(req, timeout=300) as resp:
                data = resp.read()
                with open(raw_path, 'wb') as f:
                    f.write(data)
                size_kb = len(data) / 1024
                dt = time.time() - t0
                print(f'  OK: {filename} ({size_kb:.1f} KB, {dt:.1f}s)')
                return True
        except urllib.error.HTTPError as e:
            error_body = e.read().decode('utf-8', errors='replace')
            print(f'  FAIL attempt {attempt + 1}/{retries}: HTTP {e.code}')
            print(f'    body: {error_body[:400]}')
            if e.code in (401, 403, 422):
                return False
            if attempt < retries - 1:
                time.sleep(10 * (attempt + 1))
        except Exception as e:
            print(f'  ERROR attempt {attempt + 1}/{retries}: {type(e).__name__}: {e}')
            if attempt < retries - 1:
                time.sleep(10 * (attempt + 1))
    return False


def main():
    total = len(TRACKS)
    success = 0
    fail_files = []
    t_start = time.time()

    print(f'ElevenLabs Music API v2 — {total} 트랙 × 30초 생성 시작')
    print(f'출력 RAW: {RAW_DIR}')
    print()

    for i, (filename, prompt) in enumerate(TRACKS):
        print(f'[{i + 1}/{total}] {filename}')
        ok = generate_track(filename, prompt)
        if ok:
            success += 1
        else:
            fail_files.append(filename)
        time.sleep(2)

    elapsed = time.time() - t_start
    print()
    print('=' * 60)
    print(f'완료: 성공 {success}/{total} | 경과 {elapsed:.0f}s')
    if fail_files:
        print(f'실패 파일: {fail_files}')
        sys.exit(1)


if __name__ == '__main__':
    main()
