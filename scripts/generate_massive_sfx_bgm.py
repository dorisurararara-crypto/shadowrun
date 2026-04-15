"""SFX 25개 + BGM 35개 = 60개 대량 생성"""
import urllib.request, json, os, time

API_KEY = 'sk_00bc51e2397013aa4ff2a2c1e6389c01c31cb0ed94b3abed'
SFX_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'assets', 'audio', 'sfx')
BGM_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'assets', 'audio')
os.makedirs(SFX_DIR, exist_ok=True)

# (파일명, 프롬프트, 길이초, prompt_influence, 출력디렉토리)
SOUNDS = [
    # ============ SFX 25개 ============

    # 승리 변형 4개
    ('sfx_victory_crowd.mp3', 'Massive stadium crowd cheering and roaring with clapping, triumphant sports celebration, thousands of people excited', 3.0, 0.4, SFX_DIR),
    ('sfx_victory_trumpet.mp3', 'Triumphant brass trumpet fanfare, royal victory announcement, short heroic melody, medieval tournament winner', 2.5, 0.5, SFX_DIR),
    ('sfx_victory_drums.mp3', 'Epic war drum celebration, powerful taiko drum sequence building to climax, victorious rhythm, tribal', 3.0, 0.4, SFX_DIR),
    ('sfx_victory_orchestra.mp3', 'Short orchestral victory sting, full orchestra hit with cymbal crash, movie trailer hero moment, epic and grand', 2.5, 0.5, SFX_DIR),

    # 패배 변형 4개
    ('sfx_defeat_heartfail.mp3', 'Heart monitor flatline beep, hospital ECG going flat, long continuous beep of death, clinical and cold', 3.0, 0.5, SFX_DIR),
    ('sfx_defeat_shatter.mp3', 'Massive glass shattering into million pieces, mirror world breaking apart, catastrophic destruction, slow motion', 2.0, 0.5, SFX_DIR),
    ('sfx_defeat_thunder.mp3', 'Deep ominous thunder rolling after lightning strike, dark sky rumbling, nature punishing, distant and heavy', 3.0, 0.4, SFX_DIR),
    ('sfx_defeat_grave.mp3', 'Heavy stone coffin lid sliding closed, deep stone grinding, tomb sealing shut forever, ancient and final', 2.5, 0.5, SFX_DIR),

    # 점프스케어 변형 3개
    ('sfx_jumpscare_scream.mp3', 'Horrifying inhuman scream shriek, demonic banshee wail, blood curdling horror movie jump scare, piercing', 1.5, 0.5, SFX_DIR),
    ('sfx_jumpscare_metal.mp3', 'Violent metal scraping on concrete, knife on chalkboard amplified, industrial horror grinding, unbearable', 1.5, 0.5, SFX_DIR),
    ('sfx_jumpscare_laugh.mp3', 'Creepy distorted demonic laughter, evil villain cackling in the dark, horror movie possessed child laugh', 2.0, 0.5, SFX_DIR),

    # 개인기록 달성 3개
    ('sfx_pr_epic.mp3', 'Epic achievement unlocked sound, ascending magical chimes with orchestral hit, video game legendary loot drop', 2.5, 0.5, SFX_DIR),
    ('sfx_pr_legend.mp3', 'Legendary achievement sound, heavenly choir sting with shimmering sparkles, divine power awakening, angelic', 3.0, 0.4, SFX_DIR),
    ('sfx_pr_god.mp3', 'Godlike achievement explosion, massive bass drop with rising synth, electronic power surge, dubstep style', 3.0, 0.4, SFX_DIR),

    # 연승 업적 3개
    ('sfx_streak_3.mp3', 'Short motivational guitar riff, upbeat rock power chord, 3 quick notes ascending, energetic', 1.5, 0.5, SFX_DIR),
    ('sfx_streak_7.mp3', 'Triumphant horn section playing ascending scale, brass ensemble celebration, building energy and pride', 2.0, 0.5, SFX_DIR),
    ('sfx_streak_30.mp3', 'Full orchestra and choir singing one powerful sustained note, massive cinematic swell, awe inspiring', 3.0, 0.4, SFX_DIR),

    # km 마일스톤 변형 3개
    ('sfx_km_bell.mp3', 'Single clear church bell ring, deep resonant bronze bell chime, milestone marker, solemn and powerful', 1.5, 0.5, SFX_DIR),
    ('sfx_km_chime.mp3', 'Bright crystal wind chime melody, three ascending notes, gentle achievement notification, magical', 1.0, 0.5, SFX_DIR),
    ('sfx_km_ting.mp3', 'Clean metallic ping notification, single crisp triangle hit, minimalist milestone sound, pure', 0.5, 0.5, SFX_DIR),

    # 카운트다운 변형 2개
    ('sfx_countdown_heartbeat.mp3', 'Three heavy heartbeats getting faster and louder then silence, tension building to explosion, dramatic', 3.5, 0.4, SFX_DIR),
    ('sfx_countdown_digital.mp3', 'Digital countdown beeps three two one with electronic buzzer at zero, sci-fi spaceship launch sequence', 3.5, 0.5, SFX_DIR),

    # 기타 3개
    ('sfx_camera.mp3', 'Professional DSLR camera shutter click, mechanical mirror slap, crisp photo capture sound', 0.5, 0.5, SFX_DIR),
    ('sfx_map_zoom.mp3', 'Smooth digital zoom whoosh, UI element expanding with soft pop, interface magnifying glass activate', 0.5, 0.5, SFX_DIR),
    ('sfx_footsteps_chase.mp3', 'Heavy running footsteps approaching rapidly from behind on asphalt, getting louder and faster, menacing', 3.0, 0.4, SFX_DIR),

    # ============ BGM 35개 ============

    # 도플갱어 레벨별 2번째 변형 8개
    ('bgm_peaceful_v2.mp3', 'Morning birds singing in park with distant joggers footsteps, gentle spring breeze through trees, peaceful outdoor exercise ambience', 15.0, 0.3, BGM_DIR),
    ('bgm_calm_wind_v2.mp3', 'Ocean waves distant with light wind, slightly melancholic ambient soundscape, calm but with underlying unease', 15.0, 0.3, BGM_DIR),
    ('bgm_tension_low_v2.mp3', 'Slow pulsing synthesizer with occasional distant wolf howl, night forest tension, something stalking in shadows', 15.0, 0.3, BGM_DIR),
    ('bgm_dark_ambient_v2.mp3', 'Underground tunnel dripping water with echoing footsteps, claustrophobic dark atmosphere, abandoned subway', 15.0, 0.3, BGM_DIR),
    ('bgm_chase_far_v2.mp3', 'Muffled heartbeat with distant heavy breathing and crackling twigs, someone following through woods at night', 15.0, 0.3, BGM_DIR),
    ('bgm_chase_mid_v2.mp3', 'Intense pulsing bass with rapid breathing and closer footsteps, adrenaline pumping chase music, electronic', 15.0, 0.3, BGM_DIR),
    ('bgm_chase_close_v2.mp3', 'Frantic heartbeat with wheezing breathing and stomping feet right behind, extreme panic and terror atmosphere', 15.0, 0.3, BGM_DIR),
    ('bgm_chase_critical_v2.mp3', 'Distorted screaming wind with grinding metal and demonic whispers, hellish nightmare chase, absolute horror', 15.0, 0.3, BGM_DIR),

    # 도플갱어 레벨별 3번째 변형 8개
    ('bgm_peaceful_v3.mp3', 'Crickets chirping at sunset with warm breeze, golden hour outdoor ambient, peaceful evening jog atmosphere', 15.0, 0.3, BGM_DIR),
    ('bgm_calm_wind_v3.mp3', 'Rain starting to fall gently on leaves, petrichor atmosphere, contemplative and slightly ominous weather change', 15.0, 0.3, BGM_DIR),
    ('bgm_tension_low_v3.mp3', 'Clock ticking slowly with deep reverb, time pressure building, suspenseful waiting room atmosphere, horror film', 15.0, 0.3, BGM_DIR),
    ('bgm_dark_ambient_v3.mp3', 'Creaking old house with wind whistling through cracks, haunted atmosphere, wooden floor groaning, ghost story', 15.0, 0.3, BGM_DIR),
    ('bgm_chase_far_v3.mp3', 'Slow industrial machinery rhythm with distant sirens, urban night chase beginning, factory district atmosphere', 15.0, 0.3, BGM_DIR),
    ('bgm_chase_mid_v3.mp3', 'War drums building intensity with tribal chanting, primal pursuit rhythm, hunter and prey, ancient ritual', 15.0, 0.3, BGM_DIR),
    ('bgm_chase_close_v3.mp3', 'Multiple overlapping heartbeats with chains dragging and heavy metal boots, relentless pursuer closing in', 15.0, 0.3, BGM_DIR),
    ('bgm_chase_critical_v3.mp3', 'Reversed audio glitches with bass drops and static electricity, digital nightmare, reality breaking apart', 15.0, 0.3, BGM_DIR),

    # 준비 화면 긴장감 3개
    ('bgm_prepare_tension1.mp3', 'Low rumbling drone building slowly, anticipation before battle, calm before the storm, cinematic suspense', 15.0, 0.3, BGM_DIR),
    ('bgm_prepare_tension2.mp3', 'Ticking clock with rising string tension, countdown to something big, thriller movie pre-action scene', 15.0, 0.3, BGM_DIR),
    ('bgm_prepare_tension3.mp3', 'Deep breathing in dark room with distant thunder approaching, preparing for confrontation, pre-fight nerves', 15.0, 0.3, BGM_DIR),

    # 결과 승리 3개
    ('bgm_result_victory1.mp3', 'Triumphant orchestral theme slowly fading, post-battle calm after victory, proud and relieved, sunset hero', 15.0, 0.3, BGM_DIR),
    ('bgm_result_victory2.mp3', 'Gentle piano melody with soft strings, accomplishment and reflection, looking back at the battle won', 15.0, 0.3, BGM_DIR),
    ('bgm_result_victory3.mp3', 'Ambient electronic with uplifting pads, digital achievement screen music, futuristic celebration, neon glow', 15.0, 0.3, BGM_DIR),

    # 결과 패배 3개
    ('bgm_result_defeat1.mp3', 'Somber cello solo with rain sounds, melancholic reflection after loss, dignified sadness, film noir', 15.0, 0.3, BGM_DIR),
    ('bgm_result_defeat2.mp3', 'Dark ambient drone with single piano notes fading, empty battlefield after defeat, lonely and cold', 15.0, 0.3, BGM_DIR),
    ('bgm_result_defeat3.mp3', 'Distant wind howling through ruins, abandoned hope, dark souls style post-defeat ambience, desolate', 15.0, 0.3, BGM_DIR),

    # 결과 일반 2개
    ('bgm_result_normal1.mp3', 'Calm lo-fi beats with vinyl crackle, chill study music vibes, relaxed post-run cooldown, warm', 15.0, 0.3, BGM_DIR),
    ('bgm_result_normal2.mp3', 'Gentle acoustic guitar strumming with nature sounds, peaceful completion, satisfied runner resting', 15.0, 0.3, BGM_DIR),

    # 마라토너 앰비언트 변형 4개
    ('bgm_running_ambient_v2.mp3', 'Urban city running ambience with distant traffic and birds, morning jog through city park, metropolitan', 15.0, 0.3, BGM_DIR),
    ('bgm_running_ambient_v3.mp3', 'Trail running through forest with crunching leaves and bird calls, nature trail jogging atmosphere, earthy', 15.0, 0.3, BGM_DIR),
    ('bgm_running_ambient_v4.mp3', 'Seaside running with ocean waves and seagulls, beach boardwalk jogging, fresh salt air atmosphere', 15.0, 0.3, BGM_DIR),
    ('bgm_running_ambient_v5.mp3', 'Night city running with distant neon hum and light rain, cyberpunk urban jog, futuristic lonely runner', 15.0, 0.3, BGM_DIR),

    # 프리런 앰비언트 변형 4개
    ('bgm_freerun_zen1.mp3', 'Zen garden water fountain with wind chimes, meditative running atmosphere, Japanese garden tranquility', 15.0, 0.3, BGM_DIR),
    ('bgm_freerun_zen2.mp3', 'Mountain stream flowing over rocks with distant eagle cry, high altitude trail running, alpine freedom', 15.0, 0.3, BGM_DIR),
    ('bgm_freerun_zen3.mp3', 'Early morning mist with songbirds waking up, dawn chorus, first light of day running, fresh and pure', 15.0, 0.3, BGM_DIR),
    ('bgm_freerun_zen4.mp3', 'Autumn leaves rustling in gentle wind with distant temple bell, fall season running, contemplative', 15.0, 0.3, BGM_DIR),
]

def generate(filename, prompt, duration, influence, outdir):
    filepath = os.path.join(outdir, filename)
    if os.path.exists(filepath):
        return 'skip'

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
        with urllib.request.urlopen(req, timeout=60) as resp:
            data = resp.read()
            with open(filepath, 'wb') as f:
                f.write(data)
            return f'ok ({len(data)//1024}KB)'
    except urllib.error.HTTPError as e:
        return f'fail ({e.code})'

total = len(SOUNDS)
ok = skip = fail = 0
print(f'총 {total}개 사운드 생성 시작\n')

for i, (fname, prompt, dur, inf, outdir) in enumerate(SOUNDS):
    result = generate(fname, prompt, dur, inf, outdir)
    status = result.split(' ')[0]
    if status == 'ok': ok += 1
    elif status == 'skip': skip += 1
    else: fail += 1
    print(f'[{i+1}/{total}] {fname}: {result}')
    if status == 'ok':
        time.sleep(0.5)

print(f'\n========================================')
print(f'성공: {ok} | 스킵: {skip} | 실패: {fail}')
print(f'========================================')
