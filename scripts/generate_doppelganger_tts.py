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
    # 앞서감 압도적 (400m+) - 5 variants
    'tts_ahead_far_1': ('[calm] 좋아, 한참 앞서고 있어. 하지만 방심하지 마.', 0.5, 0.8, 0.3),
    'tts_ahead_far_2': ('[calm] 그림자가 저 뒤에서 널 지켜보고 있어.', 0.45, 0.8, 0.35),
    'tts_ahead_far_3': ('[calm] 이 페이스를 유지해. 아직 안전하지 않아.', 0.5, 0.8, 0.3),
    'tts_ahead_far_4': ('[calm] 잘 달리고 있어. 그런데... 그게 얼마나 갈까?', 0.45, 0.85, 0.4),
    'tts_ahead_far_5': ('[calm] 여유로워 보이지? 그림자도 쉬고 있는 건 아니야.', 0.5, 0.8, 0.35),

    # 앞서감 여유 (250~400m) - 5 variants
    'tts_ahead_mid_1': ('[calm] 나쁘지 않아. 거리를 벌리고 있어.', 0.45, 0.8, 0.35),
    'tts_ahead_mid_2': ('[nervous] 그림자가 속도를 올리기 시작했어.', 0.35, 0.85, 0.5),
    'tts_ahead_mid_3': ('[calm] 아직 안심하기 일러. 계속 달려.', 0.45, 0.8, 0.4),
    'tts_ahead_mid_4': ('[nervous] 200미터... 충분하다고 생각해? 난 아닌데.', 0.35, 0.85, 0.5),
    'tts_ahead_mid_5': ('[nervous] 뒤에서 뭔가 느껴지지 않아?', 0.3, 0.85, 0.55),

    # 앞서감 막 벗어남 (200~250m) - 5 variants
    'tts_ahead_close_1': ('[nervous] 겨우 벗어났어. 긴장 풀지 마.', 0.35, 0.85, 0.5),
    'tts_ahead_close_2': ('[nervous] 그림자와의 거리가 아슬아슬해.', 0.3, 0.85, 0.55),
    'tts_ahead_close_3': ('[urgent] 지금 속도 떨어뜨리면 다시 쫓긴다.', 0.25, 0.85, 0.6),
    'tts_ahead_close_4': ('[nervous] 안전권에 들어왔어. 하지만 얼마나 갈까.', 0.35, 0.85, 0.5),
    'tts_ahead_close_5': ('[nervous] 조금만 더 밀어붙여. 완전히 떼어놓자.', 0.3, 0.85, 0.55),

    # 안전 (150~200m) - 5 variants
    'tts_safe_1': ('[calm] 안전권이야. 지금은.', 0.5, 0.8, 0.3),
    'tts_safe_2': ('[nervous] 뒤를 돌아보지 마. 느껴지잖아.', 0.3, 0.85, 0.55),
    'tts_safe_3': ('[whispers] 조용하지? 그게 더 무서운 거야.', 0.2, 0.85, 0.7),
    'tts_safe_4': ('[whispers] 곧 심장 소리가 들릴 거야. 네 것인지... 그것의 것인지.', 0.15, 0.9, 0.75),
    'tts_safe_5': ('[nervous] 그림자가 움직이기 시작했어.', 0.3, 0.85, 0.55),

    # 추격 중 (100~150m) - 5 variants
    'tts_warning_1': ('[nervous] 가까워지고 있어. 느껴져?', 0.3, 0.85, 0.6),
    'tts_warning_2': ('[nervous] 100미터 안쪽이야. 속도를 올려.', 0.25, 0.85, 0.65),
    'tts_warning_3': ('[nervous] 심장 소리가 커지고 있어.', 0.3, 0.85, 0.6),
    'tts_warning_4': ('[nervous] 뒤에서 발소리가 들려.', 0.25, 0.85, 0.65),
    'tts_warning_5': ('[nervous] 아직 시간이 있어. 더 빨리 뛰면.', 0.3, 0.85, 0.55),

    # 추격 근접 (50~100m) - 5 variants
    'tts_warning_close_1': ('[urgent] 50미터. 숨소리가 들려.', 0.2, 0.9, 0.75),
    'tts_warning_close_2': ('[urgent] 더 빨리! 지금 아니면 끝이야.', 0.15, 0.9, 0.8),
    'tts_warning_close_3': ('[urgent] 그림자가 널 거의 따라잡았어.', 0.2, 0.9, 0.75),
    'tts_warning_close_4': ('[urgent] 도망쳐. 지금 당장.', 0.15, 0.9, 0.8),
    'tts_warning_close_5': ('[urgent] 이대로면 잡혀. 전력질주해!', 0.15, 0.9, 0.85),

    # 바로 뒤 (20~50m) - 5 variants
    'tts_danger_1': ('[whispers][heavy breathing] 바로 뒤에 있어...', 0.1, 0.9, 0.9),
    'tts_danger_2': ('[whispers][heavy breathing] 손이 닿을 거리야.', 0.1, 0.9, 0.9),
    'tts_danger_3': ('[urgent][heavy breathing] 이 속도로는 안 돼. 전력질주해.', 0.15, 0.9, 0.85),
    'tts_danger_4': ('[whispers][heavy breathing] 숨소리가 목 뒤에서 느껴져.', 0.1, 0.9, 0.9),
    'tts_danger_5': ('[urgent][heavy breathing] 마지막 기회야.', 0.15, 0.9, 0.85),

    # 코앞 (0~20m) - 5 variants
    'tts_critical_1': ('[screaming] 잡힌다...', 0.1, 0.95, 1.0),
    'tts_critical_2': ('[screaming] 안 돼... 더 빨리...', 0.1, 0.95, 1.0),
    'tts_critical_3': ('[screaming] 그림자가 손을 뻗고 있어.', 0.1, 0.95, 1.0),
    'tts_critical_4': ('[screaming] 끝이야... 아니, 아직이야! 뛰어!', 0.1, 0.95, 1.0),
    'tts_critical_5': ('[screaming] 지금 아니면 끝이다!', 0.1, 0.95, 1.0),

    # 리드 잃을 때 - 5 variants
    'tts_losing_lead_1': ('[urgent] 리드를 잃고 있어!', 0.2, 0.9, 0.75),
    'tts_losing_lead_2': ('[urgent] 속도가 떨어지고 있어. 그림자가 다가온다.', 0.2, 0.9, 0.75),
    'tts_losing_lead_3': ('[nervous] 아까 그 페이스는 어디 갔어?', 0.25, 0.85, 0.65),
    'tts_losing_lead_4': ('[nervous] 줄어들고 있어. 간격이.', 0.25, 0.85, 0.65),
    'tts_losing_lead_5': ('[urgent] 위험해. 다시 속도 올려.', 0.2, 0.9, 0.75),
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

print('\n도플갱어 TTS 생성 완료!')
