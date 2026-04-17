#!/usr/bin/env ruby
# 특정 빌드를 외부 TestFlight 그룹에 할당 + Beta App Review 제출
# 사용: scripts/asc/submit_external_beta.rb [build_number]
#   build_number 생략 시 가장 최근 빌드 자동 선택

require_relative '_helpers'

EXTERNAL_GROUP_ID = '24a71662-f507-4276-8774-8c0a506006ce' # ganzitester (external)

# 빌드 번호 결정
target_version = ARGV[0]
if target_version
  c,b = api(:get, "/v1/builds?filter[app]=#{APP_ID}&filter[version]=#{target_version}&filter[preReleaseVersion.version]=1.0.0")
else
  c,b = api(:get, "/v1/builds?filter[app]=#{APP_ID}&filter[preReleaseVersion.version]=1.0.0&sort=-version&limit=1")
end
abort "build fetch fail: HTTP #{c}\n#{b[0..300]}" unless c == '200'
build = JSON.parse(b)['data'].first
abort "build 없음" unless build
build_id = build['id']
version = build['attributes']['version']
state = build['attributes']['processingState']
puts "타겟 빌드: v1.0.0+#{version}  id=#{build_id}  processing=#{state}"

unless state == 'VALID'
  puts "⚠️  빌드 처리 미완료 (state=#{state}). Apple 처리 끝날 때까지 기다린 후 다시 실행."
  exit 1
end

# 외부 그룹 할당 (멱등)
puts "\n=== 외부 그룹 할당 ==="
c,b = api(:post, "/v1/builds/#{build_id}/relationships/betaGroups",
  { data: [{ type: 'betaGroups', id: EXTERNAL_GROUP_ID }] })
puts "HTTP #{c}"
if c == '422' && b.include?('already')
  puts "  (이미 할당됨, skip)"
elsif !c.start_with?('2')
  puts b[0..400]
end

# Beta App Review 제출 (멱등 — 이미 제출됐으면 409)
puts "\n=== Beta App Review 제출 ==="
c,b = api(:post, '/v1/betaAppReviewSubmissions',
  { data: { type: 'betaAppReviewSubmissions',
            relationships: { build: { data: { type: 'builds', id: build_id } } } } })
puts "HTTP #{c}"
if c == '409'
  puts "  (이미 제출됨 or 이미 승인됨)"
  # 현재 상태 조회
  c2,b2 = api(:get, "/v1/builds/#{build_id}/betaAppReviewSubmission")
  if c2 == '200' && JSON.parse(b2)['data']
    puts "  current state: #{JSON.parse(b2)['data']['attributes']['betaReviewState']}"
  end
elsif c.start_with?('2')
  puts "  제출 성공"
else
  puts b[0..400]
end

puts "\n심사 대기. 첫 빌드는 24h 안팎, 이후 빌드는 대부분 빠르게 승인."
puts "상태 조회: scripts/asc/check_build_status.rb #{version}"
