Pod::Spec.new do |s|
  s.name             = 'app_branding'
  s.version          = '0.0.1'
  s.summary          = 'App Branding Plugin for T&T POS'
  s.description      = 'App Branding Plugin for T&T POS iOS'
  s.homepage         = 'https://tgdtbanhang.netlify.app'
  s.license          = { :type => 'MIT' }
  s.author           = { 'T&T POS' => 'thegioidienthoai464@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
