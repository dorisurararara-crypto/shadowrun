import urllib.request, json, os, time

API_KEY = 'sk_00bc51e2397013aa4ff2a2c1e6389c01c31cb0ed94b3abed'
MODEL = 'eleven_v3'
OUTDIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'assets', 'audio')

VOICES = {
    'harry': 'SOYHLrjzK2X1ezoPC6cr',
    'callum': 'N2lVS1w4EtoT3dr4eOWO',
    'drill': 'DGzg6RaUqxGRTHSBjfgF',
}

# 기본 voice settings (마라토너/자유러닝 코치 톤)
DEFAULT_VS = (0.7, 0.8, 0.4)  # stability, similarity, style

# ==========================================
# A. 자유 러닝 - 시작 (6변형)
# ==========================================
SOLO_START = {
    'tts_start_solo_1': ('[commanding] 기록을 남겨. 달려.', *DEFAULT_VS),
    'tts_start_solo_2': ('[stern] 준비됐지? 출발.', *DEFAULT_VS),
    'tts_start_solo_3': ('[commanding] 오늘의 너를 증명해.', *DEFAULT_VS),
    'tts_start_solo_4': ('[firm] 달려. 생각은 나중에.', *DEFAULT_VS),
    'tts_start_solo_5': ('[warm] 시작이 반이야. 가자.', *DEFAULT_VS),
    'tts_start_solo_6': ('[calm] 몸이 원하고 있어. 움직여.', *DEFAULT_VS),
}
SOLO_START_EN = {
    'tts_start_solo_en_1': ('[commanding] Leave your mark. Run.', *DEFAULT_VS),
    'tts_start_solo_en_2': ('[stern] Ready? Go.', *DEFAULT_VS),
    'tts_start_solo_en_3': ('[commanding] Prove yourself today.', *DEFAULT_VS),
    'tts_start_solo_en_4': ('[firm] Run. Think later.', *DEFAULT_VS),
    'tts_start_solo_en_5': ('[warm] Starting is half the battle. Let\'s go.', *DEFAULT_VS),
    'tts_start_solo_en_6': ('[calm] Your body wants this. Move.', *DEFAULT_VS),
}

# ==========================================
# B. 자유 러닝 - 종료 (6변형)
# ==========================================
SOLO_END = {
    'tts_end_solo_1': ('[warm] 수고했어. 기록이 저장됐다.', *DEFAULT_VS),
    'tts_end_solo_2': ('[warm] 오늘도 해냈어. 대단해.', *DEFAULT_VS),
    'tts_end_solo_3': ('[calm] 끝까지 뛰었어. 그게 다야.', *DEFAULT_VS),
    'tts_end_solo_4': ('[friendly] 잘 뛰었어. 내일 또 보자.', *DEFAULT_VS),
    'tts_end_solo_5': ('[commanding] 오늘 기록, 기억해둬.', *DEFAULT_VS),
    'tts_end_solo_6': ('[stern] 멈추지 않았어. 그게 실력이야.', *DEFAULT_VS),
}
SOLO_END_EN = {
    'tts_end_solo_en_1': ('[warm] Good work. Record saved.', *DEFAULT_VS),
    'tts_end_solo_en_2': ('[warm] You did it again. Impressive.', *DEFAULT_VS),
    'tts_end_solo_en_3': ('[calm] You ran to the end. That\'s all that matters.', *DEFAULT_VS),
    'tts_end_solo_en_4': ('[friendly] Good run. See you tomorrow.', *DEFAULT_VS),
    'tts_end_solo_en_5': ('[commanding] Remember today\'s record.', *DEFAULT_VS),
    'tts_end_solo_en_6': ('[stern] You didn\'t stop. That\'s strength.', *DEFAULT_VS),
}

