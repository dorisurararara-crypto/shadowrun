import urllib.request, json, os

API_KEY = 'sk_00bc51e2397013aa4ff2a2c1e6389c01c31cb0ed94b3abed'
MODEL = 'eleven_v3'
OUTDIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'assets', 'audio', 'preview')

VOICES = {
    'harry': ('SOYHLrjzK2X1ezoPC6cr', 'Harry - Fierce Warrior'),
    'callum': ('N2lVS1w4EtoT3dr4eOWO', 'Callum - Calm Operator'),
    'drill': ('DGzg6RaUqxGRTHSBjfgF', 'Drill Sergeant - Commander'),
}

# 미리보기용 대사 3개 (안전/경고/위험)
PREVIEW_LINES = [
    ('preview_safe', '[calm] 좋은 페이스입니다. 계속 유지하세요.', 0.5, 0.8, 0.3),
    ('preview_warning', '[nervous] 뒤에서 뭔가 다가옵니다...', 0.3, 0.85, 0.6),
    ('preview_danger', '[urgent][nervous] 잡히기 직전입니다! 속도를 올리세요! [heavy breathing]', 0.2, 0.9, 0.8),
]

os.makedirs(OUTDIR, exist_ok=True)

for voice_key, (voice_id, voice_name) in VOICES.items():
    print(f'\n=== {voice_name} ({voice_key}) ===')
    for base_name, text, stability, similarity, style in PREVIEW_LINES:
        filename = f'{base_name}_{voice_key}.mp3'
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
                filepath = os.path.join(OUTDIR, filename)
                with open(filepath, 'wb') as f:
                    f.write(data)
                print(f'  {filename}: {len(data)} bytes OK')
        except urllib.error.HTTPError as e:
            error_body = e.read().decode('utf-8')
            print(f'  {filename}: FAIL {e.code} - {error_body}')

print('\n미리보기 생성 완료!')
print(f'파일 위치: {OUTDIR}')
