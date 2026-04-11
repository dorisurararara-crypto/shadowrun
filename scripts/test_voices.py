import urllib.request, json, os

API_KEY = 'sk_00bc51e2397013aa4ff2a2c1e6389c01c31cb0ed94b3abed'
MODEL = 'eleven_v3'
OUTDIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'assets', 'audio', 'test')
os.makedirs(OUTDIR, exist_ok=True)

# 같은 대사로 4가지 음성 비교
TEXT = '[nervous][urgent][whispers] 뒤에서... 뭔가 다가오고 있어... [louder] 지금 당장 뛰세요!'

voices = [
    ('SOYHLrjzK2X1ezoPC6cr', 'harry_fierce_warrior'),      # Harry - Fierce Warrior
    ('pNInz6obpgDQGcFmaJgB', 'adam_dominant'),              # Adam - Dominant, Firm
    ('N2lVS1w4EtoT3dr4eOWO', 'callum_husky'),              # Callum - Husky Trickster
    ('DGzg6RaUqxGRTHSBjfgF', 'drill_sergeant'),            # Drill Sergeant
]

for voice_id, name in voices:
    url = f'https://api.elevenlabs.io/v1/text-to-speech/{voice_id}'
    body = json.dumps({
        'text': TEXT,
        'model_id': MODEL,
        'voice_settings': {
            'stability': 0.15,
            'similarity_boost': 0.9,
            'style': 0.8,
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
            filepath = os.path.join(OUTDIR, f'{name}.mp3')
            with open(filepath, 'wb') as f:
                f.write(data)
            print(f'{name}: {len(data)} bytes OK')
    except urllib.error.HTTPError as e:
        error_body = e.read().decode('utf-8')
        print(f'{name}: FAIL {e.code} - {error_body[:200]}')