# ==========================================
# C. 마라토너 - 시작 (6변형)
# ==========================================
MARATHON_START = {
    'tts_marathon_start_1': ('[commanding] 오늘도 나왔군. 좋아, 같이 뛰자.', *DEFAULT_VS),
    'tts_marathon_start_2': ('[calm] 마라톤은 한 발짝부터야. 시작하자.', *DEFAULT_VS),
    'tts_marathon_start_3': ('[warm] 몸 상태 어때? 일단 천천히 가자.', *DEFAULT_VS),
    'tts_marathon_start_4': ('[stern] 오늘의 목표는 어제보다 한 발 더.', *DEFAULT_VS),
    'tts_marathon_start_5': ('[friendly] 좋아. 워밍업부터 가볍게.', *DEFAULT_VS),
    'tts_marathon_start_6': ('[commanding] 또 왔어? 꾸준하군. 가자.', *DEFAULT_VS),
}
MARATHON_START_EN = {
    'tts_marathon_start_en_1': ('[commanding] You showed up. Good. Let\'s run.', *DEFAULT_VS),
    'tts_marathon_start_en_2': ('[calm] A marathon starts with one step. Let\'s begin.', *DEFAULT_VS),
    'tts_marathon_start_en_3': ('[warm] How\'s your body? Let\'s start slow.', *DEFAULT_VS),
    'tts_marathon_start_en_4': ('[stern] Today\'s goal: one step more than yesterday.', *DEFAULT_VS),
    'tts_marathon_start_en_5': ('[friendly] Good. Easy warmup first.', *DEFAULT_VS),
    'tts_marathon_start_en_6': ('[commanding] Back again? Consistent. Let\'s go.', *DEFAULT_VS),
}

