"""마라토너 모드 추가 TTS 생성 — 시간 기반 격려 + 명언 + 조언"""
import urllib.request, json, os, time

API_KEY = 'sk_00bc51e2397013aa4ff2a2c1e6389c01c31cb0ed94b3abed'
MODEL = 'eleven_v3'
OUTDIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'assets', 'audio')

VOICES = {
    'harry': 'SOYHLrjzK2X1ezoPC6cr',
    'callum': 'N2lVS1w4EtoT3dr4eOWO',
    'drill': 'DGzg6RaUqxGRTHSBjfgF',
}

VS = {'stability': 0.7, 'similarity_boost': 0.8, 'style': 0.4, 'speed': 0.9}

# ==========================================
# 시간 기반 격려 (5분, 10분, 15분, 20분, 30분, 40분, 50분, 60분)
# ==========================================
TIME_LINES = {
    # 5분
    'tts_time_5min_1': ('[commanding] 5분. 몸이 달궈지기 시작했어. 이제부터야.', 'ko'),
    'tts_time_5min_2': ('[calm] 5분 지났어. 워밍업 끝. 본격적으로 가자.', 'ko'),
    'tts_time_5min_en_1': ('[commanding] 5 minutes. Your body is warming up. It starts now.', 'en'),
    'tts_time_5min_en_2': ('[calm] 5 minutes in. Warmup done. Let\'s go for real.', 'en'),
    # 10분
    'tts_time_10min_1': ('[warm] 10분. 잘하고 있어. 리듬을 유지해.', 'ko'),
    'tts_time_10min_2': ('[stern] 10분 경과. 지금 페이스가 네 진짜 페이스야. 기억해.', 'ko'),
    'tts_time_10min_en_1': ('[warm] 10 minutes. Doing great. Keep the rhythm.', 'en'),
    'tts_time_10min_en_2': ('[stern] 10 minutes in. This pace is your true pace. Remember it.', 'en'),
    # 15분
    'tts_time_15min_1': ('[commanding] 15분. 대부분 여기서 포기해. 넌 아니지?', 'ko'),
    'tts_time_15min_2': ('[calm] 15분. 호흡 체크. 깊게 들이쉬고 천천히 내쉬어.', 'ko'),
    'tts_time_15min_en_1': ('[commanding] 15 minutes. Most people quit here. Not you.', 'en'),
    'tts_time_15min_en_2': ('[calm] 15 minutes. Check your breathing. Deep in, slow out.', 'en'),
    # 20분
    'tts_time_20min_1': ('[warm] 20분 돌파. 여기까지 온 건 의지야. 멈추지 마.', 'ko'),
    'tts_time_20min_2': ('[stern] 20분. 러너스 하이가 올 시간이야. 느껴봐.', 'ko'),
    'tts_time_20min_en_1': ('[warm] 20 minutes. Getting here is willpower. Don\'t stop.', 'en'),
    'tts_time_20min_en_2': ('[stern] 20 minutes. Runner\'s high is coming. Feel it.', 'en'),
    # 30분
    'tts_time_30min_1': ('[excited] 30분! 반시간이야. 너 지금 대단한 거 하고 있어.', 'ko'),
    'tts_time_30min_2': ('[commanding] 30분. 수분 보충 잊지 마. 마시면서 뛰어도 돼.', 'ko'),
    'tts_time_30min_en_1': ('[excited] 30 minutes! Half an hour. You\'re doing something amazing.', 'en'),
    'tts_time_30min_en_2': ('[commanding] 30 minutes. Don\'t forget to hydrate. Drink while running.', 'en'),
    # 40분
    'tts_time_40min_1': ('[warm] 40분. 네 몸은 이미 러너의 몸이야.', 'ko'),
    'tts_time_40min_en_1': ('[warm] 40 minutes. Your body is already a runner\'s body.', 'en'),
    # 50분
    'tts_time_50min_1': ('[commanding] 50분. 거의 한 시간이야. 전설이 되고 있어.', 'ko'),
    'tts_time_50min_en_1': ('[commanding] 50 minutes. Almost an hour. You\'re becoming a legend.', 'en'),
    # 60분
    'tts_time_60min_1': ('[excited] 1시간! 믿을 수 없어. 네가 해냈어. 계속 갈 수 있어.', 'ko'),
    'tts_time_60min_en_1': ('[excited] One hour! Unbelievable. You did it. You can keep going.', 'en'),
}

