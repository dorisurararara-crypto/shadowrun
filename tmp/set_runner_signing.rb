#!/usr/bin/env ruby
# Runner 타겟에 DEVELOPMENT_TEAM + CODE_SIGN_STYLE 설정 (Watch 타겟과 동일).
# Archive/TestFlight 업로드 시 서명 자동 진행되도록.

GEMS = '/opt/homebrew/Cellar/cocoapods/1.16.2_2/libexec/gems'
Dir["#{GEMS}/*/lib"].each { |p| $LOAD_PATH.unshift(p) }
require 'xcodeproj'

TEAM_ID = 'Q6H9HCTK6W'

proj = Xcodeproj::Project.open('/Users/pc/shadow/ios/Runner.xcodeproj')
runner = proj.targets.find { |t| t.name == 'Runner' } or abort 'Runner not found'

runner.build_configurations.each do |c|
  s = c.build_settings
  s['DEVELOPMENT_TEAM'] = TEAM_ID
  s['CODE_SIGN_STYLE'] = 'Automatic'
  puts "#{c.name}: Team=#{s['DEVELOPMENT_TEAM']}, Style=#{s['CODE_SIGN_STYLE']}"
end

proj.save
puts 'saved.'