# ==========================================
# D. 마라토너 - 거리별 (9시점 × 4변형)
# ==========================================
MARATHON_KM = {
    # 1km
    'tts_marathon_1km_1': ('[commanding] 좋아, 처음 1킬로는 워밍업이야. 어깨 힘 빼고, 팔은 90도로 유지해.', *DEFAULT_VS),
    'tts_marathon_1km_2': ('[calm] 1킬로 통과. 몸이 풀리기 시작했어.', *DEFAULT_VS),
    'tts_marathon_1km_3': ('[stern] 1킬로. 아직 시작이야. 페이스 서두르지 마.', *DEFAULT_VS),
    'tts_marathon_1km_4': ('[warm] 첫 1킬로 좋아. 이 리듬 기억해.', *DEFAULT_VS),
    # 2km
    'tts_marathon_2km_1': ('[commanding] 호흡이 중요하다. 코로 들이쉬고, 입으로 내쉬어. 리듬을 만들어.', *DEFAULT_VS),
    'tts_marathon_2km_2': ('[calm] 2킬로. 호흡이 안정되기 시작하는 구간이야.', *DEFAULT_VS),
    'tts_marathon_2km_3': ('[stern] 2킬로 지점. 상체를 곧게 세워. 허리가 구부러지면 폐가 좁아져.', *DEFAULT_VS),
    'tts_marathon_2km_4': ('[commanding] 좋아, 2킬로. 워밍업 끝. 이제부터 진짜야.', *DEFAULT_VS),
    # 3km
    'tts_marathon_3km_1': ('[commanding] 3킬로. 발 착지를 확인해. 발 중간으로 착지하면 무릎에 무리가 덜 가.', *DEFAULT_VS),
    'tts_marathon_3km_2': ('[warm] 3킬로 돌파. 좋은 흐름이야. 유지해.', *DEFAULT_VS),
    'tts_marathon_3km_3': ('[stern] 3킬로. 팔 스윙을 확인해. 좌우로 흔들지 말고, 앞뒤로.', *DEFAULT_VS),
    'tts_marathon_3km_4': ('[calm] 여기서부터 리듬이 잡혀야 해. 3킬로, 잘하고 있어.', *DEFAULT_VS),
    # 4km
    'tts_marathon_4km_1': ('[commanding] 시선은 전방 20미터. 고개 숙이면 폼이 무너진다.', *DEFAULT_VS),
    'tts_marathon_4km_2': ('[calm] 4킬로. 목과 어깨 긴장 풀어. 힘 빼면 더 빨라져.', *DEFAULT_VS),
    'tts_marathon_4km_3': ('[stern] 4킬로. 발목 힘 빼고 자연스럽게 굴려.', *DEFAULT_VS),
    'tts_marathon_4km_4': ('[warm] 잘 오고 있어. 4킬로. 몸이 기억하기 시작했어.', *DEFAULT_VS),
    # 5km
    'tts_marathon_5km_1': ('[commanding] 5킬로 돌파. 대단해. 여기서부터가 진짜 러닝이야.', *DEFAULT_VS),
    'tts_marathon_5km_2': ('[stern] 5킬로. 수분 보충 타이밍이야. 목 마르기 전에 마셔.', *DEFAULT_VS),
    'tts_marathon_5km_3': ('[calm] 5킬로, 반을 넘겼어. 정신력 싸움이 시작된다.', *DEFAULT_VS),
    'tts_marathon_5km_4': ('[warm] 5킬로. 대부분 여기서 멈춰. 넌 계속 가고 있어.', *DEFAULT_VS),
    # 7km
    'tts_marathon_7km_1': ('[commanding] 힘들 때 보폭을 줄여. 작은 보폭이 더 효율적이야.', *DEFAULT_VS),
    'tts_marathon_7km_2': ('[stern] 7킬로. 엉덩이 근육을 써. 다리만으로 뛰면 금방 지쳐.', *DEFAULT_VS),
    'tts_marathon_7km_3': ('[firm] 7킬로. 중반 고비야. 여기서 무너지지 마.', *DEFAULT_VS),
    'tts_marathon_7km_4': ('[warm] 7킬로 통과. 네 몸은 이미 적응했어. 믿어.', *DEFAULT_VS),
    # 10km
    'tts_marathon_10km_1': ('[commanding] 10킬로. 너 지금 상위 10퍼센트 러너야. 멈추지 마.', *DEFAULT_VS),
    'tts_marathon_10km_2': ('[warm] 10킬로 돌파. 여기까지 온 건 실력이야.', *DEFAULT_VS),
    'tts_marathon_10km_3': ('[calm] 10킬로. 다리가 무거울 거야. 정상이야. 계속 가.', *DEFAULT_VS),
    'tts_marathon_10km_4': ('[stern] 10킬로. 프로 선수들도 여기서 페이스 점검해. 너도 확인해봐.', *DEFAULT_VS),
    # 15km
    'tts_marathon_15km_1': ('[stern] 15킬로. 수분 보충 잊지 마. 목마를 때는 이미 늦은 거야.', *DEFAULT_VS),
    'tts_marathon_15km_2': ('[warm] 15킬로. 여기까지 뛰는 사람은 많지 않아. 자부심을 가져.', *DEFAULT_VS),
    'tts_marathon_15km_3': ('[commanding] 15킬로. 코어에 힘 줘. 허리가 흔들리면 에너지 낭비야.', *DEFAULT_VS),
    'tts_marathon_15km_4': ('[calm] 15킬로 통과. 마라톤의 벽은 아직이야. 지금은 즐겨.', *DEFAULT_VS),
    # 20km
    'tts_marathon_20km_1': ('[warm] 20킬로. 하프 마라톤 거리야. 넌 이미 대단한 러너야.', *DEFAULT_VS),
    'tts_marathon_20km_2': ('[commanding] 20킬로. 여기서부터는 정신이 몸을 이끌어. 포기하지 마.', *DEFAULT_VS),
    'tts_marathon_20km_3': ('[stern] 20킬로. 글리코겐이 바닥나기 시작해. 에너지 보충 생각해.', *DEFAULT_VS),
    'tts_marathon_20km_4': ('[excited] 20킬로 돌파. 전설은 여기서 만들어져.', *DEFAULT_VS),
}

