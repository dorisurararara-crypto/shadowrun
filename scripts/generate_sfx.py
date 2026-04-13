"""ElevenLabs Sound Effects API로 앱 효과음 31개 생성"""
import urllib.request, json, os, time

API_KEY = 'sk_00bc51e2397013aa4ff2a2c1e6389c01c31cb0ed94b3abed'
OUTDIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'assets', 'audio', 'sfx')
os.makedirs(OUTDIR, exist_ok=True)

# (파일명, 프롬프트, 길이초, prompt_influence)
SFX_LIST = [
    # === 1. 앱 진입 ===
    ('sfx_splash.mp3',
     'Dark cinematic drone bass rumble, low frequency vibration slowly building then fading, horror movie atmosphere, very short',
     2.5, 0.3),

    ('sfx_heartbeat_single.mp3',
     'Single deep heartbeat thump, low bass thud like a heart beating once, organic and heavy, isolated',
     1.0, 0.5),

    # === 2. 홈 화면 ===
    ('sfx_tap_newrun.mp3',
     'Short mechanical click, metal latch unlocking, clean and precise, futuristic UI button press',
     0.5, 0.5),

    ('sfx_tap_challenge.mp3',
     'Single deep taiko drum hit, powerful Japanese war drum strike, boomy and resonant, intimidating',
     1.5, 0.5),

    ('sfx_tap_card.mp3',
     'Soft subtle click, gentle paper touch, minimal UI interaction sound, light and clean',
     0.5, 0.5),

    # === 3. 준비 화면 ===
    ('sfx_gps_ready.mp3',
     'Short electronic beep confirmation sound, digital device ready notification, clean high-pitched ping, tech gadget',
     0.5, 0.5),

    ('sfx_toggle.mp3',
     'Crisp toggle switch click, mechanical button press, short and satisfying snap sound',
     0.5, 0.5),

    ('sfx_countdown.mp3',
     'Three slow heavy heartbeats getting louder and faster, tension building, like heart pounding before a race start, dramatic',
     3.0, 0.4),

    ('sfx_go.mp3',
     'Race start air horn blast, loud and powerful starting signal, explosive energy burst, athletic competition horn',
     1.5, 0.5),

    # === 4. 도플갱어 — 러닝 중 ===
    ('sfx_alert_low.mp3',
     'Low rumbling alert sound, deep warning tone, submarine sonar ping, ominous and foreboding, something approaching',
     1.5, 0.4),

    ('sfx_alert_high.mp3',
     'Urgent high-pitched alarm, danger siren short burst, heart rate monitor speeding up, panic inducing alert',
     1.5, 0.4),

    ('sfx_chain_break.mp3',
     'Metal chain snapping and breaking apart, iron links shattering, liberation sound, breaking free from restraints',
     1.0, 0.5),

    ('sfx_whoosh.mp3',
     'Fast wind whoosh swooping past, speed movement air rush, runner sprinting past you, dynamic and powerful',
     1.0, 0.5),

    ('sfx_fanfare.mp3',
     'Short triumphant victory fanfare, brass instruments celebration, heroic achievement unlocked, 2 seconds only',
     2.0, 0.5),

    ('sfx_glass_break.mp3',
     'Glass shattering and cracking, mirror breaking into pieces, sudden and startling, hope shattering moment',
     1.0, 0.5),

    ('sfx_km_ding.mp3',
     'Clean bright notification ding, crystal bell chime, milestone reached alert, pleasant and clear single tone',
     0.5, 0.5),

    # === 5. 마라토너 — 러닝 중 ===
    ('sfx_whistle.mp3',
     'Coach whistle blow, sports referee whistle short sharp blast, athletic training signal, commanding',
     1.0, 0.5),

    ('sfx_powerup.mp3',
     'Video game power up sound effect, energy boost activation, ascending electronic tones, speed increase',
     1.0, 0.5),

    ('sfx_tension.mp3',
     'Low tension drum roll, snare drum building suspense, getting slower and heavier, warning that pace is dropping',
     2.0, 0.4),

    # === 6. 공통 — 러닝 중 ===
    ('sfx_pause.mp3',
     'Tape deck stopping abruptly, vinyl record scratch stop, music freezing suddenly, time stopping effect',
     0.5, 0.5),

    ('sfx_resume.mp3',
     'Tape deck starting to play again, motor spinning up, rewinding then playing, resuming from pause',
     0.5, 0.5),

    ('sfx_vehicle_warn.mp3',
     'Two short warning beeps, car proximity sensor alert, digital warning double beep, caution signal',
     1.0, 0.5),

    # === 7. 러닝 종료 ===
    ('sfx_door_close.mp3',
     'Heavy metal door slamming shut, vault door closing with deep thud, final and definitive, chapter ending',
     1.0, 0.5),

    ('sfx_victory.mp3',
     'Stadium crowd cheering with short victory music, celebration moment, triumphant brass and applause, epic win',
     3.0, 0.4),

    ('sfx_defeat.mp3',
     'Single deep church bell toll, somber and heavy, echoing into silence, game over funeral bell, melancholic',
     2.0, 0.4),

    # === 8. 결과 화면 ===
    ('sfx_report_open.mp3',
     'Wax seal breaking and envelope opening, parchment unfolding, secret document reveal, mysterious unveiling',
     1.0, 0.5),

    ('sfx_counter.mp3',
     'Fast digital counter ticking up rapidly, slot machine number counting, data processing clicks, score tallying',
     2.0, 0.5),

    ('sfx_share.mp3',
     'Camera shutter click, DSLR photo capture, single crisp snap, screenshot taken sound',
     0.5, 0.5),

    # === 9. 설정 ===
    ('sfx_switch_on.mp3',
     'Light switch flipping on with electrical hum, toggle activated, power on click, clean mechanical',
     0.5, 0.5),

    ('sfx_switch_off.mp3',
     'Light switch flipping off, toggle deactivated, power down click, slightly lower tone than on',
     0.5, 0.5),

    ('sfx_levelup.mp3',
     'RPG level up sound effect, magical ascending chimes, achievement unlocked jingle, sparkling upgrade complete',
     1.5, 0.5),
]

def generate_sfx(filename, prompt, duration, influence):
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
    total = len(SFX_LIST)
    success = 0
    fail = 0
    skip = 0

    print(f'총 {total}개 효과음 생성 시작\n')

    for i, (filename, prompt, duration, influence) in enumerate(SFX_LIST):
        print(f'[{i+1}/{total}] {filename}')
        filepath = os.path.join(OUTDIR, filename)

        if os.path.exists(filepath):
            skip += 1
            print(f'  SKIP (exists)')
            continue

        ok = generate_sfx(filename, prompt, duration, influence)
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
