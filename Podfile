platform :ios, '14.0'

inhibit_all_warnings!
use_modular_headers!

target 'memo' do
  pod 'FSCalendar'
  pod 'R.swift'
  pod 'Reveal-SDK', :configurations => ['Debug']

  target 'memo-tests' do
    pod 'R.swift'
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
    end
  end
end