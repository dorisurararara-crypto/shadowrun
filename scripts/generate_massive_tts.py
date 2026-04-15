"""대량 TTS 생성 — 도플갱어 캐릭터 대사 + 마라토너 재미 요소"""
import urllib.request, json, os, time

API_KEY = os.environ.get('ELEVENLABS_API_KEY', '')
MODEL = 'eleven_v3'
OUTDIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'assets', 'audio')
os.makedirs(OUTDIR, exist_ok=True)

VOICES = {
    'harry': 'SOYHLrjzK2X1ezoPC6cr',
    'callum': 'N2lVS1w4EtoT3dr4eOWO',
    'drill': 'DGzg6RaUqxGRTHSBjfgF',
}

# ========================================
# 도플갱어 추가 대사 (레벨당 +10개)
# ========================================
DOPPELGANGER_KO = {
    # 앞서감 압도적 (400m+) — 도플갱어가 말하는 듯한 느낌
    'tts_ahead_far_6': ('[calm] 멀리 도망갔다고 생각해? 난 항상 여기 있어.', 0.5, 0.8, 0.35),
    'tts_ahead_far_7': ('[calm] 이 페이스... 기억해둘게. 다음엔 이걸로 쫓아갈 테니까.', 0.45, 0.8, 0.4),
    'tts_ahead_far_8': ('[calm] 여유 부릴 시간이야. 곧 달라질 거지만.', 0.5, 0.8, 0.35),
    'tts_ahead_far_9': ('[calm] 400미터 이상 앞서고 있어. 대단해. 하지만 영원하진 않아.', 0.5, 0.8, 0.3),
    'tts_ahead_far_10': ('[calm] 뒤를 안 돌아봐도 돼. 아직은.', 0.5, 0.8, 0.35),

    # 앞서감 여유 (250~400m)
    'tts_ahead_mid_6': ('[nervous] 그림자가 점점 빨라지고 있어. 느껴져?', 0.3, 0.85, 0.55),
    'tts_ahead_mid_7': ('[calm] 좋은 리드야. 하지만 마지막 1km에서 뒤집히는 경우가 많아.', 0.45, 0.8, 0.4),
    'tts_ahead_mid_8': ('[nervous] 저번에도 이쯤에서 느려졌어. 기억 안 나?', 0.3, 0.85, 0.5),
    'tts_ahead_mid_9': ('[calm] 거리를 벌리고 있지만, 그림자는 절대 지치지 않아.', 0.45, 0.8, 0.4),
    'tts_ahead_mid_10': ('[calm] 넌 지치지만 그림자는 안 지쳐. 그게 차이야.', 0.45, 0.8, 0.45),

    # 앞서감 막 벗어남 (200~250m)
    'tts_ahead_close_6': ('[nervous] 안전권이라고? 200미터는 10초면 사라져.', 0.3, 0.85, 0.55),
    'tts_ahead_close_7': ('[nervous] 방금 벗어났어. 다시 잡히기 전에 더 벌려.', 0.3, 0.85, 0.5),
    'tts_ahead_close_8': ('[urgent] 이 정도로는 부족해. 더 빨리!', 0.25, 0.85, 0.6),
    'tts_ahead_close_9': ('[nervous] 아직 숨소리가 들리는 거리야.', 0.3, 0.85, 0.55),
    'tts_ahead_close_10': ('[nervous] 그림자가 멈춘 게 아니야. 기다리는 거야.', 0.3, 0.85, 0.6),

    # 안전 (150~200m) — 불안한 정적
    'tts_safe_6': ('[whispers] 너무 조용해... 뭔가 이상해.', 0.2, 0.85, 0.7),
    'tts_safe_7': ('[calm] 안전하다고 느끼는 순간이 가장 위험해.', 0.4, 0.8, 0.45),
    'tts_safe_8': ('[nervous] 공기가 달라졌어. 느껴지지?', 0.3, 0.85, 0.55),
    'tts_safe_9': ('[whispers] 그림자는 어둠 속에서 기다리고 있어.', 0.15, 0.9, 0.75),
    'tts_safe_10': ('[calm] 이 고요함을 즐겨. 곧 끝날 테니까.', 0.4, 0.8, 0.45),

    # 추격 중 (100~150m) — 긴박
    'tts_warning_6': ('[nervous] 뒤에서 발소리가 빨라지고 있어!', 0.25, 0.85, 0.65),
    'tts_warning_7': ('[nervous] 100미터... 전력질주하면 10초야. 서둘러.', 0.25, 0.85, 0.65),
    'tts_warning_8': ('[urgent] 지금 속도를 올리지 않으면 30초 안에 잡혀.', 0.2, 0.9, 0.7),
    'tts_warning_9': ('[nervous] 저번에 여기서 잡혔어. 이번엔 다를 수 있을까?', 0.3, 0.85, 0.6),
    'tts_warning_10': ('[nervous] 심장이 빨라지고 있어. 그건 네 심장이야... 맞지?', 0.25, 0.85, 0.65),

    # 추격 근접 (50~100m) — 공포
    'tts_warning_close_6': ('[urgent] 그림자의 손이 네 등에 닿을 것 같아!', 0.15, 0.9, 0.8),
    'tts_warning_close_7': ('[urgent] 뒤돌아보지 마. 뛰기만 해!', 0.15, 0.9, 0.85),
    'tts_warning_close_8': ('[urgent] 50미터... 숨을 참고 달려!', 0.15, 0.9, 0.8),
    'tts_warning_close_9': ('[urgent] 더 빨리 뛸 수 있잖아. 왜 안 뛰어?!', 0.15, 0.9, 0.85),
    'tts_warning_close_10': ('[urgent] 지금이 진짜야. 전력으로 달려!', 0.15, 0.9, 0.8),

    # 바로 뒤 (20~50m) — 극한
    'tts_danger_6': ('[whispers][heavy breathing] 뒤에서 체온이 느껴져...', 0.1, 0.9, 0.9),
    'tts_danger_7': ('[urgent][heavy breathing] 안 돼, 안 돼, 안 돼! 더 빨리!', 0.1, 0.95, 0.95),
    'tts_danger_8': ('[whispers][heavy breathing] 그림자가 웃고 있어...', 0.1, 0.9, 0.9),
    'tts_danger_9': ('[urgent][heavy breathing] 지금 뛰지 않으면 영영 끝이야!', 0.1, 0.95, 0.95),
    'tts_danger_10': ('[whispers][heavy breathing] 이제... 거의... 끝이야...', 0.1, 0.9, 0.95),

    # 코앞 (0~20m) — 절박
    'tts_critical_6': ('[screaming] 잡았다...!', 0.1, 0.95, 1.0),
    'tts_critical_7': ('[screaming] 넌 나한테서 도망칠 수 없어!', 0.1, 0.95, 1.0),
    'tts_critical_8': ('[screaming] 뛰어! 제발! 지금!', 0.1, 0.95, 1.0),
    'tts_critical_9': ('[screaming] 여기서 끝이야... 아니면...?!', 0.1, 0.95, 1.0),
    'tts_critical_10': ('[screaming] 과거의 너는 더 빨랐어!', 0.1, 0.95, 1.0),

    # 리드 잃을 때 추가
    'tts_losing_lead_6': ('[urgent] 방금 10미터가 줄었어!', 0.2, 0.9, 0.75),
    'tts_losing_lead_7': ('[nervous] 페이스가 흔들리고 있어. 그림자는 흔들리지 않아.', 0.25, 0.85, 0.65),
    'tts_losing_lead_8': ('[urgent] 지금 이 순간에도 간격이 좁혀지고 있어!', 0.2, 0.9, 0.75),
    'tts_losing_lead_9': ('[nervous] 아까 그 속도 어디 갔어? 되찾아!', 0.25, 0.85, 0.65),
    'tts_losing_lead_10': ('[urgent] 그림자가 가속하고 있어!', 0.2, 0.9, 0.75),
}

