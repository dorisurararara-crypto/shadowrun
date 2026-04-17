# 공통 ASC API 헬퍼 (다른 스크립트에서 require)
GEMS='/opt/homebrew/Cellar/cocoapods/1.16.2_2/libexec/gems'
Dir["#{GEMS}/*/lib"].each { |p| $LOAD_PATH.unshift(p) }
require 'openssl'; require 'base64'; require 'json'; require 'net/http'; require 'uri'

KEY_ID='KQ46867WUN'; ISSUER_ID='5269abe3-03f1-46a9-a37c-35d950758714'
KEY_PATH = File.expand_path("~/.appstoreconnect/private_keys/AuthKey_#{KEY_ID}.p8")
APP_ID='6762060466'
PK = OpenSSL::PKey::EC.new(File.read(KEY_PATH))

def jwt_token
  h={alg:'ES256',kid:KEY_ID,typ:'JWT'}; p={iss:ISSUER_ID,iat:Time.now.to_i,exp:Time.now.to_i+1200,aud:'appstoreconnect-v1'}
  si="#{Base64.urlsafe_encode64(h.to_json,padding:false)}.#{Base64.urlsafe_encode64(p.to_json,padding:false)}"
  sig=PK.dsa_sign_asn1(OpenSSL::Digest::SHA256.new.digest(si))
  a=OpenSSL::ASN1.decode(sig)
  r=a.value[0].value.to_s(2).rjust(32,"\x00".b); s=a.value[1].value.to_s(2).rjust(32,"\x00".b)
  "#{si}.#{Base64.urlsafe_encode64(r+s,padding:false)}"
end

def api(method, path, body=nil)
  u = URI("https://api.appstoreconnect.apple.com#{path}")
  r = case method
      when :get then Net::HTTP::Get.new(u)
      when :post then Net::HTTP::Post.new(u).tap{|x|x.body=body.to_json;x['Content-Type']='application/json'}
      when :patch then Net::HTTP::Patch.new(u).tap{|x|x.body=body.to_json;x['Content-Type']='application/json'}
      when :delete then Net::HTTP::Delete.new(u)
      end
  r['Authorization']="Bearer #{jwt_token}"
  h=Net::HTTP.new(u.host,u.port); h.use_ssl=true
  res=h.request(r); [res.code, res.body]
end
