"""
ElevenLabs Music API — 테마 2/4/5 러닝 BGM (자유 + 도플갱어) 각 2트랙씩 12 트랙.
크레딧 예상: 30초 × 12 × 100 c/s = 36,000 크레딧.
출력: assets/audio/themes/.raw/ (정규화 전), 별도 ffmpeg 정규화 스크립트로 themes/ 이동.
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
RAW_DIR = os.path.join(ROOT, 'assets', 'audio', 'themes', '.raw')
os.makedirs(RAW_DIR, exist_ok=True)

TRACKS = [
    # ── Film Noir (T2): 자유 러닝 ──
    ('t2_freerun_v1.mp3',
     'Slow film noir jazz ambient instrumental for walking contemplation. '
     'Upright bass slow walking line, brushed drum ghost notes barely audible, '
     'solitary muted trumpet far back, soft felt piano chord punctuation, '
     'distant rain texture. Cool 1940s detective reverie, no tension. '
     '75 BPM, A minor blues, no vocals, no horror. Clean -23 LUFS, instrumental.'),

    ('t2_freerun_v2.mp3',
     'Film noir ambient instrumental for evening jogging reverie. '
     'Walking upright bass, brushed jazz drums low volume, clarinet legato solo phrases, '
     'warm felt piano chord comping, light vinyl crackle texture. '
     'Smoky reflective mood, no urgency, no fear. '
     '70 BPM, D minor, instrumental only, clean -23 LUFS mix.'),

    # ── Film Noir (T2): 도플갱어 추격 ──
    ('t2_chase_v1.mp3',
     'Tense noir jazz pursuit instrumental, urgent detective chase score. '
     'Fast walking upright bass urgent pattern, tight brushed snare driving 140 BPM, '
     'muted trumpet staccato alarm phrases, dark piano triplet runs, '
     'baritone saxophone sustained tension notes, ride cymbal accent. '
     'Cinematic pursuit energy, thriller not horror, no screams. '
     '140 BPM, E minor, instrumental only, clean -23 LUFS mix.'),

    ('t2_chase_v2.mp3',
     'Aggressive noir jazz chase instrumental for doppelganger pursuit. '
     'Urgent upright bass running line, tight kit drums 150 BPM with rimshot accents, '
     'dark piano ostinato, trumpet alarm stabs, organ tension chords sustained, '
     'occasional glass break ambient texture. '
     'Dangerous film noir hunt mood, no vocals, no gore. '
     '150 BPM, C minor, instrumental only, clean mix -23 LUFS.'),

    # ── Editorial (T4): 자유 러닝 ──
    ('t4_freerun_v1.mp3',
     'Modern sophisticated ambient instrumental for contemplative running. '
     'Warm felt piano slow motif, sustained dark string pad, soft electronic pulse, '
     'warm sub-bass drone, subtle vibraphone accents. '
     'Elegant editorial mood, controlled, refined. No drums, no vocals. '
     '85 BPM, A minor, instrumental only, clean -23 LUFS.'),

    ('t4_freerun_v2.mp3',
     'Cinematic editorial ambient instrumental for easy-pace running. '
     'Slow piano single-note motif, swelling string ensemble, '
     'sparse modern electronic pulse, warm pad drone underneath. '
     'Sophisticated thriller intro mood, measured tension. '
     'No drums, no vocals. 80 BPM, D minor, clean -23 LUFS mix, instrumental.'),

    # ── Editorial (T4): 도플갱어 추격 ──
    ('t4_chase_v1.mp3',
     'Driving modern thriller instrumental for pursuit scene. '
     'Pulsing synth bass on every downbeat, tight programmed kick/snare 150 BPM, '
     'staccato string ostinato repeating cell, urgent piano cluster stabs, '
     'brass swell accents, electronic pulse layer. '
     'Modern editorial thriller chase, elegant menace not slasher. '
     '150 BPM, E minor, no vocals, clean -23 LUFS, instrumental only.'),

    ('t4_chase_v2.mp3',
     'Tense modern orchestral electronic chase instrumental. '
     'Driving synth bass ostinato, tight drum kit 155 BPM with cross-stick snare, '
     'low string ostinato building, piano staccato cells, '
     'brass rising swells, electronic shimmer layer. '
     'High-end thriller pursuit, refined tension. No vocals. '
     '155 BPM, G minor, instrumental only, clean -23 LUFS.'),

    # ── Neo-Noir Cyber (T5): 자유 러닝 ──
    ('t5_freerun_v1.mp3',
     'Chilled cyberpunk synthwave instrumental for easy-pace running. '
     'Warm analog synth pad sustained chords, slow arpeggiated digital synth, '
     'soft sub-bass drone, gentle gated-reverb snare ghost hits at 90 BPM, '
     'distant city rain texture ambient. '
     'Rainy neon night stroll mood, no tension. No vocals. '
     '90 BPM, D minor, instrumental only, clean -23 LUFS.'),

    ('t5_freerun_v2.mp3',
     'Midtempo synthwave instrumental for jogging flow. '
     'Smooth analog synth pad, steady sub-bass pulse, arpeggiated digital synth melody, '
     'light electronic drum kit at 100 BPM with soft hi-hat, glassy bell highlights. '
     'Futurist chill mood, confident motion. No vocals, no horror. '
     '100 BPM, A minor, instrumental only, clean -23 LUFS.'),

    # ── Neo-Noir Cyber (T5): 도플갱어 추격 ──
    ('t5_chase_v1.mp3',
     'Aggressive synthwave chase instrumental for pursuit scene. '
     'Pulsing analog synth bassline at 150 BPM, tight gated snare on 2 and 4, '
     'driving sawtooth synth arpeggio, pad tension chords, '
     'distorted synth lead stabs, industrial percussion accents. '
     'Futuristic motorcycle pursuit energy, dangerous drive, no horror screams. '
     '150 BPM, E minor, no vocals, instrumental only, clean -23 LUFS.'),

    ('t5_chase_v2.mp3',
     'Aggressive darksynth chase instrumental for doppelganger pursuit. '
     'Distorted synth bass ostinato, tight electronic drums 155 BPM, '
     'sawtooth synth lead repeating cell, industrial percussion, '
     'glitched synth stab accents, pad sustained menace layer. '
     'Cyberpunk chase scene energy, relentless drive. No vocals, no gore. '
     '155 BPM, F minor, instrumental only, clean -23 LUFS.'),
]


def generate_track(filename, prompt, retries=3):
    raw_path = os.path.join(RAW_DIR, filename)
    if os.path.exists(raw_path) and os.path.getsize(raw_path) > 50000:
        print(f'  SKIP (raw 존재): {filename}', flush=True)
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
                print(f'  OK: {filename} ({size_kb:.1f} KB, {dt:.1f}s)', flush=True)
                return True
        except urllib.error.HTTPError as e:
            error_body = e.read().decode('utf-8', errors='replace')
            print(f'  FAIL {attempt + 1}/{retries}: HTTP {e.code}', flush=True)
            print(f'    body: {error_body[:300]}', flush=True)
            if e.code in (401, 403):
                return False
            if attempt < retries - 1:
                time.sleep(8 * (attempt + 1))
        except Exception as e:
            print(f'  ERROR {attempt + 1}/{retries}: {type(e).__name__}: {e}', flush=True)
            if attempt < retries - 1:
                time.sleep(8 * (attempt + 1))
    return False


def main():
    total = len(TRACKS)
    success = 0
    fail_files = []
    t0 = time.time()

    print(f'ElevenLabs Music API — {total} 러닝 트랙 × 30초 (예상 36,000 크레딧)', flush=True)
    for i, (filename, prompt) in enumerate(TRACKS):
        print(f'[{i + 1}/{total}] {filename}', flush=True)
        if generate_track(filename, prompt):
            success += 1
        else:
            fail_files.append(filename)
        time.sleep(2)

    print('=' * 60, flush=True)
    print(f'완료: {success}/{total} | {time.time() - t0:.0f}s', flush=True)
    if fail_files:
        print(f'실패: {fail_files}', flush=True)
        sys.exit(1)


if __name__ == '__main__':
    main()
