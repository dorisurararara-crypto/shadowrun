"""영어 TTS 대량 생성 — 도플갱어 + 마라토너 새 대사 전체"""
import urllib.request, json, os, time

API_KEY = os.environ.get('ELEVENLABS_API_KEY', '')
MODEL = 'eleven_v3'
OUTDIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'assets', 'audio')

VOICES = {
    'harry': 'SOYHLrjzK2X1ezoPC6cr',
    'callum': 'N2lVS1w4EtoT3dr4eOWO',
    'drill': 'DGzg6RaUqxGRTHSBjfgF',
}

# (text, stability, similarity, style)
LINES = {
    # === 도플갱어 영어 ===
    # 앞서감 압도적 (400m+)
    'tts_ahead_far_en_1': ('[calm] Good. You are way ahead. But do not let your guard down.', 0.5, 0.8, 0.3),
    'tts_ahead_far_en_2': ('[calm] The shadow is watching you from behind.', 0.45, 0.8, 0.35),
    'tts_ahead_far_en_3': ('[calm] Keep this pace. You are not safe yet.', 0.5, 0.8, 0.3),
    'tts_ahead_far_en_4': ('[calm] Running well. But... how long can you keep it up?', 0.45, 0.85, 0.4),
    'tts_ahead_far_en_5': ('[calm] Feeling comfortable? The shadow is not resting either.', 0.5, 0.8, 0.35),

    # 앞서감 여유 (250~400m)
    'tts_ahead_mid_en_1': ('[calm] Not bad. You are pulling ahead.', 0.45, 0.8, 0.35),
    'tts_ahead_mid_en_2': ('[nervous] The shadow is picking up speed.', 0.35, 0.85, 0.5),
    'tts_ahead_mid_en_3': ('[calm] Do not relax yet. Keep running.', 0.45, 0.8, 0.4),
    'tts_ahead_mid_en_4': ('[nervous] Two hundred meters... think that is enough? I don\'t.', 0.35, 0.85, 0.5),
    'tts_ahead_mid_en_5': ('[nervous] Don\'t you feel something behind you?', 0.3, 0.85, 0.55),

    # 앞서감 막 벗어남 (200~250m)
    'tts_ahead_close_en_1': ('[nervous] Barely escaped. Stay focused.', 0.35, 0.85, 0.5),
    'tts_ahead_close_en_2': ('[nervous] The gap is dangerously thin.', 0.3, 0.85, 0.55),
    'tts_ahead_close_en_3': ('[urgent] Slow down now and it catches you again.', 0.25, 0.85, 0.6),
    'tts_ahead_close_en_4': ('[nervous] Safe zone. But for how long.', 0.35, 0.85, 0.5),
    'tts_ahead_close_en_5': ('[nervous] Push a little more. Break away completely.', 0.3, 0.85, 0.55),

    # 안전 (150~200m)
    'tts_safe_en_1': ('[calm] Safe zone. For now.', 0.5, 0.8, 0.3),
    'tts_safe_en_2': ('[nervous] Don\'t look back. You can feel it.', 0.3, 0.85, 0.55),
    'tts_safe_en_3': ('[whispers] Quiet, isn\'t it? That is what makes it scarier.', 0.2, 0.85, 0.7),
    'tts_safe_en_4': ('[whispers] Soon you will hear a heartbeat. Yours... or its.', 0.15, 0.9, 0.75),
    'tts_safe_en_5': ('[nervous] The shadow has started moving.', 0.3, 0.85, 0.55),

    # 추격 중 (100~150m)
    'tts_warning_en_1': ('[nervous] It is getting closer. Can you feel it?', 0.3, 0.85, 0.6),
    'tts_warning_en_2': ('[nervous] Under a hundred meters. Speed up.', 0.25, 0.85, 0.65),
    'tts_warning_en_3': ('[nervous] The heartbeat is getting louder.', 0.3, 0.85, 0.6),
    'tts_warning_en_4': ('[nervous] Footsteps behind you.', 0.25, 0.85, 0.65),
    'tts_warning_en_5': ('[nervous] There is still time. Run faster.', 0.3, 0.85, 0.55),

    # 추격 근접 (50~100m)
    'tts_warning_close_en_1': ('[urgent] Fifty meters. You can hear it breathing.', 0.2, 0.9, 0.75),
    'tts_warning_close_en_2': ('[urgent] Faster! Now or never!', 0.15, 0.9, 0.8),
    'tts_warning_close_en_3': ('[urgent] The shadow has almost caught you.', 0.2, 0.9, 0.75),
    'tts_warning_close_en_4': ('[urgent] Run. Right now.', 0.15, 0.9, 0.8),
    'tts_warning_close_en_5': ('[urgent] You will be caught at this speed. Sprint!', 0.15, 0.9, 0.85),

    # 바로 뒤 (20~50m)
    'tts_danger_en_1': ('[whispers][heavy breathing] Right behind you...', 0.1, 0.9, 0.9),
    'tts_danger_en_2': ('[whispers][heavy breathing] Within arm\'s reach.', 0.1, 0.9, 0.9),
    'tts_danger_en_3': ('[urgent][heavy breathing] Not fast enough. Sprint now.', 0.15, 0.9, 0.85),
    'tts_danger_en_4': ('[whispers][heavy breathing] You can feel the breath on your neck.', 0.1, 0.9, 0.9),
    'tts_danger_en_5': ('[urgent][heavy breathing] Last chance.', 0.15, 0.9, 0.85),

    # 코앞 (0~20m)
    'tts_critical_en_1': ('[screaming] It\'s catching you...', 0.1, 0.95, 1.0),
    'tts_critical_en_2': ('[screaming] No... faster...', 0.1, 0.95, 1.0),
    'tts_critical_en_3': ('[screaming] The shadow is reaching for you.', 0.1, 0.95, 1.0),
    'tts_critical_en_4': ('[screaming] It\'s over... no, not yet! Run!', 0.1, 0.95, 1.0),
    'tts_critical_en_5': ('[screaming] Now or it ends!', 0.1, 0.95, 1.0),

    # 리드 잃을 때
    'tts_losing_lead_en_1': ('[urgent] Losing your lead!', 0.2, 0.9, 0.75),
    'tts_losing_lead_en_2': ('[urgent] Slowing down. The shadow is closing in.', 0.2, 0.9, 0.75),
    'tts_losing_lead_en_3': ('[nervous] Where did that pace go?', 0.25, 0.85, 0.65),
    'tts_losing_lead_en_4': ('[nervous] The gap is shrinking.', 0.25, 0.85, 0.65),
    'tts_losing_lead_en_5': ('[urgent] Dangerous. Pick up the pace.', 0.2, 0.9, 0.75),

    # === 마라토너 영어 — 새 대사 ===
    # 초반 격려
    'tts_marathon_early_en_1': ('[calm] Good. Your body is warming up.', 0.5, 0.8, 0.3),
    'tts_marathon_early_en_2': ('[calm] The first five minutes are the hardest. Push through.', 0.45, 0.8, 0.35),
    'tts_marathon_early_en_3': ('[calm] Find your rhythm. Match it to your breath.', 0.5, 0.8, 0.3),
    'tts_marathon_early_en_4': ('[calm] Starting slow is the right move.', 0.5, 0.8, 0.3),
    'tts_marathon_early_en_5': ('[calm] Think of this as a warm-up.', 0.5, 0.8, 0.3),

    # 중반 격려
    'tts_marathon_mid_en_1': ('[calm] Good. You found your rhythm.', 0.5, 0.8, 0.3),
    'tts_marathon_mid_en_2': ('[calm] Get past this and your body gets lighter.', 0.45, 0.8, 0.35),
    'tts_marathon_mid_en_3': ('[calm] Focus on breathing. In... and out.', 0.5, 0.8, 0.3),
    'tts_marathon_mid_en_4': ('[calm] Remember why you are running.', 0.5, 0.8, 0.35),
    'tts_marathon_mid_en_5': ('[calm] Relax your shoulders. Arms natural.', 0.5, 0.8, 0.3),
    'tts_marathon_mid_en_6': ('[calm] Light foot strikes. Land on your midfoot.', 0.5, 0.8, 0.3),
    'tts_marathon_mid_en_7': ('[calm] You are doing great. Really.', 0.5, 0.8, 0.3),

    # 후반 격려
    'tts_marathon_late_en_1': ('[calm] When you want to quit, that is when it really starts.', 0.45, 0.8, 0.4),
    'tts_marathon_late_en_2': ('[calm] One more step. Just think about that.', 0.5, 0.8, 0.35),
    'tts_marathon_late_en_3': ('[calm] You are stronger than you think.', 0.5, 0.8, 0.3),
    'tts_marathon_late_en_4': ('[calm] You came this far. Too good to stop now.', 0.45, 0.8, 0.35),
    'tts_marathon_late_en_5': ('[calm] Pain is temporary. Pride is forever.', 0.45, 0.8, 0.4),
    'tts_marathon_late_en_6': ('[calm] This is the hardest part. Get through it.', 0.45, 0.8, 0.35),
    'tts_marathon_late_en_7': ('[calm] Dig deep. Find that last bit of energy.', 0.45, 0.8, 0.4),

    # 러닝 팁
    'tts_marathon_tip_en_1': ('[calm] Eyes forward, thirty meters ahead. Don\'t look down.', 0.5, 0.8, 0.3),
    'tts_marathon_tip_en_2': ('[calm] Minimize your ground contact time.', 0.5, 0.8, 0.3),
    'tts_marathon_tip_en_3': ('[calm] Elbows at ninety degrees. Swing front to back.', 0.5, 0.8, 0.3),
    'tts_marathon_tip_en_4': ('[calm] Engage your core slightly. It improves your form.', 0.5, 0.8, 0.3),
    'tts_marathon_tip_en_5': ('[calm] Breathe in through your nose, out through your mouth.', 0.5, 0.8, 0.3),
    'tts_marathon_tip_en_6': ('[calm] Shorten your stride and increase your cadence.', 0.5, 0.8, 0.3),
    'tts_marathon_tip_en_7': ('[calm] Time for water. Drink before you feel thirsty.', 0.5, 0.8, 0.3),
    'tts_marathon_tip_en_8': ('[calm] Downhill? Shorten your stride, don\'t speed up.', 0.5, 0.8, 0.3),

    # 페이스 피드백
    'tts_pace_fast_new_en_1': ('[calm] Oh, picking up speed? Nice!', 0.5, 0.8, 0.35),
    'tts_pace_fast_new_en_2': ('[calm] Pace up! Keep this rhythm going.', 0.5, 0.8, 0.35),
    'tts_pace_fast_new_en_3': ('[calm] You are on personal record pace. Can you hold it?', 0.45, 0.8, 0.4),
    'tts_pace_fast_new_en_4': ('[calm] Getting faster. Your body is responding.', 0.5, 0.8, 0.35),

    'tts_pace_slow_new_en_1': ('[calm] Pace dropped a bit. No worries, bring it back.', 0.5, 0.8, 0.3),
    'tts_pace_slow_new_en_2': ('[calm] Push a little harder. Find your pace again.', 0.5, 0.8, 0.3),
    'tts_pace_slow_new_en_3': ('[calm] Slowing down is okay. Just don\'t stop.', 0.5, 0.8, 0.3),
    'tts_pace_slow_new_en_4': ('[calm] Easy does it. Finishing is the goal.', 0.5, 0.8, 0.3),
}

os.makedirs(OUTDIR, exist_ok=True)

def generate(voice_key, voice_id):
    print(f'\n=== {voice_key} ({voice_id}) ===')
    count = 0
    for base_name, (text, stability, similarity, style) in LINES.items():
        if voice_key == 'harry':
            filename = f'{base_name}.mp3'
        else:
            filename = f'{base_name}_{voice_key}.mp3'

        filepath = os.path.join(OUTDIR, filename)
        if os.path.exists(filepath):
            print(f'  SKIP: {filename}')
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
                count += 1
        except urllib.error.HTTPError as e:
            error_body = e.read().decode('utf-8')
            print(f'  FAIL: {filename} - {e.code} - {error_body[:200]}')

        time.sleep(0.3)
    return count

total = 0
for key, vid in VOICES.items():
    total += generate(key, vid)

print(f'\n전체 영어 TTS 생성 완료! 새로 생성: {total}개')
