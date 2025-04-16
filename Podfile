source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '13.0'

inhibit_all_warnings!

target 'mapcache-ios' do
  pod 'geopackage-ios', '~> 8.0.6'
  pod 'mgrs-ios', '~> 1.1.6'
#  pod 'gars-ios', '~> 1.1.5'
  pod 'gars-ios', :path => '~/Development/NGA/gars-ios'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    puts "Configuring Swift version for #{target.name}"
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '5.0'
    end
  end
end



