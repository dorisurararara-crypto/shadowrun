import urllib.request, json, os

API_KEY = 'sk_00bc51e2397013aa4ff2a2c1e6389c01c31cb0ed94b3abed'
VOICE = 'nPczCjzI2devNBz1zQrb'  # Brian - Deep, Resonant
MODEL = 'eleven_multilingual_v2'
OUTDIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'assets', 'audio')

tts_list = [
    ('tts_safe.mp3', '좋은 페이스입니다. 계속 유지하세요.', 0.4, 0.8),
    ('tts_warning.mp3', '뒤에서 뭔가 다가옵니다.', 0.3, 0.9),
    ('tts_warning2.mp3', '그림자가 가까워지고 있습니다. 긴장하세요.', 0.3, 0.9),
    ('tts_danger.mp3', '잡히기 직전입니다! 속도를 올리세요!', 0.2, 0.95),
    ('tts_danger2.mp3', '바로 뒤에 있습니다! 지금 당장 뛰세요!', 0.2, 0.95),
    ('tts_critical.mp3', '잡혔습니다.', 0.15, 1.0),
    ('tts_start.mp3', '러닝을 시작합니다. 그림자가 깨어났습니다.', 0.35, 0.85),
    ('tts_survived.mp3', '생존했습니다. 오늘은 당신이 이겼습니다.', 0.4, 0.8),
]

for filename, text, stability, similarity in tts_list:
    url = f'https://api.elevenlabs.io/v1/text-to-speech/{VOICE}'
    body = json.dumps({
        'text': text,
        'model_id': MODEL,
        'voice_settings': {'stability': stability, 'similarity_boost': similarity}
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
    except Exception as e:
        print(f'{filename}: FAIL - {e}')
