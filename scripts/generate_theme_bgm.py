"""
ElevenLabs Music API 로 테마별 BGM 생성 (Pure / Korean Mystic × 자유러닝 / 마라토너).

사용법:
    export ELEVENLABS_API_KEY='<키>'
    python3 scripts/generate_theme_bgm.py

생성물:
    assets/audio/themes/t1_freerun_v1.mp3, t1_freerun_v2.mp3   — Pure 자유러닝
    assets/audio/themes/t1_marathon_v1.mp3, t1_marathon_v2.mp3 — Pure 마라토너
    assets/audio/themes/t3_freerun_v1.mp3, t3_freerun_v2.mp3   — Mystic 자유러닝
    assets/audio/themes/t3_marathon_v1.mp3, t3_marathon_v2.mp3 — Mystic 마라토너

크레딧 예상: 30초 × 8 = 240초 × 100 c/s = 24,000 크레딧.
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
RAW_DIR = os.path.join(OUTDIR, '.raw')  # 정규화 전 원본 보관
os.makedirs(OUTDIR, exist_ok=True)
os.makedirs(RAW_DIR, exist_ok=True)

# 트랙 정의. 각 30초. force_instrumental=True (가사 없음).
TRACKS = [
    # === Pure Cinematic (테마1) ===
    ('t1_freerun_v1.mp3',
     'Cinematic noir minimal piano ambient music for peaceful outdoor running. '
     'Slow dark piano chords with long reverb, soft cello drone bass, distant violins with tremolo. '
     'Brushed snare barely audible texture, rain-like soft synth pad underneath. '
     'No drums, no beat, no vocals. Melancholic but not depressing, film noir mood. '
     'Around 75 BPM, A minor key. Reminiscent of Blade Runner 2049 or Chinatown soundtrack. '
     'Mix clean, target -23 LUFS, no clipping, instrumental only.'),

    ('t1_freerun_v2.mp3',
     'Cinematic noir ambient instrumental for contemplative evening running. '
     'Warm felt piano single-note motif with tape saturation, dark string pad swells, '
     'sub-bass drone holds, distant jazz brush cymbal shimmer. '
     'Occasional solo muted trumpet phrase far back in mix. No percussion, no beat, no vocals. '
     'Moody, introspective, cinematic. Around 70 BPM, D minor key. '
     'Clean mix, -23 LUFS target, no distortion, instrumental only.'),

    ('t1_marathon_v1.mp3',
     'Cinematic noir rhythmic instrumental running score. '
     'Driving low-register piano ostinato motif, pulsing synth bass on each downbeat, '
     'brushed drum kit at 160 BPM with steady ride cymbal pattern, dark strings unison melody. '
     'Sparse brass swells for motivation without horror. '
     'Cinematic chase-style energy but positive and motivating, no fear. '
     '160 BPM, A minor, modern film score cinematic. '
     'No vocals, no jazz improvisation, clean -23 LUFS mix, original composition.'),

    ('t1_marathon_v2.mp3',
     'Instrumental cinematic noir music for marathon running pace. '
     'Urgent staccato piano arpeggio, driving synth bass, tight brushed drums 160 BPM, '
     'cello ostinato building tension, short brass stabs on bar ends. '
     'Sense of pursuit and drive, not horror. Thriller score mood, not slasher. '
     '160 BPM, E minor. Mix tight, no clipping, target -23 LUFS. '
     'No vocals, no long tails, instrumental cinematic.'),

    # === Korean Mystic (테마3) ===
    ('t3_freerun_v1.mp3',
     'Korean traditional zen ambient instrumental music for peaceful meditative running. '
     'Soft gayageum (Korean 12-string zither) slow plucked melody with long reverb, '
     'gentle daegeum (Korean bamboo flute) distant airy phrases, subtle bowl gong punctuation, '
     'soft natural wind and breath textures, warm analog synth pad underneath. '
     'No percussion, no horror, no vocals, no heartbeat. '
     'Spiritual, peaceful, contemplative mountain temple mood. '
     '85 BPM, D minor pentatonic, authentic Korean traditional sound. '
     'Clean mix, -23 LUFS target, instrumental only.'),

    ('t3_freerun_v2.mp3',
     'Korean traditional ambient instrumental for quiet early-morning running. '
     'Haegeum (Korean bowed string) slow legato melody, sparse geomungo (Korean six-string zither) '
     'bass notes, soft wooden mokutaku rhythmic click on bar starts only, '
     'faint wind chimes, warm pad holding tonic drone underneath. '
     'Peaceful, reverent, folk-mystical mood, absolutely no horror or fear elements. '
     '80 BPM, A minor pentatonic. Clean mix, -23 LUFS, instrumental only, no vocals.'),

    ('t3_marathon_v1.mp3',
     'Korean traditional percussion-driven instrumental running music. '
     'Janggu (Korean hourglass drum) steady rhythmic pulse at 160 BPM, '
     'buk (Korean barrel drum) deep accents on beats 1 and 3, '
     'daegeum (Korean bamboo flute) soaring melodic phrases over the beat, '
     'bak (wooden clapper) metallic accents for running pace cue, '
     'minimal gayageum counter-melody for texture. '
     'Warm, motivating, cinematic folk festival feel. '
     'Absolutely no horror, fear, or gloom. Drive and momentum, like traditional folk marathon. '
     '160 BPM, E minor, instrumental only, no vocals. Clean -23 LUFS mix.'),

    ('t3_marathon_v2.mp3',
     'Korean traditional driving instrumental for long-distance running tempo. '
     'Bak wooden clapper downbeat pulse, janggu tight dance rhythm at 165 BPM, '
     'piri (Korean double-reed oboe) ornamented melody line, sogo (small hand drum) rolls in fills, '
     'haegeum countermelody in higher register, buk low accents. '
     'Celebratory, energetic, motivating folk-modern fusion. '
     'No horror, no vocals, no slow sections. '
     '165 BPM, D minor pentatonic, clean mix, -23 LUFS target, instrumental only.'),
]


def generate_track(filename, prompt, retries=3):
    """Music API 로 1개 트랙 생성. 재시도 3회, exponential backoff."""
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
                return False  # 재시도 무의미
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

    print(f'ElevenLabs Music API — {total} 트랙 × 30초 생성 시작')
    print(f'출력 RAW: {RAW_DIR}')
    print()

    for i, (filename, prompt) in enumerate(TRACKS):
        print(f'[{i + 1}/{total}] {filename}')
        ok = generate_track(filename, prompt)
        if ok:
            success += 1
        else:
            fail_files.append(filename)
        time.sleep(2)  # API 간격

    elapsed = time.time() - t_start
    print()
    print('=' * 60)
    print(f'완료: 성공 {success}/{total} | 경과 {elapsed:.0f}s')
    if fail_files:
        print(f'실패 파일: {fail_files}')
        sys.exit(1)


if __name__ == '__main__':
    main()
