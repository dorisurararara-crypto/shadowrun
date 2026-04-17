#!/usr/bin/env ruby
# TestFlight 빌드 상태 조회. 사용: scripts/check_build_status.rb [build_number]

GEMS='/opt/homebrew/Cellar/cocoapods/1.16.2_2/libexec/gems'
Dir["#{GEMS}/*/lib"].each { |p| $LOAD_PATH.unshift(p) }
require 'openssl'; require 'base64'; require 'json'; require 'net/http'; require 'uri'

KEY_ID='KQ46867WUN'
ISSUER_ID='5269abe3-03f1-46a9-a37c-35d950758714'
APP_ID='6762060466'
KEY_PATH = File.expand_path("~/.appstoreconnect/private_keys/AuthKey_#{KEY_ID}.p8")

private_key = OpenSSL::PKey::EC.new(File.read(KEY_PATH))
h={alg:'ES256',kid:KEY_ID,typ:'JWT'}
p={iss:ISSUER_ID,iat:Time.now.to_i,exp:Time.now.to_i+1200,aud:'appstoreconnect-v1'}
si = "#{Base64.urlsafe_encode64(h.to_json,padding:false)}.#{Base64.urlsafe_encode64(p.to_json,padding:false)}"
sig = private_key.dsa_sign_asn1(OpenSSL::Digest::SHA256.new.digest(si))
a = OpenSSL::ASN1.decode(sig)
r = a.value[0].value.to_s(2).rjust(32,"\x00".b)
s = a.value[1].value.to_s(2).rjust(32,"\x00".b)
jwt = "#{si}.#{Base64.urlsafe_encode64(r+s,padding:false)}"

version_filter = ARGV[0] ? "&filter[version]=#{ARGV[0]}" : ''
uri = URI("https://api.appstoreconnect.apple.com/v1/builds?filter[app]=#{APP_ID}&filter[preReleaseVersion.version]=1.0.0#{version_filter}&sort=-version&limit=10")
req = Net::HTTP::Get.new(uri); req['Authorization'] = "Bearer #{jwt}"
http = Net::HTTP.new(uri.host, uri.port); http.use_ssl = true
res = http.request(req)

abort "HTTP #{res.code}: #{res.body}" unless res.code == '200'
data = JSON.parse(res.body)['data']
if data.empty?
  puts "빌드 없음"; exit 0
end
puts "%-6s %-18s %-18s %s" % ['build', 'state', 'expiration', 'uploaded']
data.each do |b|
  a = b['attributes']
  puts "%-6s %-18s %-18s %s" % [a['version'], a['processingState'], a['expired']?'EXPIRED':'valid', a['uploadedDate']]
end
