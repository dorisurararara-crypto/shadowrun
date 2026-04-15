import urllib.request, json, os, time

API_KEY = os.environ.get('ELEVENLABS_API_KEY', '')
MODEL = 'eleven_v3'
OUTDIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'assets', 'audio')

VOICES = {
    'harry': 'SOYHLrjzK2X1ezoPC6cr',
    'callum': 'N2lVS1w4EtoT3dr4eOWO',
    'drill': 'DGzg6RaUqxGRTHSBjfgF',
}

LINES = {
    # 초반 격려 (0~5분) - 5 variants
    'tts_marathon_early_1': ('[calm] 좋아, 몸이 풀리기 시작할 거야.', 0.5, 0.8, 0.3),
    'tts_marathon_early_2': ('[calm] 처음 5분이 제일 힘들어. 버텨.', 0.45, 0.8, 0.35),
    'tts_marathon_early_3': ('[calm] 리듬을 찾아봐. 호흡에 맞춰서.', 0.5, 0.8, 0.3),
    'tts_marathon_early_4': ('[calm] 천천히 시작하는 게 맞아.', 0.5, 0.8, 0.3),
    'tts_marathon_early_5': ('[calm] 워밍업이라고 생각해.', 0.5, 0.8, 0.3),

    # 중반 격려 (5~15분) - 7 variants
    'tts_marathon_mid_1': ('[calm] 좋아, 리듬을 찾았어.', 0.5, 0.8, 0.3),
    'tts_marathon_mid_2': ('[calm] 이 고비만 넘기면 몸이 가벼워질 거야.', 0.45, 0.8, 0.35),
    'tts_marathon_mid_3': ('[calm] 호흡에 집중해. 들이쉬고... 내쉬고.', 0.5, 0.8, 0.3),
    'tts_marathon_mid_4': ('[calm] 지금 네가 달리는 이유를 떠올려봐.', 0.5, 0.8, 0.35),
    'tts_marathon_mid_5': ('[calm] 어깨 힘 빼. 팔은 자연스럽게.', 0.5, 0.8, 0.3),
    'tts_marathon_mid_6': ('[calm] 발 착지를 가볍게. 발바닥 중간으로.', 0.5, 0.8, 0.3),
    'tts_marathon_mid_7': ('[calm] 잘하고 있어. 진짜로.', 0.5, 0.8, 0.3),

    # 후반 격려 (15분+) - 7 variants
    'tts_marathon_late_1': ('[calm] 포기하고 싶을 때가 진짜 시작이야.', 0.45, 0.8, 0.4),
    'tts_marathon_late_2': ('[calm] 한 발짝만 더. 그것만 생각해.', 0.5, 0.8, 0.35),
    'tts_marathon_late_3': ('[calm] 넌 생각보다 강해.', 0.5, 0.8, 0.3),
    'tts_marathon_late_4': ('[calm] 여기까지 왔잖아. 멈추기엔 아까워.', 0.45, 0.8, 0.35),
    'tts_marathon_late_5': ('[calm] 고통은 일시적이야. 자부심은 영원하고.', 0.45, 0.8, 0.4),
    'tts_marathon_late_6': ('[calm] 지금이 가장 힘든 구간이야. 여기만 넘기면 돼.', 0.45, 0.8, 0.35),
    'tts_marathon_late_7': ('[calm] 마지막 힘을 짜내봐.', 0.45, 0.8, 0.4),

    # 러닝 팁 - 8 variants
    'tts_marathon_tip_1': ('[calm] 시선은 전방 30미터. 고개 숙이지 마.', 0.5, 0.8, 0.3),
    'tts_marathon_tip_2': ('[calm] 발이 땅에 머무는 시간을 줄여봐.', 0.5, 0.8, 0.3),
    'tts_marathon_tip_3': ('[calm] 팔꿈치 90도. 앞뒤로만 흔들어.', 0.5, 0.8, 0.3),
    'tts_marathon_tip_4': ('[calm] 배에 살짝 힘 주고 달려봐. 자세가 좋아져.', 0.5, 0.8, 0.3),
    'tts_marathon_tip_5': ('[calm] 코로 들이쉬고 입으로 내쉬어.', 0.5, 0.8, 0.3),
    'tts_marathon_tip_6': ('[calm] 보폭을 줄이고 회전수를 높여봐.', 0.5, 0.8, 0.3),
    'tts_marathon_tip_7': ('[calm] 물 마실 타이밍이야. 갈증 느끼기 전에.', 0.5, 0.8, 0.3),
    'tts_marathon_tip_8': ('[calm] 내리막에선 속도 내지 말고 보폭 줄여.', 0.5, 0.8, 0.3),

    # 페이스 피드백 - fast 4 + slow 4
    'tts_pace_fast_new_1': ('[calm] 오, 속도 올렸네? 좋아!', 0.5, 0.8, 0.35),
    'tts_pace_fast_new_2': ('[calm] 페이스업! 이 리듬 유지해봐.', 0.5, 0.8, 0.35),
    'tts_pace_fast_new_3': ('[calm] 기록 갱신 페이스야. 유지할 수 있어?', 0.45, 0.8, 0.4),
    'tts_pace_fast_new_4': ('[calm] 빨라지고 있어. 몸이 따라주는 거야.', 0.5, 0.8, 0.35),

    'tts_pace_slow_new_1': ('[calm] 속도가 좀 떨어졌어. 괜찮아, 다시 올려.', 0.5, 0.8, 0.3),
    'tts_pace_slow_new_2': ('[calm] 조금만 더 힘내. 페이스를 되찾자.', 0.5, 0.8, 0.3),
    'tts_pace_slow_new_3': ('[calm] 느려져도 괜찮아. 멈추지만 않으면 돼.', 0.5, 0.8, 0.3),
    'tts_pace_slow_new_4': ('[calm] 쉬엄쉬엄 가도 돼. 완주가 목표야.', 0.5, 0.8, 0.3),
}

os.makedirs(OUTDIR, exist_ok=True)

def generate(voice_key, voice_id):
    print(f'\n=== {voice_key} ({voice_id}) ===')
    for base_name, (text, stability, similarity, style) in LINES.items():
        if voice_key == 'harry':
            filename = f'{base_name}.mp3'
        else:
            filename = f'{base_name}_{voice_key}.mp3'

        filepath = os.path.join(OUTDIR, filename)

        if os.path.exists(filepath):
            print(f'  SKIP (exists): {filename}')
            continue

        url = f'https://api.elevenlabs.io/v1/text-to-speech/{voice_id}'
        body = json.dumps({
            'text': text,
            'model_id': MODEL,
            'voice_settings': {
                'stability': stability,
                'similarity_boost': similarity,
                'style': style,
                'use_speaker_boost': True,
            }
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
                print(f'  OK: {filename} ({len(data)} bytes)')
        except urllib.error.HTTPError as e:
            error_body = e.read().decode('utf-8')
            print(f'  FAIL: {filename} - {e.code} - {error_body[:200]}')

        time.sleep(0.3)

for key, vid in VOICES.items():
    generate(key, vid)

print('\n마라토너 TTS v2 생성 완료!')
