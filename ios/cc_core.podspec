Pod::Spec.new do |s|
  s.name             = 'cc_core'
  s.version          = '0.31.0'
  s.summary          = 'Code Cowboys shared core: Suite Link (iOS).'
  s.description      = 'Suite Link on iOS: an App Group inbox for the quiet feed, same-team URL handoffs for Send / Log this in, and back-links.'
  s.homepage         = 'https://code-cowboys.com'
  s.license          = { :type => 'Proprietary', :file => '../LICENSE' }
  s.author           = { 'Code Cowboys LLC' => 'hello@code-cowboys.com' }
  s.source           = { :path => '.' }
  s.swift_version    = '5.0'
  s.source_files     = 'cc_core/Sources/cc_core/**/*.swift'
  s.dependency 'Flutter'
  s.platform         = :ios, '13.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