MARATHON_KM_EN = {
    # 1km
    'tts_marathon_1km_en_1': ('[commanding] First kilometer is warmup. Drop your shoulders, keep arms at 90 degrees.', *DEFAULT_VS),
    'tts_marathon_1km_en_2': ('[calm] 1K done. Your body is loosening up.', *DEFAULT_VS),
    'tts_marathon_1km_en_3': ('[stern] 1K. Still the beginning. Don\'t rush your pace.', *DEFAULT_VS),
    'tts_marathon_1km_en_4': ('[warm] First 1K, good. Remember this rhythm.', *DEFAULT_VS),
    # 2km
    'tts_marathon_2km_en_1': ('[commanding] Breathing matters. In through the nose, out through the mouth. Find your rhythm.', *DEFAULT_VS),
    'tts_marathon_2km_en_2': ('[calm] 2K. This is where breathing stabilizes.', *DEFAULT_VS),
    'tts_marathon_2km_en_3': ('[stern] 2K mark. Keep your torso upright. Slouching compresses your lungs.', *DEFAULT_VS),
    'tts_marathon_2km_en_4': ('[commanding] Good, 2K. Warmup done. Now it\'s real.', *DEFAULT_VS),
    # 3km
    'tts_marathon_3km_en_1': ('[commanding] 3K. Check your footstrike. Midfoot landing reduces knee stress.', *DEFAULT_VS),
    'tts_marathon_3km_en_2': ('[warm] 3K cleared. Good flow. Maintain it.', *DEFAULT_VS),
    'tts_marathon_3km_en_3': ('[stern] 3K. Check your arm swing. Forward and back, not side to side.', *DEFAULT_VS),
    'tts_marathon_3km_en_4': ('[calm] This is where rhythm locks in. 3K, doing well.', *DEFAULT_VS),
    # 4km
    'tts_marathon_4km_en_1': ('[commanding] Eyes 20 meters ahead. Drop your head, lose your form.', *DEFAULT_VS),
    'tts_marathon_4km_en_2': ('[calm] 4K. Release neck and shoulder tension. Relaxing makes you faster.', *DEFAULT_VS),
    'tts_marathon_4km_en_3': ('[stern] 4K. Relax your ankles and roll naturally.', *DEFAULT_VS),
    'tts_marathon_4km_en_4': ('[warm] Coming along well. 4K. Your body is starting to remember.', *DEFAULT_VS),
    # 5km
    'tts_marathon_5km_en_1': ('[commanding] 5K done. Impressive. Real running starts here.', *DEFAULT_VS),
    'tts_marathon_5km_en_2': ('[stern] 5K. Time to hydrate. Drink before you\'re thirsty.', *DEFAULT_VS),
    'tts_marathon_5km_en_3': ('[calm] 5K, past halfway. The mental game begins.', *DEFAULT_VS),
    'tts_marathon_5km_en_4': ('[warm] 5K. Most people stop here. You\'re still going.', *DEFAULT_VS),
    # 7km
    'tts_marathon_7km_en_1': ('[commanding] When it gets hard, shorten your stride. Smaller steps are more efficient.', *DEFAULT_VS),
    'tts_marathon_7km_en_2': ('[stern] 7K. Use your glutes. Legs alone tire you fast.', *DEFAULT_VS),
    'tts_marathon_7km_en_3': ('[firm] 7K. Mid-run wall. Don\'t break here.', *DEFAULT_VS),
    'tts_marathon_7km_en_4': ('[warm] 7K cleared. Your body has adapted. Trust it.', *DEFAULT_VS),
    # 10km
    'tts_marathon_10km_en_1': ('[commanding] 10K. You\'re in the top 10 percent of runners now. Don\'t stop.', *DEFAULT_VS),
    'tts_marathon_10km_en_2': ('[warm] 10K done. Getting here is skill, not luck.', *DEFAULT_VS),
    'tts_marathon_10km_en_3': ('[calm] 10K. Your legs feel heavy. That\'s normal. Keep going.', *DEFAULT_VS),
    'tts_marathon_10km_en_4': ('[stern] 10K. Even pros check pace here. Check yours too.', *DEFAULT_VS),
    # 15km
    'tts_marathon_15km_en_1': ('[stern] 15K. Don\'t forget hydration. If you\'re thirsty, you\'re already late.', *DEFAULT_VS),
    'tts_marathon_15km_en_2': ('[warm] 15K. Not many run this far. Be proud.', *DEFAULT_VS),
    'tts_marathon_15km_en_3': ('[commanding] 15K. Engage your core. A wobbly torso wastes energy.', *DEFAULT_VS),
    'tts_marathon_15km_en_4': ('[calm] 15K cleared. The marathon wall is still ahead. Enjoy this.', *DEFAULT_VS),
    # 20km
    'tts_marathon_20km_en_1': ('[warm] 20K. Half marathon distance. You\'re already a great runner.', *DEFAULT_VS),
    'tts_marathon_20km_en_2': ('[commanding] 20K. From here, mind leads body. Don\'t give up.', *DEFAULT_VS),
    'tts_marathon_20km_en_3': ('[stern] 20K. Glycogen is running low. Consider refueling.', *DEFAULT_VS),
    'tts_marathon_20km_en_4': ('[excited] 20K done. Legends are made right here.', *DEFAULT_VS),
}

