import re, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

with open(r'C:\Users\pc\AppData\Local\Temp\naver_post.html', 'r', encoding='utf-8', errors='ignore') as f:
    html = f.read()

# 먼저 se-main-container 위치 찾기
start = html.find('se-main-container')
if start < 0:
    print("NO se-main-container")
    sys.exit(1)

body = html[start:]

# se-component 단위로 순서대로 추출
# 패턴: <div class="se-component se-XXX ...">...</div>
# 각 컴포넌트는 class에 'se-image', 'se-text', 'se-video' 등을 가짐
comps = re.findall(r'<div[^>]+class="[^"]*se-component\s+se-(\w+)[^"]*"[^>]*>(.*?)(?=<div[^>]+class="[^"]*se-component\s+se-\w+|<div[^>]+class="area_sympathy"|</body>)', body, re.DOTALL)

print(f"Found {len(comps)} components\n")

outputs = []
img_urls = []
img_idx = 0

for ctype, content in comps:
    if ctype in ('image','imageStrip','imageGroup'):
        # 모든 img 태그 수집
        imgs = re.findall(r'<img[^>]+>', content)
        for imgtag in imgs:
            # 가장 큰 src 찾기
            m_url = re.search(r'data-lazy-src="(https://postfiles\.pstatic\.net/[^"]+)"', imgtag)
            if not m_url:
                m_url = re.search(r'src="(https://postfiles\.pstatic\.net/[^"]+)"', imgtag)
            if m_url:
                url = m_url.group(1)
                if 'w80_blur' in url:
                    continue
                url_big = re.sub(r'type=w\d+(_blur)?', 'type=w966', url)
                img_idx += 1
                img_urls.append((img_idx, url_big))
        # 캡션
        m_cap = re.search(r'class="se-caption[^"]*"[^>]*>(.*?)</(?:span|div|p)>', content, re.DOTALL)
        cap = ''
        if m_cap:
            cap = re.sub(r'<[^>]+>', '', m_cap.group(1)).strip()
        if cap or img_idx:
            outputs.append(f'[IMG #{img_idx:02d}]' + (f' cap: {cap}' if cap else ''))
    elif ctype in ('text','quotation','textHeader','header'):
        t = content
        t = re.sub(r'<br\s*/?>', '\n', t)
        t = re.sub(r'</p>|</div>', '\n', t)
        t = re.sub(r'<[^>]+>', '', t)
        t = re.sub(r'&nbsp;', ' ', t)
        t = re.sub(r'&amp;', '&', t)
        t = re.sub(r'&lt;', '<', t)
        t = re.sub(r'&gt;', '>', t)
        t = re.sub(r'&quot;', '"', t)
        t = re.sub(r'\u200b', '', t)
        t = re.sub(r'[ \t]+', ' ', t)
        t = re.sub(r'\n\s*\n+', '\n', t)
        t = t.strip()
        if t:
            outputs.append(f'[TEXT] {t}')
    elif ctype == 'video':
        m_url = re.search(r'src="(https://mblogvideo-phinf[^"]+)"', content)
        if m_url:
            outputs.append(f'[VIDEO] {m_url.group(1).split("/")[-1].split("?")[0]}')
    elif ctype == 'horizontalLine':
        outputs.append('---')
    elif ctype == 'sticker':
        outputs.append('[STICKER]')
    elif ctype in ('oglink','link'):
        m_url = re.search(r'href="([^"]+)"', content)
        if m_url:
            outputs.append(f'[LINK] {m_url.group(1)}')
    else:
        outputs.append(f'[{ctype.upper()}]')

print('=' * 60)
print('PARSED BODY (순서대로)')
print('=' * 60)
for line in outputs:
    print(line)

print()
print('=' * 60)
print(f'IMAGE URLS ({len(img_urls)} total)')
print('=' * 60)
for idx, url in img_urls:
    print(f'{idx:02d}\t{url}')

with open(r'C:\Users\pc\AppData\Local\Temp\naver_imgs.txt', 'w', encoding='utf-8') as f:
    for idx, url in img_urls:
        f.write(f'{idx}\t{url}\n')
