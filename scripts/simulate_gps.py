"""에뮬레이터에서 GPX 경로를 시뮬레이션하는 스크립트"""
import subprocess, time, xml.etree.ElementTree as ET, os

ADB = os.path.join(os.environ['LOCALAPPDATA'], 'Android', 'Sdk', 'platform-tools', 'adb.exe')
GPX = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'test_route.gpx')

tree = ET.parse(GPX)
ns = {'gpx': 'http://www.topografix.com/GPX/1/1'}
points = tree.findall('.//gpx:trkpt', ns)

print(f'총 {len(points)}개 GPS 포인트 로드')
print('GPS 시뮬레이션 시작 (Ctrl+C로 중단)')

# 첫 포인트를 먼저 여러 번 보내서 GPS 안정화
first = points[0]
lat, lon = first.get('lat'), first.get('lon')
print(f'GPS 안정화 중... ({lat}, {lon})')
for _ in range(5):
    subprocess.run([ADB, 'emu', 'geo', 'fix', lon, lat, '10'], capture_output=True)
    time.sleep(0.5)

print('안정화 완료. 3초 후 이동 시작...')
time.sleep(3)

for i, pt in enumerate(points):
    lat, lon = pt.get('lat'), pt.get('lon')
    result = subprocess.run([ADB, 'emu', 'geo', 'fix', lon, lat, '10'], capture_output=True, text=True)
    status = 'OK' if 'OK' in result.stdout else 'FAIL'
    print(f'[{i+1}/{len(points)}] lat={lat} lon={lon} → {status}')
    time.sleep(2)  # 2초 간격으로 이동 (러닝 속도 시뮬레이션)

print('\nGPS 시뮬레이션 완료!')
