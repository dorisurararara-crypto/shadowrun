import urllib.request, json, os

API_KEY = 'sk_00bc51e2397013aa4ff2a2c1e6389c01c31cb0ed94b3abed'
MODEL = 'eleven_v3'
OUTDIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'assets', 'audio')
os.makedirs(OUTDIR, exist_ok=True)

VOICES = {
    'harry': 'SOYHLrjzK2X1ezoPC6cr',
    'callum': 'N2lVS1w4EtoT3dr4eOWO',
    'drill': 'DGzg6RaUqxGRTHSBjfgF',
}

LINES = {
    # 한국어 8개
    'tts_safe': ('[calm] 좋은 페이스입니다. 계속 유지하세요.', 0.5, 0.8, 0.3),
    'tts_warning': ('[nervous] 뒤에서 뭔가 다가옵니다...', 0.3, 0.85, 0.6),
    'tts_warning2': ('[urgent] 발소리가 들립니다. 속도를 올리세요.', 0.25, 0.85, 0.7),
    'tts_danger': ('[urgent][nervous] 잡히기 직전입니다! 속도를 올리세요! [heavy breathing]', 0.2, 0.9, 0.8),
    'tts_danger2': ('[whispers] 느껴지나요... 바로 뒤에 있습니다... [heavy breathing]', 0.15, 0.9, 0.9),
    'tts_critical': ('[screaming] 잡혔습니다!!!', 0.1, 0.95, 1.0),
    'tts_start': ('[calm] 러닝을 시작합니다. 그림자가 깨어납니다.', 0.5, 0.8, 0.4),
    'tts_survived': ('[relieved] 생존했습니다. 오늘은 당신이 이겼습니다.', 0.5, 0.8, 0.3),
    # 영어 4개
    'tts_safe_en': ('[calm] Good pace. Keep it steady.', 0.5, 0.8, 0.3),
    'tts_warning_en': ('[nervous] Something is approaching from behind...', 0.3, 0.85, 0.6),
    'tts_danger_en': ('[urgent] Almost caught! Pick up the pace! [heavy breathing]', 0.2, 0.9, 0.8),
    'tts_critical_en': ("[screaming] You've been caught!!!", 0.1, 0.95, 1.0),
}

total = len(VOICES) * len(LINES)
done = 0

for voice_name, voice_id in VOICES.items():
    for base_name, (text, stability, similarity, style) in LINES.items():
        # harry는 기본 파일명, callum/drill은 접미사
        if voice_name == 'harry':
            filename = f'{base_name}.mp3'
        else:
            filename = f'{base_name}_{voice_name}.mp3'

        filepath = os.path.join(OUTDIR, filename)

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
                done += 1
                print(f'[{done}/{total}] {filename}: {len(data)} bytes OK')
        except urllib.error.HTTPError as e:
            error_body = e.read().decode('utf-8')
            done += 1
            print(f'[{done}/{total}] {filename}: FAIL {e.code} - {error_body[:100]}')

print(f'\n완료: {done}/{total}')
