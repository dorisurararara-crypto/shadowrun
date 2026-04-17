#!/usr/bin/env ruby
# Embed Watch Content 페이즈를 마지막 → "Embed Frameworks" 바로 뒤로 이동.
# 현재 위치(마지막)는 [CP] scripts 뒤라 Xcode dependency cycle 을 만든다.

GEMS = '/opt/homebrew/Cellar/cocoapods/1.16.2_2/libexec/gems'
Dir["#{GEMS}/*/lib"].each { |p| $LOAD_PATH.unshift(p) }
require 'xcodeproj'

proj = Xcodeproj::Project.open('/Users/pc/shadow/ios/Runner.xcodeproj')
runner = proj.targets.find { |t| t.name == 'Runner' } or abort 'Runner target not found'

phases = runner.build_phases
embed_watch = phases.find { |p| p.display_name == 'Embed Watch Content' } or abort 'Embed Watch Content phase not found'
embed_frameworks_idx = phases.index { |p| p.display_name == 'Embed Frameworks' } or abort 'Embed Frameworks not found'

# remove and reinsert right after Embed Frameworks
phases.delete(embed_watch)
phases.insert(embed_frameworks_idx + 1, embed_watch)

puts 'New Runner phase order:'
phases.each_with_index { |p, i| puts "  #{i}: #{p.display_name}" }

proj.save
puts 'saved.'