# ==========================================
# 랜덤 러닝 명언/격언 (3~5분 간격으로 랜덤 재생)
# ==========================================
QUOTES = {
    'tts_quote_1': ('[calm] 달리기는 나 자신과의 대화야. 오늘 나는 뭘 말하고 있지?', 'ko'),
    'tts_quote_2': ('[stern] 고통은 일시적이야. 포기는 영원해.', 'ko'),
    'tts_quote_3': ('[warm] 느리더라도 달리고 있으면 소파에 앉아있는 모든 사람보다 앞서가는 거야.', 'ko'),
    'tts_quote_4': ('[commanding] 몸이 멈추라고 할 때, 정신이 계속 가라고 말해. 정신의 말을 들어.', 'ko'),
    'tts_quote_5': ('[calm] 마라톤은 20마일의 준비와 6마일의 진실이야.', 'ko'),
    'tts_quote_6': ('[warm] 오늘 뛰기 싫었지? 그래도 나왔잖아. 그게 진짜 실력이야.', 'ko'),
    'tts_quote_7': ('[stern] 편안한 곳에서는 아무것도 자라지 않아.', 'ko'),
    'tts_quote_8': ('[commanding] 1킬로미터는 1킬로미터야. 빠르든 느리든 똑같은 거리야.', 'ko'),
    'tts_quote_9': ('[calm] 달리기의 기적은 시작하는 용기에 있어.', 'ko'),
    'tts_quote_10': ('[warm] 오늘의 고통이 내일의 힘이 된다. 믿어.', 'ko'),
    'tts_quote_11': ('[stern] 레이스는 다른 사람과 하는 게 아니야. 어제의 나와 하는 거야.', 'ko'),
    'tts_quote_12': ('[commanding] 멈추고 싶을 때가 시작할 때야.', 'ko'),
    'tts_quote_en_1': ('[calm] Running is a conversation with yourself. What are you saying today?', 'en'),
    'tts_quote_en_2': ('[stern] Pain is temporary. Quitting is forever.', 'en'),
    'tts_quote_en_3': ('[warm] No matter how slow you go, you\'re still lapping everyone on the couch.', 'en'),
    'tts_quote_en_4': ('[commanding] When your body says stop, your mind says go. Listen to your mind.', 'en'),
    'tts_quote_en_5': ('[calm] A marathon is 20 miles of preparation and 6 miles of truth.', 'en'),
    'tts_quote_en_6': ('[warm] You didn\'t want to run today? But you showed up. That\'s real strength.', 'en'),
    'tts_quote_en_7': ('[stern] Nothing grows in the comfort zone.', 'en'),
    'tts_quote_en_8': ('[commanding] A kilometer is a kilometer. Fast or slow, same distance.', 'en'),
    'tts_quote_en_9': ('[calm] The miracle of running is the courage to start.', 'en'),
    'tts_quote_en_10': ('[warm] Today\'s pain is tomorrow\'s strength. Believe it.', 'en'),
    'tts_quote_en_11': ('[stern] The race isn\'t against others. It\'s against yesterday\'s you.', 'en'),
    'tts_quote_en_12': ('[commanding] When you want to stop, that\'s when it begins.', 'en'),
}

# ==========================================
# 추가 러닝 조언 (랜덤)
# ==========================================
TIPS = {
    'tts_tip_1': ('[calm] 어깨에 힘이 들어가 있지 않아? 한 번 흔들어서 풀어줘.', 'ko'),
    'tts_tip_2': ('[stern] 턱을 당겨. 고개를 들면 목에 긴장이 와.', 'ko'),
    'tts_tip_3': ('[commanding] 손을 살짝 쥐어. 주먹을 꽉 쥐면 에너지가 낭비돼.', 'ko'),
    'tts_tip_4': ('[warm] 발소리가 크면 착지가 세다는 뜻이야. 가볍게 착지해봐.', 'ko'),
    'tts_tip_5': ('[calm] 팔은 앞뒤로만. 좌우로 흔들면 에너지가 새어나가.', 'ko'),
    'tts_tip_6': ('[stern] 코로 들이쉬고 입으로 내쉬어. 2:2 리듬으로.', 'ko'),
    'tts_tip_7': ('[warm] 내리막에서 브레이크 걸지 마. 중력을 이용해서 편하게 가.', 'ko'),
    'tts_tip_8': ('[commanding] 오르막에서는 보폭을 줄이고 팔을 더 써.', 'ko'),
    'tts_tip_en_1': ('[calm] Are your shoulders tense? Shake them loose.', 'en'),
    'tts_tip_en_2': ('[stern] Tuck your chin. Lifting your head creates neck tension.', 'en'),
    'tts_tip_en_3': ('[commanding] Keep your fists loose. Clenching wastes energy.', 'en'),
    'tts_tip_en_4': ('[warm] Loud footsteps mean heavy landing. Try landing lighter.', 'en'),
    'tts_tip_en_5': ('[calm] Arms forward and back only. Side swinging wastes energy.', 'en'),
    'tts_tip_en_6': ('[stern] Breathe in through nose, out through mouth. 2:2 rhythm.', 'en'),
    'tts_tip_en_7': ('[warm] Don\'t brake on downhills. Use gravity to glide.', 'en'),
    'tts_tip_en_8': ('[commanding] On uphills, shorten your stride and pump your arms more.', 'en'),
}

ALL_LINES = {}
ALL_LINES.update(TIME_LINES)
ALL_LINES.update(QUOTES)
ALL_LINES.update(TIPS)

os.makedirs(OUTDIR, exist_ok=True)

def generate(base_name, text, lang, voice_key, voice_id):
    if voice_key == 'harry':
        filename = f'{base_name}.mp3'
    else:
        filename = f'{base_name}_{voice_key}.mp3'

    filepath = os.path.join(OUTDIR, filename)
    if os.path.exists(filepath):
        print(f'  SKIP: {filename}')
        return

    url = f'https://api.elevenlabs.io/v1/text-to-speech/{voice_id}'
    body = json.dumps({
        'text': text,
        'model_id': MODEL,
        'language_code': lang,
        'voice_settings': VS,
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
            print(f'  OK: {filename} ({len(data)/1024:.1f}KB)')
    except urllib.error.HTTPError as e:
        print(f'  FAIL: {filename} - {e.code}')

    time.sleep(0.3)

def main():
    total = len(ALL_LINES) * 3
    done = 0
    print(f'총 {len(ALL_LINES)}개 대사 × 3음성 = {total}개 생성\n')

    for base_name, (text, lang) in ALL_LINES.items():
        for voice_key, voice_id in VOICES.items():
            done += 1
            print(f'[{done}/{total}] {base_name} ({voice_key})')
            generate(base_name, text, lang, voice_key, voice_id)

    print(f'\n완료!')

if __name__ == '__main__':
    main()
