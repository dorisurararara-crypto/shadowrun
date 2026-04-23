"""
ElevenLabs Sound Effects API — 테마 2/4/5 전용 signature SFX 9개.
가이드 §3 기준: duration_seconds × 40c/s. 각 clip 2.5s → 9 × 2.5 × 40 = 900c.

클립:
  Film Noir (T2):      start / victory / defeat
  Editorial (T4):      start / victory / defeat
  Neo-Noir Cyber (T5): start / victory / defeat
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
OUT_DIR = os.path.join(ROOT, 'assets', 'audio', 'sfx')
os.makedirs(OUT_DIR, exist_ok=True)

SFX = [
    # ── Film Noir (T2) ──
    ('sfx_noir_start.mp3',
     'Vintage typewriter quick burst of three clacks followed by a metallic bell ding, '
     '1940s detective office ambiance, subtle paper rustle, clean mono 2 seconds'),
    ('sfx_noir_victory.mp3',
     'Cork popping from champagne bottle, glasses clinking warmly, distant jazz club '
     'applause, classic 1940s celebration stinger, warm reverb 2 seconds'),
    ('sfx_noir_defeat.mp3',
     'Slow single slam of a heavy wooden door closing with distant rain and a sad '
     'muted trumpet tail note, noir detective finality 2.5 seconds'),

    # ── Editorial (T4) ──
    ('sfx_editorial_start.mp3',
     'Camera shutter snap followed by a fast magazine page flip and a crisp paper '
     'tear, professional press release stinger, clean 2 seconds'),
    ('sfx_editorial_victory.mp3',
     'Sharp bright bell chime with a short crowd applause burst and a short fanfare '
     'string swell, editorial headline drop 2 seconds'),
    ('sfx_editorial_defeat.mp3',
     'Paper shredder grinding briefly and stopping with a final deep thud, '
     'magazine cover shredded, somber tail 2 seconds'),

    # ── Neo-Noir Cyber (T5) ──
    ('sfx_cyber_start.mp3',
     'Modem dial-up startup burst followed by an ascending digital synth bleep and a '
     'single deep sub-bass drop, cyberpunk boot sequence 2 seconds'),
    ('sfx_cyber_victory.mp3',
     'Ascending chiptune arpeggio with a bright synth fanfare, neon achievement '
     'unlock jingle, clean futuristic 2 seconds'),
    ('sfx_cyber_defeat.mp3',
     'Glitch error burst with descending distorted synth tone, power down buzz, '
     'static hiss tail, dystopian shutdown 2 seconds'),
]


def gen(filename, prompt, duration=2.5, retries=3):
    out_path = os.path.join(OUT_DIR, filename)
    if os.path.exists(out_path) and os.path.getsize(out_path) > 20000:
        print(f'  SKIP: {filename}', flush=True)
        return True
    body = json.dumps({
        'text': prompt,
        'duration_seconds': duration,
        'prompt_influence': 0.35,
        'model_id': 'eleven_text_to_sound_v2',
    }).encode('utf-8')
    url = 'https://api.elevenlabs.io/v1/sound-generation?output_format=mp3_44100_192'
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url, data=body, headers={
                'xi-api-key': API_KEY,
                'Content-Type': 'application/json',
            })
            t0 = time.time()
            with urllib.request.urlopen(req, timeout=180) as resp:
                data = resp.read()
                with open(out_path, 'wb') as f:
                    f.write(data)
                print(f'  OK: {filename} ({len(data)/1024:.1f} KB, {time.time()-t0:.1f}s)', flush=True)
                return True
        except urllib.error.HTTPError as e:
            body_text = e.read().decode('utf-8', errors='replace')
            print(f'  FAIL {attempt + 1}/{retries}: HTTP {e.code}', flush=True)
            print(f'    body: {body_text[:300]}', flush=True)
            if e.code in (401, 403):
                return False
            if attempt < retries - 1:
                time.sleep(6 * (attempt + 1))
        except Exception as e:
            print(f'  ERROR {attempt + 1}/{retries}: {type(e).__name__}: {e}', flush=True)
            if attempt < retries - 1:
                time.sleep(6 * (attempt + 1))
    return False


def main():
    total = len(SFX)
    ok = 0
    fail = []
    t0 = time.time()
    print(f'ElevenLabs Sound Effects — {total} SFX × 2.5s = ~{total * 2.5 * 40:.0f} credits', flush=True)
    for i, (filename, prompt) in enumerate(SFX):
        print(f'[{i + 1}/{total}] {filename}', flush=True)
        if gen(filename, prompt):
            ok += 1
        else:
            fail.append(filename)
        time.sleep(1.5)
    print('=' * 60, flush=True)
    print(f'완료: {ok}/{total} | {time.time() - t0:.0f}s', flush=True)
    if fail:
        print(f'실패: {fail}', flush=True)
        sys.exit(1)


if __name__ == '__main__':
    main()