# ========================================
# 마라토너 재미 요소 + 추가 격려
# ========================================
MARATHON_KO = {
    # 재미있는 러닝 팩트
    'tts_funfact_1': ('[calm] 재미있는 사실. 인간은 장거리에서 말보다 빠릅니다. 당신은 진화의 걸작이에요.', 0.5, 0.8, 0.3),
    'tts_funfact_2': ('[calm] 마라톤 세계 기록은 2시간 0분 35초입니다. 킵초게가 세웠죠. 당신은... 잘하고 있어요.', 0.5, 0.8, 0.3),
    'tts_funfact_3': ('[calm] 러닝 중 뇌에서 엔도르핀이 분비됩니다. 곧 러너스 하이가 올 거예요.', 0.5, 0.8, 0.3),
    'tts_funfact_4': ('[calm] 러닝은 평균 수명을 3~7년 늘려줍니다. 지금 달리는 매 분이 수명을 연장하고 있어요.', 0.5, 0.8, 0.3),
    'tts_funfact_5': ('[calm] 인간의 아킬레스건은 스프링처럼 에너지를 저장했다가 방출합니다. 당신은 지금 천연 스프링으로 달리고 있어요.', 0.5, 0.8, 0.3),
    'tts_funfact_6': ('[calm] 러닝은 뇌의 해마를 키워줍니다. 달릴수록 기억력이 좋아져요.', 0.5, 0.8, 0.3),
    'tts_funfact_7': ('[calm] 1km를 달리면 평균 60~80 칼로리를 소모합니다. 지금까지 꽤 태웠을 거예요.', 0.5, 0.8, 0.3),
    'tts_funfact_8': ('[calm] 프로 러너의 심박수는 분당 40회까지 내려갑니다. 꾸준히 달리면 심장이 강해져요.', 0.5, 0.8, 0.3),
    'tts_funfact_9': ('[calm] 고대 그리스에서 마라톤의 유래가 된 페이디피데스는 42km를 뛰고 소식을 전한 뒤 쓰러졌습니다. 당신은 쓰러지지 마세요.', 0.5, 0.8, 0.3),
    'tts_funfact_10': ('[calm] 러닝은 창의력을 25% 향상시킵니다. 달리면서 좋은 아이디어가 떠오르는 건 우연이 아닙니다.', 0.5, 0.8, 0.3),

    # 유명인 명언
    'tts_athlete_1': ('[calm] 무라카미 하루키가 말했죠. 고통은 피할 수 없지만, 고통을 견디는 것은 선택이라고.', 0.5, 0.8, 0.35),
    'tts_athlete_2': ('[calm] 에밀 자토펙이 말했습니다. 힘들면 느려지면 됩니다. 중요한 건 멈추지 않는 것.', 0.5, 0.8, 0.35),
    'tts_athlete_3': ('[calm] 나이키 창업자 필 나이트가 말했죠. 포기하지 마라. 마법 같은 일은 마지막 순간에 일어난다.', 0.5, 0.8, 0.35),
    'tts_athlete_4': ('[calm] 킵초게가 말했습니다. 인간에게 한계는 없다.', 0.5, 0.8, 0.35),
    'tts_athlete_5': ('[calm] 무하마드 알리가 말했죠. 고통을 느끼기 시작한 후부터 세기 시작해라. 그때부터가 진짜 운동이다.', 0.5, 0.8, 0.35),
    'tts_athlete_6': ('[calm] 딘 카나제스가 말했습니다. 달리기가 편해지면, 더 빨리 달려라.', 0.5, 0.8, 0.35),
    'tts_athlete_7': ('[calm] 프리퐁텐이 말했죠. 재능만으로 이길 수 있는 거리는 없다. 의지가 필요해.', 0.5, 0.8, 0.35),
    'tts_athlete_8': ('[calm] 윌마 루돌프가 말했습니다. 이기는 것은 위대하지만, 포기하지 않는 것은 더 위대하다.', 0.5, 0.8, 0.35),
    'tts_athlete_9': ('[calm] 손기정 선생님이 보여주셨죠. 달리는 것은 자유를 향한 발걸음이라고.', 0.5, 0.8, 0.35),
    'tts_athlete_10': ('[calm] 오프라 윈프리가 말했습니다. 달리기는 나를 만나는 시간이다.', 0.5, 0.8, 0.35),

    # 추가 격려 (시간대별)
    'tts_marathon_early_6': ('[calm] 첫 발걸음이 가장 무거워. 이미 그걸 넘었어.', 0.5, 0.8, 0.3),
    'tts_marathon_early_7': ('[calm] 몸이 아직 차가워. 5분만 지나면 달라질 거야.', 0.5, 0.8, 0.3),
    'tts_marathon_early_8': ('[calm] 오늘 밖에 나와서 뛰는 것만으로도 상위 5%야.', 0.5, 0.8, 0.3),

    'tts_marathon_mid_8': ('[calm] 지금 네 몸에서 엔도르핀이 나오기 시작할 거야.', 0.5, 0.8, 0.3),
    'tts_marathon_mid_9': ('[calm] 이 순간을 즐겨. 러닝은 명상이야.', 0.5, 0.8, 0.3),
    'tts_marathon_mid_10': ('[calm] 주변을 둘러봐. 풍경을 느껴봐. 이게 러닝의 즐거움이야.', 0.5, 0.8, 0.3),
    'tts_marathon_mid_11': ('[calm] 힘든 건 자연스러운 거야. 몸이 적응하는 과정이야.', 0.5, 0.8, 0.3),
    'tts_marathon_mid_12': ('[calm] 숨이 차면 속도를 줄여. 멈추지만 않으면 돼.', 0.5, 0.8, 0.3),

    'tts_marathon_late_8': ('[calm] 끝이 보여. 조금만 더!', 0.45, 0.8, 0.4),
    'tts_marathon_late_9': ('[calm] 이 고통은 내일이면 자부심으로 바뀔 거야.', 0.45, 0.8, 0.4),
    'tts_marathon_late_10': ('[calm] 지금 포기하면 아까 뛴 게 전부 헛수고야. 마저 끝내.', 0.45, 0.8, 0.4),
    'tts_marathon_late_11': ('[calm] 뇌가 그만두라고 해도 몸은 아직 갈 수 있어.', 0.45, 0.8, 0.4),
    'tts_marathon_late_12': ('[calm] 마지막 100미터라고 생각하고 달려봐.', 0.45, 0.8, 0.4),

    # 추가 팁
    'tts_marathon_tip_9': ('[calm] 오르막에서는 시선을 3미터 앞 바닥에 두세요.', 0.5, 0.8, 0.3),
    'tts_marathon_tip_10': ('[calm] 턱을 살짝 당기면 호흡이 편해집니다.', 0.5, 0.8, 0.3),
    'tts_marathon_tip_11': ('[calm] 양팔을 크게 흔들면 에너지 낭비야. 작고 빠르게.', 0.5, 0.8, 0.3),
    'tts_marathon_tip_12': ('[calm] 발가락에 힘을 빼세요. 발이 가벼워집니다.', 0.5, 0.8, 0.3),
}

