"""ElevenLabs Sound Effects API로 배경음 생성"""
import urllib.request, json, os, time

API_KEY = 'sk_00bc51e2397013aa4ff2a2c1e6389c01c31cb0ed94b3abed'
OUTDIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'assets', 'audio')
os.makedirs(OUTDIR, exist_ok=True)

# (파일명, 프롬프트, 길이초, prompt_influence)
BGM_LIST = [
    # 도플갱어 배경음
    ('bgm_peaceful.mp3', 'Gentle birds chirping in a forest with light wind blowing through leaves, peaceful morning nature sounds, ambient outdoor running atmosphere', 15.0, 0.3),
    ('bgm_calm_wind.mp3', 'Soft wind blowing with distant low drone humming, slightly eerie outdoor atmosphere, calm but unsettling ambient sound', 15.0, 0.3),
    ('bgm_tension_low.mp3', 'Low tension strings with wind, dark ambient atmosphere, something watching from the shadows, subtle dread building', 15.0, 0.3),
    ('bgm_dark_ambient.mp3', 'Dark ambient drone with occasional twig snapping sounds, forest at night, eerie silence with subtle movements in the dark', 15.0, 0.3),
    ('bgm_chase_far.mp3', 'Slow steady heartbeat with distant footsteps approaching, low bass pulse, tension building gradually, someone following from far away', 15.0, 0.3),
    ('bgm_chase_mid.mp3', 'Fast heartbeat with closer heavy footsteps, breathing getting louder, urgent bass pulse, being chased through dark streets', 15.0, 0.3),
    ('bgm_chase_close.mp3', 'Rapid heartbeat with heavy ragged breathing very close, running footsteps right behind you, panic and terror, being hunted', 15.0, 0.3),
    ('bgm_chase_critical.mp3', 'Extreme panic sounds, distorted heartbeat, growling and metal scraping, heavy breathing on your neck, about to be caught by monster', 15.0, 0.3),

    # 마라토너 배경음
    ('bgm_running_ambient.mp3', 'Light footsteps on pavement with birds singing and gentle breeze, peaceful outdoor jogging white noise, calming exercise atmosphere', 15.0, 0.3),
]

def generate_bgm(filename, prompt, duration, influence):
    filepath = os.path.join(OUTDIR, filename)

    if os.path.exists(filepath):
        print(f'  SKIP (exists): {filename}')
        return True

    url = 'https://api.elevenlabs.io/v1/sound-generation'
    body = json.dumps({
        'text': prompt,
        'duration_seconds': duration,
        'prompt_influence': influence,
    }).encode('utf-8')

    req = urllib.request.Request(url, data=body, headers={
        'xi-api-key': API_KEY,
        'Content-Type': 'application/json; charset=utf-8',
    })

    try:
        with urllib.request.urlopen(req) as resp:
            data = resp.read()
            with open(filepath, 'wb') as f:
                f.write(data)
            size_kb = len(data) / 1024
            print(f'  OK: {filename} ({size_kb:.1f}KB)')
            return True
    except urllib.error.HTTPError as e:
        error_body = e.read().decode('utf-8')
        print(f'  FAIL: {filename} - {e.code} - {error_body[:200]}')
        return False

def main():
    total = len(BGM_LIST)
    success = 0
    fail = 0
    skip = 0

    print(f'총 {total}개 배경음 생성 시작\n')

    for i, (filename, prompt, duration, influence) in enumerate(BGM_LIST):
        print(f'[{i+1}/{total}] {filename}')
        filepath = os.path.join(OUTDIR, filename)

        if os.path.exists(filepath):
            skip += 1
            print(f'  SKIP (exists)')
            continue

        ok = generate_bgm(filename, prompt, duration, influence)
        if ok:
            success += 1
        else:
            fail += 1

        time.sleep(0.5)

    print(f'\n========================================')
    print(f'총: {total} | 성공: {success} | 실패: {fail} | 스킵: {skip}')
    print(f'========================================')

if __name__ == '__main__':
    main()
