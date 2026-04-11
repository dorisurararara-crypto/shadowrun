import urllib.request, json, os

API_KEY = 'sk_00bc51e2397013aa4ff2a2c1e6389c01c31cb0ed94b3abed'
VOICE_HARRY = 'SOYHLrjzK2X1ezoPC6cr'  # Harry - Fierce Warrior
MODEL = 'eleven_v3'
OUTDIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'assets', 'audio')

# Harry 음성으로 전체 대사 생성 (v3 + Audio Tags)
lines = {
    # 한국어 8개
    'tts_safe.mp3': ('[calm] 좋은 페이스입니다. 계속 유지하세요.', 0.5, 0.8, 0.3),
    'tts_warning.mp3': ('[nervous] 뒤에서 뭔가 다가옵니다...', 0.3, 0.85, 0.6),
    'tts_warning2.mp3': ('[urgent] 발소리가 들립니다. 속도를 올리세요.', 0.25, 0.85, 0.7),
    'tts_danger.mp3': ('[urgent][nervous] 잡히기 직전입니다! 속도를 올리세요! [heavy breathing]', 0.2, 0.9, 0.8),
    'tts_danger2.mp3': ('[whispers] 느껴지나요... 바로 뒤에 있습니다... [heavy breathing]', 0.15, 0.9, 0.9),
    'tts_critical.mp3': ('[screaming] 잡혔습니다!!!', 0.1, 0.95, 1.0),
    'tts_start.mp3': ('[calm] 러닝을 시작합니다. 그림자가 깨어납니다.', 0.5, 0.8, 0.4),
    'tts_survived.mp3': ('[relieved] 생존했습니다. 오늘은 당신이 이겼습니다.', 0.5, 0.8, 0.3),

    # 영어 4개
    'tts_safe_en.mp3': ('[calm] Good pace. Keep it steady.', 0.5, 0.8, 0.3),
    'tts_warning_en.mp3': ('[nervous] Something is approaching from behind...', 0.3, 0.85, 0.6),
    'tts_danger_en.mp3': ('[urgent] Almost caught! Pick up the pace! [heavy breathing]', 0.2, 0.9, 0.8),
    'tts_critical_en.mp3': ('[screaming] You\'ve been caught!!!', 0.1, 0.95, 1.0),
}

os.makedirs(OUTDIR, exist_ok=True)

for filename, (text, stability, similarity, style) in lines.items():
    url = f'https://api.elevenlabs.io/v1/text-to-speech/{VOICE_HARRY}'
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
            filepath = os.path.join(OUTDIR, filename)
            with open(filepath, 'wb') as f:
                f.write(data)
            print(f'{filename}: {len(data)} bytes OK')
    except urllib.error.HTTPError as e:
        error_body = e.read().decode('utf-8')
        print(f'{filename}: FAIL {e.code} - {error_body}')
