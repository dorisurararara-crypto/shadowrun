#!/usr/bin/env ruby
# Runner 에 ShadowRunWatch Watch App 을 companion 으로 임베드하도록 pbxproj 수정.
# - Watch App: WKWatchOnly 제거, WKCompanionAppBundleIdentifier 추가, bundle ID 를 Runner 하위로 변경
# - Runner: Embed Watch Content 빌드 페이즈 추가 + Watch App 타겟 dependency

GEMS = '/opt/homebrew/Cellar/cocoapods/1.16.2_2/libexec/gems'
Dir["#{GEMS}/*/lib"].each { |p| $LOAD_PATH.unshift(p) }
require 'xcodeproj'

IPHONE_BUNDLE_ID = 'com.ganziman.shadowrun'
NEW_WATCH_BUNDLE_ID = 'com.ganziman.shadowrun.watchkitapp'

proj = Xcodeproj::Project.open('ios/Runner.xcodeproj')
runner = proj.targets.find { |t| t.name == 'Runner' } or abort 'Runner target not found'
watch = proj.targets.find { |t| t.name == 'ShadowRunWatch Watch App' } or abort 'Watch target not found'
watch_product = watch.product_reference or abort 'Watch product_reference not found'

puts "=== Watch App settings ==="
watch.build_configurations.each do |c|
  s = c.build_settings
  s.delete('INFOPLIST_KEY_WKWatchOnly')
  s['INFOPLIST_KEY_WKCompanionAppBundleIdentifier'] = IPHONE_BUNDLE_ID
  s['PRODUCT_BUNDLE_IDENTIFIER'] = NEW_WATCH_BUNDLE_ID
  puts "  #{c.name}: bundle=#{s['PRODUCT_BUNDLE_IDENTIFIER']}, companion=#{s['INFOPLIST_KEY_WKCompanionAppBundleIdentifier']}, watchOnly=#{s['INFOPLIST_KEY_WKWatchOnly'] || '(removed)'}"
end

puts "\n=== Runner dependency on Watch App ==="
already_dep = runner.dependencies.any? { |d| d.target_proxy&.remote_global_id_string == watch.uuid }
if already_dep
  puts "  already present"
else
  runner.add_dependency(watch)
  puts "  added"
end

puts "\n=== Runner 'Embed Watch Content' build phase ==="
embed_phase = runner.copy_files_build_phases.find { |p| p.name == 'Embed Watch Content' }
if embed_phase
  puts "  phase already exists"
else
  embed_phase = runner.new_copy_files_build_phase('Embed Watch Content')
  embed_phase.dst_subfolder_spec = '16'  # Products Directory relative
  embed_phase.dst_path = '$(CONTENTS_FOLDER_PATH)/Watch'
  puts "  phase created"
end

already_embedded = embed_phase.files.any? { |bf| bf.file_ref == watch_product }
if already_embedded
  puts "  Watch App.app already in phase"
else
  build_file = embed_phase.add_file_reference(watch_product)
  build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
  puts "  Watch App.app added to phase"
end

proj.save
puts "\npbxproj saved."
