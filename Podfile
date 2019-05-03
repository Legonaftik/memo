platform :ios, '12.2'

inhibit_all_warnings!
use_modular_headers!

target 'memo' do
  pod 'R.swift'
  pod 'FSCalendar'
  pod 'Firebase/Core'
  pod 'FirebaseUI'
  pod 'FirebaseUI/Auth'
  pod 'FirebaseUI/Google'
end

post_install do |installer|
  installer.aggregate_targets.each do |aggregate_target|
    aggregate_target.xcconfigs.each do |config_name, config_file|
      config_file.other_linker_flags[:frameworks].delete("TwitterCore")

      xcconfig_path = aggregate_target.xcconfig_path(config_name)
      config_file.save_as(xcconfig_path)
    end
  end
end