# ==========================================
# E. 마라토너 - 페이스별 (4상황 × 4변형)
# ==========================================
MARATHON_PACE = {
    # 아주 빠름
    'tts_pace_fast_1': ('[excited] 미쳤어, 오늘 날아다니고 있어.', *DEFAULT_VS),
    'tts_pace_fast_2': ('[excited] 이 페이스 실화냐? 역대급이다.', *DEFAULT_VS),
    'tts_pace_fast_3': ('[warm] 지금 너 최고의 날이야. 기억해둬.', *DEFAULT_VS),
    'tts_pace_fast_4': ('[commanding] 엔진이 완전히 걸렸어. 그대로 가.', *DEFAULT_VS),
    # 좋은 페이스
    'tts_pace_good_1': ('[calm] 안정적이야. 이 리듬 유지해.', *DEFAULT_VS),
    'tts_pace_good_2': ('[warm] 좋은 페이스야. 몸이 기억하고 있어.', *DEFAULT_VS),
    'tts_pace_good_3': ('[calm] 딱 좋아. 무리하지 말고 이대로.', *DEFAULT_VS),
    'tts_pace_good_4': ('[warm] 꾸준함이 실력이야. 잘하고 있어.', *DEFAULT_VS),
    # 느려지고 있음
    'tts_pace_slow_1': ('[stern] 페이스 떨어지고 있어. 보폭을 줄여봐.', *DEFAULT_VS),
    'tts_pace_slow_2': ('[commanding] 느려지고 있다. 팔을 더 써봐.', *DEFAULT_VS),
    'tts_pace_slow_3': ('[stern] 지금이 고비야. 여기서 버텨.', *DEFAULT_VS),
    'tts_pace_slow_4': ('[calm] 힘들지? 호흡부터 다시 잡아.', *DEFAULT_VS),
    # 많이 느림
    'tts_pace_veryslow_1': ('[stern] 멈추지 마. 느려도 뛰고 있으면 된다.', *DEFAULT_VS),
    'tts_pace_veryslow_2': ('[commanding] 걷고 싶지? 30초만 더 버텨봐.', *DEFAULT_VS),
    'tts_pace_veryslow_3': ('[stern] 포기는 없어. 한 발만 더 내밀어.', *DEFAULT_VS),
    'tts_pace_veryslow_4': ('[commanding] 느린 게 부끄러운 게 아니야. 멈추는 게 부끄러운 거야.', *DEFAULT_VS),
}
MARATHON_PACE_EN = {
    # 아주 빠름
    'tts_pace_fast_en_1': ('[excited] You\'re flying today. Unreal.', *DEFAULT_VS),
    'tts_pace_fast_en_2': ('[excited] Is this pace for real? This is historic.', *DEFAULT_VS),
    'tts_pace_fast_en_3': ('[warm] This is your best day. Remember it.', *DEFAULT_VS),
    'tts_pace_fast_en_4': ('[commanding] Engine\'s fully fired up. Keep it.', *DEFAULT_VS),
    # 좋은 페이스
    'tts_pace_good_en_1': ('[calm] Steady. Hold this rhythm.', *DEFAULT_VS),
    'tts_pace_good_en_2': ('[warm] Good pace. Your body remembers.', *DEFAULT_VS),
    'tts_pace_good_en_3': ('[calm] Perfect. Don\'t push, just maintain.', *DEFAULT_VS),
    'tts_pace_good_en_4': ('[warm] Consistency is skill. You\'re doing well.', *DEFAULT_VS),
    # 느려지고 있음
    'tts_pace_slow_en_1': ('[stern] Pace is dropping. Try shorter strides.', *DEFAULT_VS),
    'tts_pace_slow_en_2': ('[commanding] You\'re slowing. Use your arms more.', *DEFAULT_VS),
    'tts_pace_slow_en_3': ('[stern] This is the wall. Push through.', *DEFAULT_VS),
    'tts_pace_slow_en_4': ('[calm] Tough? Reset your breathing first.', *DEFAULT_VS),
    # 많이 느림
    'tts_pace_veryslow_en_1': ('[stern] Don\'t stop. Slow is still running.', *DEFAULT_VS),
    'tts_pace_veryslow_en_2': ('[commanding] Want to walk? Give me 30 more seconds.', *DEFAULT_VS),
    'tts_pace_veryslow_en_3': ('[stern] No quitting. One more step.', *DEFAULT_VS),
    'tts_pace_veryslow_en_4': ('[commanding] Slow isn\'t shameful. Stopping is.', *DEFAULT_VS),
}

