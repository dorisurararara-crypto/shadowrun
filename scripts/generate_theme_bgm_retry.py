"""
ElevenLabs Music API — ToS 필터 거부된 5 트랙 재시도.
아티스트/영화명 레퍼런스 제거, 추상 기술 용어만 사용.
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

TRACKS = [
    ('t4_home_v1.mp3',
     'Sophisticated modern orchestral and minimal electronica ambient instrumental. '
     'Dark sustained string pad, subtle high piano notes with long reverb tails, '
     'soft analog synth pulse slow breath, warm sub-bass drone, '
     'distant felt timpani roll, tiny glass percussion accent. '
     'Refined and tense but controlled. No drums, no vocals. '
     '80 BPM, D minor, clean mix, instrumental only, -23 LUFS target.'),

    ('t4_home_v2.mp3',
     'Modern cinematic editorial instrumental ambient. '
     'Slow piano solo motif with warm tape noise texture, muted string ensemble swells, '
     'soft synth arpeggio slowly evolving, warm bass drone underneath. '
     'Sophisticated intellectual mood, feels expensive and restrained. '
     'Controlled tension. No vocals, no drums, no horror. '
     '75 BPM, A minor, clean mix, -23 LUFS target, instrumental only.'),

    ('t5_home_v1.mp3',
     'Dark synthwave ambient instrumental for standby screen. '
     'Slow analog synth pad sustained long notes with chorus and reverb, '
     'warm sub-bass drone at tonic, arpeggiated digital synth slow sixteenth notes, '
     'distant electronic cityscape wind and rain texture, occasional metallic ting accent. '
     'Neon-lit rainy night mood, melancholic futurism. '
     'No drums, no beat, no vocals. '
     '75 BPM, D minor, clean mix, -23 LUFS, instrumental only.'),

    ('t5_home_v2.mp3',
     'Dark synthwave instrumental ambient. '
     'Analog synth pad wide stereo spread, soft tape-warped piano chord tones, '
     'pulsing sub-bass slow whole notes, glassy bell synth high sparkle accents, '
     'distant thunder rumble and electronic buzz ambient texture. '
     'Future-noir meditation, red-cyan contrast feeling. '
     'No drums, no vocals. '
     '70 BPM, A minor, clean mix, -23 LUFS target, instrumental only.'),

    ('t5_marathon_v1.mp3',
     'Driving synthwave instrumental for fast-paced running. '
     'Pulsing analog synth bassline at 160 BPM, gated reverb snare on beats 2 and 4, '
     'arpeggiated digital synth lead motif repeating, pad chord progression, '
     'classic analog electronic drum kit at steady tempo. '
     'Futuristic motorcycle pursuit energy, forward motion, determined drive. '
     'No vocals, no extreme frequencies, no horror. '
     '160 BPM, E minor, clean mix, -23 LUFS, instrumental only.'),
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
            print(f'  FAIL attempt {attempt + 1}/{retries}: HTTP {e.code}', flush=True)
            print(f'    body: {error_body[:300]}', flush=True)
            if e.code in (401, 403):
                return False
            if attempt < retries - 1:
                time.sleep(8 * (attempt + 1))
        except Exception as e:
            print(f'  ERROR attempt {attempt + 1}/{retries}: {type(e).__name__}: {e}', flush=True)
            if attempt < retries - 1:
                time.sleep(8 * (attempt + 1))
    return False


def main():
    total = len(TRACKS)
    success = 0
    fail_files = []
    t_start = time.time()

    print(f'ElevenLabs Music API retry — {total} 트랙 × 30초', flush=True)

    for i, (filename, prompt) in enumerate(TRACKS):
        print(f'[{i + 1}/{total}] {filename}', flush=True)
        ok = generate_track(filename, prompt)
        if ok:
            success += 1
        else:
            fail_files.append(filename)
        time.sleep(2)

    elapsed = time.time() - t_start
    print('=' * 60, flush=True)
    print(f'재시도 완료: {success}/{total} | {elapsed:.0f}s', flush=True)
    if fail_files:
        print(f'여전히 실패: {fail_files}', flush=True)
        sys.exit(1)


if __name__ == '__main__':
    main()
