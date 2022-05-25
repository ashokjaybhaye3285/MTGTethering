#
# Be sure to run `pod lib lint JDMTGTethering.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

ver_num = '#VER_NUM#'

Pod::Spec.new do |s|
  s.name             = 'JDMTGTethering'
  s.version          = ver_num.start_with?('#') ? '1.1' : ver_num
  s.summary          = 'An interface to configure an MTG 4G LTE\'s Wi-Fi connection via Bluetooth LE.'
  s.frameworks       = ['UIKit', 'Foundation', 'CoreBluetooth']
  s.homepage         = 'https://github.deere.com/MobileSDK/Tethering-iOS'
  s.license          = 'Deere Internal'
  s.author           = 'Deere'
  s.source           = { :git => 'git@github.deere.com:MobileSDK/Tethering-iOS.git', :tag => s.version.to_s }


  s.ios.deployment_target = '9.0'

  s.source_files = '{MTGTethering/JDMTGTethering,CommonBluetooth}/**/*.{swift,h,m}'

  s.resources = 'MTGTethering/JDMTGTethering/**/*.{storyboard,xib,strings}'

  s.dependency 'MBProgressHUD', '~> 0.9.0'
end