# ==========================================
# F. 마라토너 - 종료 (6변형)
# ==========================================
MARATHON_END = {
    'tts_marathon_end_1': ('[warm] 수고했다. 오늘 뛴 만큼 내일 더 강해진다. 스트레칭 잊지 마.', *DEFAULT_VS),
    'tts_marathon_end_2': ('[commanding] 끝까지 완주했다. 이게 진짜 실력이야.', *DEFAULT_VS),
    'tts_marathon_end_3': ('[stern] 잘 뛰었어. 쿨다운 5분, 스트레칭 10분. 회복이 훈련이야.', *DEFAULT_VS),
    'tts_marathon_end_4': ('[warm] 대단해. 오늘 네 몸이 한 단계 올라갔어.', *DEFAULT_VS),
    'tts_marathon_end_5': ('[stern] 수고했어. 단백질 30분 안에 섭취해. 근회복에 중요해.', *DEFAULT_VS),
    'tts_marathon_end_6': ('[friendly] 오늘도 해냈군. 내일 또 보자.', *DEFAULT_VS),
}
MARATHON_END_EN = {
    'tts_marathon_end_en_1': ('[warm] Good work. Every run makes you stronger. Don\'t skip the stretch.', *DEFAULT_VS),
    'tts_marathon_end_en_2': ('[commanding] You finished the whole thing. That\'s real strength.', *DEFAULT_VS),
    'tts_marathon_end_en_3': ('[stern] Good run. 5 minutes cooldown, 10 minutes stretching. Recovery is training.', *DEFAULT_VS),
    'tts_marathon_end_en_4': ('[warm] Impressive. Your body leveled up today.', *DEFAULT_VS),
    'tts_marathon_end_en_5': ('[stern] Good work. Get protein within 30 minutes. Key for muscle recovery.', *DEFAULT_VS),
    'tts_marathon_end_en_6': ('[friendly] You did it again. See you tomorrow.', *DEFAULT_VS),
}

# ==========================================
# G. 도플갱어 - 앞서고 있을 때 (3단계)
# ==========================================
SHADOW_AHEAD = {
    'tts_ahead_close': ('[whispers] 그림자가 뒤처지고 있어... 하지만 아직 가까워.', 0.3, 0.85, 0.6),
    'tts_ahead_mid': ('[calm] 그림자가 멀어지고 있어. 이 페이스 유지해.', 0.5, 0.8, 0.4),
    'tts_ahead_far': ('[excited] 완전히 따돌렸어. 새 기록이다, 계속 가!', 0.6, 0.8, 0.5),
}
SHADOW_AHEAD_EN = {
    'tts_ahead_close_en': ('[whispers] The shadow\'s falling behind... but it\'s still close.', 0.3, 0.85, 0.6),
    'tts_ahead_mid_en': ('[calm] The shadow is fading. Hold this pace.', 0.5, 0.8, 0.4),
    'tts_ahead_far_en': ('[excited] You\'ve left it behind. New record, keep going!', 0.6, 0.8, 0.5),
}

# ==========================================
# H. 도플갱어 - 전환 (앞서다 → 다시 쫓김)
# ==========================================
SHADOW_TRANSITION = {
    'tts_losing_lead': ('[urgent] 그림자가 다시 다가온다. 속도 올려.', 0.25, 0.85, 0.7),
}
SHADOW_TRANSITION_EN = {
    'tts_losing_lead_en': ('[urgent] The shadow is catching up again. Pick it up.', 0.25, 0.85, 0.7),
}

# ==========================================
# I. 도플갱어 - 패배
# ==========================================
SHADOW_DEFEATED = {
    'tts_defeated': ('[deadpan] 패배했습니다.', 0.7, 0.8, 0.2),
}
SHADOW_DEFEATED_EN = {
    'tts_defeated_en': ('[deadpan] You lost.', 0.7, 0.8, 0.2),
}