# 영어 버전
DOPPELGANGER_EN = {
    'tts_ahead_far_en_6': ('[calm] Think you ran far enough? I am always here.', 0.5, 0.8, 0.35),
    'tts_ahead_far_en_7': ('[calm] This pace... I will remember it. Next time, I will use it.', 0.45, 0.8, 0.4),
    'tts_ahead_far_en_8': ('[calm] Enjoy the calm. It will change soon.', 0.5, 0.8, 0.35),
    'tts_ahead_far_en_9': ('[calm] Over 400 meters ahead. Impressive. But not forever.', 0.5, 0.8, 0.3),
    'tts_ahead_far_en_10': ('[calm] You don\'t need to look back. Not yet.', 0.5, 0.8, 0.35),

    'tts_ahead_mid_en_6': ('[nervous] The shadow is getting faster. Can you feel it?', 0.3, 0.85, 0.55),
    'tts_ahead_mid_en_7': ('[calm] Good lead. But most people get caught in the last kilometer.', 0.45, 0.8, 0.4),
    'tts_ahead_mid_en_8': ('[nervous] Last time you slowed down right about here. Remember?', 0.3, 0.85, 0.5),
    'tts_ahead_mid_en_9': ('[calm] You are pulling ahead, but the shadow never gets tired.', 0.45, 0.8, 0.4),
    'tts_ahead_mid_en_10': ('[calm] You get tired. The shadow does not. That is the difference.', 0.45, 0.8, 0.45),

    'tts_ahead_close_en_6': ('[nervous] Safe? 200 meters disappears in 10 seconds.', 0.3, 0.85, 0.55),
    'tts_ahead_close_en_7': ('[nervous] Just escaped. Widen the gap before it catches up again.', 0.3, 0.85, 0.5),
    'tts_ahead_close_en_8': ('[urgent] This is not enough. Faster!', 0.25, 0.85, 0.6),
    'tts_ahead_close_en_9': ('[nervous] Still within earshot of its breathing.', 0.3, 0.85, 0.55),
    'tts_ahead_close_en_10': ('[nervous] The shadow hasn\'t stopped. It is waiting.', 0.3, 0.85, 0.6),

    'tts_safe_en_6': ('[whispers] Too quiet... Something is wrong.', 0.2, 0.85, 0.7),
    'tts_safe_en_7': ('[calm] The moment you feel safe is the most dangerous.', 0.4, 0.8, 0.45),
    'tts_safe_en_8': ('[nervous] The air changed. Can you feel it?', 0.3, 0.85, 0.55),
    'tts_safe_en_9': ('[whispers] The shadow waits in the darkness.', 0.15, 0.9, 0.75),
    'tts_safe_en_10': ('[calm] Enjoy this silence. It won\'t last.', 0.4, 0.8, 0.45),

    'tts_warning_en_6': ('[nervous] The footsteps behind you are getting faster!', 0.25, 0.85, 0.65),
    'tts_warning_en_7': ('[nervous] 100 meters... a sprinter covers that in 10 seconds. Hurry.', 0.25, 0.85, 0.65),
    'tts_warning_en_8': ('[urgent] If you don\'t speed up now, you are caught in 30 seconds.', 0.2, 0.9, 0.7),
    'tts_warning_en_9': ('[nervous] Last time you were caught here. Will this time be different?', 0.3, 0.85, 0.6),
    'tts_warning_en_10': ('[nervous] Your heart is racing. That is your heart... right?', 0.25, 0.85, 0.65),

    'tts_warning_close_en_6': ('[urgent] The shadow\'s hand is about to touch your back!', 0.15, 0.9, 0.8),
    'tts_warning_close_en_7': ('[urgent] Don\'t look back. Just run!', 0.15, 0.9, 0.85),
    'tts_warning_close_en_8': ('[urgent] 50 meters... hold your breath and sprint!', 0.15, 0.9, 0.8),
    'tts_warning_close_en_9': ('[urgent] You can run faster than this. Why aren\'t you?!', 0.15, 0.9, 0.85),
    'tts_warning_close_en_10': ('[urgent] This is real. Full speed now!', 0.15, 0.9, 0.8),

    'tts_danger_en_6': ('[whispers][heavy breathing] Body heat... right behind you...', 0.1, 0.9, 0.9),
    'tts_danger_en_7': ('[urgent][heavy breathing] No no no! Faster!', 0.1, 0.95, 0.95),
    'tts_danger_en_8': ('[whispers][heavy breathing] The shadow is smiling...', 0.1, 0.9, 0.9),
    'tts_danger_en_9': ('[urgent][heavy breathing] If you don\'t run now it is over forever!', 0.1, 0.95, 0.95),
    'tts_danger_en_10': ('[whispers][heavy breathing] Almost... over...', 0.1, 0.9, 0.95),

    'tts_critical_en_6': ('[screaming] Got you...!', 0.1, 0.95, 1.0),
    'tts_critical_en_7': ('[screaming] You can\'t escape me!', 0.1, 0.95, 1.0),
    'tts_critical_en_8': ('[screaming] Run! Please! Now!', 0.1, 0.95, 1.0),
    'tts_critical_en_9': ('[screaming] It ends here... unless...?!', 0.1, 0.95, 1.0),
    'tts_critical_en_10': ('[screaming] Your past self was faster!', 0.1, 0.95, 1.0),

    'tts_losing_lead_en_6': ('[urgent] Just lost 10 meters!', 0.2, 0.9, 0.75),
    'tts_losing_lead_en_7': ('[nervous] Your pace is shaking. The shadow\'s is not.', 0.25, 0.85, 0.65),
    'tts_losing_lead_en_8': ('[urgent] Right now the gap is closing!', 0.2, 0.9, 0.75),
    'tts_losing_lead_en_9': ('[nervous] Where is that speed from earlier? Find it!', 0.25, 0.85, 0.65),
    'tts_losing_lead_en_10': ('[urgent] The shadow is accelerating!', 0.2, 0.9, 0.75),
}

