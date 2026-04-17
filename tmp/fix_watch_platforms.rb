#!/usr/bin/env ruby
# Watch App 타겟이 iphoneos SDK 로 잘못 빌드되는 문제 해결:
# SUPPORTED_PLATFORMS 명시 → xcodebuild 가 Watch 를 watchos SDK 로 컴파일.

GEMS = '/opt/homebrew/Cellar/cocoapods/1.16.2_2/libexec/gems'
Dir["#{GEMS}/*/lib"].each { |p| $LOAD_PATH.unshift(p) }
require 'xcodeproj'

proj = Xcodeproj::Project.open('ios/Runner.xcodeproj')
watch = proj.targets.find { |t| t.name == 'ShadowRunWatch Watch App' } or abort 'Watch target not found'

watch.build_configurations.each do |c|
  s = c.build_settings
  s['SUPPORTED_PLATFORMS'] = 'watchos watchsimulator'
  s['SDKROOT'] = 'watchos'
  puts "#{c.name}: SUPPORTED_PLATFORMS=#{s['SUPPORTED_PLATFORMS']}, SDKROOT=#{s['SDKROOT']}"
end

proj.save
puts 'saved.'