# ==========================================
# J. 기존 TTS 영어 추가 (누락분)
# ==========================================
EXISTING_EN = {
    'tts_start_en': ('[calm] Starting your run. The shadow awakens.', 0.5, 0.8, 0.4),
    'tts_warning2_en': ('[urgent] Footsteps behind you. Speed up.', 0.25, 0.85, 0.7),
    'tts_danger2_en': ('[whispers] Can you feel it... right behind you... [heavy breathing]', 0.15, 0.9, 0.9),
    'tts_survived_en': ('[relieved] You survived. You win today.', 0.5, 0.8, 0.3),
}

# ==========================================
# 전체 합치기
# ==========================================

# 3음성 모두 생성하는 그룹
ALL_THREE_VOICES = {}
ALL_THREE_VOICES.update(SOLO_START)
ALL_THREE_VOICES.update(SOLO_START_EN)
ALL_THREE_VOICES.update(SOLO_END)
ALL_THREE_VOICES.update(SOLO_END_EN)
ALL_THREE_VOICES.update(MARATHON_START)
ALL_THREE_VOICES.update(MARATHON_START_EN)
ALL_THREE_VOICES.update(MARATHON_KM)
ALL_THREE_VOICES.update(MARATHON_KM_EN)
ALL_THREE_VOICES.update(MARATHON_PACE)
ALL_THREE_VOICES.update(MARATHON_PACE_EN)
ALL_THREE_VOICES.update(MARATHON_END)
ALL_THREE_VOICES.update(MARATHON_END_EN)
ALL_THREE_VOICES.update(SHADOW_AHEAD)
ALL_THREE_VOICES.update(SHADOW_AHEAD_EN)
ALL_THREE_VOICES.update(SHADOW_TRANSITION)
ALL_THREE_VOICES.update(SHADOW_TRANSITION_EN)
ALL_THREE_VOICES.update(SHADOW_DEFEATED)
ALL_THREE_VOICES.update(SHADOW_DEFEATED_EN)
ALL_THREE_VOICES.update(EXISTING_EN)

os.makedirs(OUTDIR, exist_ok=True)

def get_filename(base_name, voice_key):
    if voice_key == 'harry':
        return f'{base_name}.mp3'
    else:
        return f'{base_name}_{voice_key}.mp3'

def generate_one(base_name, text, stability, similarity, style, voice_key, voice_id):
    filename = get_filename(base_name, voice_key)
    filepath = os.path.join(OUTDIR, filename)

    # 이미 존재하면 스킵
    if os.path.exists(filepath):
        print(f'  SKIP (exists): {filename}')
        return True

    url = f'https://api.elevenlabs.io/v1/text-to-speech/{voice_id}'

    # 언어 감지
    lang = 'en' if '_en' in base_name or any(c.isascii() and c.isalpha() for c in text.split(']')[-1][:10]) else 'ko'

    body = json.dumps({
        'text': text,
        'model_id': MODEL,
        'language_code': lang,
        'voice_settings': {
            'stability': stability,
            'similarity_boost': similarity,
            'style': style,
            'speed': 0.9,
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
            size_kb = len(data) / 1024
            print(f'  OK: {filename} ({size_kb:.1f}KB)')
            return True
    except urllib.error.HTTPError as e:
        error_body = e.read().decode('utf-8')
        print(f'  FAIL: {filename} - {e.code} - {error_body}')
        return False

def main():
    total = 0
    success = 0
    fail = 0
    skip = 0

    for base_name, (text, stability, similarity, style) in ALL_THREE_VOICES.items():
        for voice_key, voice_id in VOICES.items():
            total += 1
            filename = get_filename(base_name, voice_key)
            filepath = os.path.join(OUTDIR, filename)

            if os.path.exists(filepath):
                skip += 1
                print(f'  SKIP: {filename}')
                continue

            ok = generate_one(base_name, text, stability, similarity, style, voice_key, voice_id)
            if ok:
                success += 1
            else:
                fail += 1

            # API 레이트 리밋 방지
            time.sleep(0.3)

    print(f'\n========================================')
    print(f'총: {total} | 성공: {success} | 실패: {fail} | 스킵: {skip}')
    print(f'========================================')

if __name__ == '__main__':
    main()