MARATHON_EN = {
    'tts_funfact_en_1': ('[calm] Fun fact. Humans are faster than horses over long distances. You are an evolutionary masterpiece.', 0.5, 0.8, 0.3),
    'tts_funfact_en_2': ('[calm] The marathon world record is 2 hours 0 minutes 35 seconds. By Kipchoge. You are... doing great.', 0.5, 0.8, 0.3),
    'tts_funfact_en_3': ('[calm] Your brain is releasing endorphins right now. Runner\'s high is coming.', 0.5, 0.8, 0.3),
    'tts_funfact_en_4': ('[calm] Running adds 3 to 7 years to your life. Every minute you run extends your lifespan.', 0.5, 0.8, 0.3),
    'tts_funfact_en_5': ('[calm] Your Achilles tendon stores and releases energy like a spring. You are running on natural springs.', 0.5, 0.8, 0.3),
    'tts_funfact_en_6': ('[calm] Running grows your hippocampus. The more you run, the better your memory.', 0.5, 0.8, 0.3),
    'tts_funfact_en_7': ('[calm] One kilometer burns 60 to 80 calories on average. You have burned quite a bit by now.', 0.5, 0.8, 0.3),
    'tts_funfact_en_8': ('[calm] Pro runners have resting heart rates as low as 40 BPM. Consistent running strengthens your heart.', 0.5, 0.8, 0.3),
    'tts_funfact_en_9': ('[calm] Pheidippides ran 42km to deliver a message in ancient Greece. He collapsed after. Please don\'t collapse.', 0.5, 0.8, 0.3),
    'tts_funfact_en_10': ('[calm] Running boosts creativity by 25%. Good ideas while running are not a coincidence.', 0.5, 0.8, 0.3),

    'tts_athlete_en_1': ('[calm] Murakami said: Pain is inevitable, but suffering is optional.', 0.5, 0.8, 0.35),
    'tts_athlete_en_2': ('[calm] Emil Zatopek said: If you are tired, slow down. Just don\'t stop.', 0.5, 0.8, 0.35),
    'tts_athlete_en_3': ('[calm] Phil Knight said: Don\'t give up. Magic happens at the last moment.', 0.5, 0.8, 0.35),
    'tts_athlete_en_4': ('[calm] Kipchoge said: No human is limited.', 0.5, 0.8, 0.35),
    'tts_athlete_en_5': ('[calm] Ali said: Start counting when it starts hurting. That is when it really counts.', 0.5, 0.8, 0.35),
    'tts_athlete_en_6': ('[calm] Dean Karnazes said: If it feels easy, run harder.', 0.5, 0.8, 0.35),
    'tts_athlete_en_7': ('[calm] Prefontaine said: Talent can\'t win any distance. You need will.', 0.5, 0.8, 0.35),
    'tts_athlete_en_8': ('[calm] Wilma Rudolph said: Winning is great, but not giving up is greater.', 0.5, 0.8, 0.35),
    'tts_athlete_en_9': ('[calm] Every step you take is a step toward freedom.', 0.5, 0.8, 0.35),
    'tts_athlete_en_10': ('[calm] Oprah said: Running is the time I meet myself.', 0.5, 0.8, 0.35),

    'tts_marathon_early_en_6': ('[calm] The first step is the heaviest. You already passed it.', 0.5, 0.8, 0.3),
    'tts_marathon_early_en_7': ('[calm] Your body is still cold. Five minutes and it changes.', 0.5, 0.8, 0.3),
    'tts_marathon_early_en_8': ('[calm] Just by coming out to run today, you are in the top 5%.', 0.5, 0.8, 0.3),

    'tts_marathon_mid_en_8': ('[calm] Endorphins are about to kick in. Feel it coming.', 0.5, 0.8, 0.3),
    'tts_marathon_mid_en_9': ('[calm] Enjoy this moment. Running is meditation.', 0.5, 0.8, 0.3),
    'tts_marathon_mid_en_10': ('[calm] Look around. Take in the scenery. This is the joy of running.', 0.5, 0.8, 0.3),
    'tts_marathon_mid_en_11': ('[calm] Feeling tough is natural. Your body is adapting.', 0.5, 0.8, 0.3),
    'tts_marathon_mid_en_12': ('[calm] If breathing gets hard, slow down. Just don\'t stop.', 0.5, 0.8, 0.3),

    'tts_marathon_late_en_8': ('[calm] The end is in sight. Just a little more!', 0.45, 0.8, 0.4),
    'tts_marathon_late_en_9': ('[calm] This pain will turn into pride by tomorrow.', 0.45, 0.8, 0.4),
    'tts_marathon_late_en_10': ('[calm] Quit now and everything you ran was for nothing. Finish it.', 0.45, 0.8, 0.4),
    'tts_marathon_late_en_11': ('[calm] Your brain says quit but your body can still go.', 0.45, 0.8, 0.4),
    'tts_marathon_late_en_12': ('[calm] Pretend the next 100 meters is the last. Then do it again.', 0.45, 0.8, 0.4),

    'tts_marathon_tip_en_9': ('[calm] On uphills, look 3 meters ahead at the ground.', 0.5, 0.8, 0.3),
    'tts_marathon_tip_en_10': ('[calm] Tuck your chin slightly. It makes breathing easier.', 0.5, 0.8, 0.3),
    'tts_marathon_tip_en_11': ('[calm] Big arm swings waste energy. Keep them small and quick.', 0.5, 0.8, 0.3),
    'tts_marathon_tip_en_12': ('[calm] Relax your toes. Your feet become lighter.', 0.5, 0.8, 0.3),
}

ALL_LINES = {}
ALL_LINES.update(DOPPELGANGER_KO)
ALL_LINES.update(DOPPELGANGER_EN)
ALL_LINES.update(MARATHON_KO)
ALL_LINES.update(MARATHON_EN)

print(f'총 {len(ALL_LINES)}개 기본 대사 × 3 음성 = {len(ALL_LINES) * 3}개 mp3 생성 예정\n')

total_generated = 0
total_skipped = 0
total_failed = 0

for voice_key, voice_id in VOICES.items():
    print(f'\n=== {voice_key} ({voice_id}) ===')
    for base_name, (text, stability, similarity, style) in ALL_LINES.items():
        if voice_key == 'harry':
            filename = f'{base_name}.mp3'
        else:
            filename = f'{base_name}_{voice_key}.mp3'

        filepath = os.path.join(OUTDIR, filename)
        if os.path.exists(filepath):
            total_skipped += 1
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
                total_generated += 1
        except urllib.error.HTTPError as e:
            error_body = e.read().decode('utf-8')
            print(f'  FAIL: {filename} - {e.code} - {error_body[:200]}')
            total_failed += 1

        time.sleep(0.3)

print(f'\n========================================')
print(f'생성: {total_generated} | 스킵: {total_skipped} | 실패: {total_failed}')
print(f'========================================')
