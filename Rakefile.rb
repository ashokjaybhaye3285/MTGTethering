require 'shellwords' # Needed for bash function


# Run commands in bash instead of sh
def bash(command)
  
    escaped_command = Shellwords.escape(command)
    system "bash --login -c #{escaped_command}"

end

task :default => [:unit]

task :clean do
  
    #Kill the sim
    bash('killall "Simulator"')

    #Reset the simulator
    bash('xcrun simctl erase all')

end

task :setup => [:clean] do

    # TODO: Do we need bundle install and pod install?
    bash('rvm use 2.2.3') # && bundle install && bundle exec pod install')
  
end

task :unit => [:setup] do
  
    object_root = "OBJROOT=Build"
    derivedData = "-derivedDataPath Build"
    workspace = "-workspace MTGTethering.xcworkspace"
    scheme = "-scheme JDMTGTetheringTests"
    simulator_to_use = "-destination \'platform=iOS Simulator,name=iPhone 6s,OS=9.2\'"
    enable_cov = "-enableCodeCoverage YES"
    sdk = "-sdk iphonesimulator9.2"
    build_config = "-configuration Debug"

    bash("xcodebuild #{object_root} #{derivedData} #{workspace} #{scheme} #{simulator_to_use} #{enable_cov} #{sdk} #{build_config} clean build test | ocunit2junit")

end

task :calabash_build do
    
    object_root = "OBJROOT=Build"
    derivedData = "-derivedDataPath Build"
    workspace = "-workspace MTGTethering/MTGTethering.xcworkspace"
    scheme = "-scheme Calabash"
    build_config = "-configuration Calabash"
    archive_path = "-archivePath MTGTethering.xcarchive"
    swift_build = "EMBEDDED_CONTENT_CONTAINS_SWIFT=YES"

    bash("xcodebuild #{swift_build} #{object_root} #{derivedData} #{workspace} #{scheme} #{build_config} #{archive_path} clean archive")

end

app_path = 'MTGTethering.xcarchive/Products/Applications/MTGTetheringDemo.app/'

task :calabash_install, [:udid] => [:calabash_build] do |t, args|
    debug = '-d'
    uninstall = '-U'
    install = '-i'
    # udid = '-u 649fb0d4f4eeba4b25a31f66fb3142b1c7a385ed'
    udid = "-u #{args[:udid]}"
    app_id = 'com.deere.MTGTetheringDemo'
    
    bash("ideviceinstaller #{debug} #{udid} #{uninstall} #{app_id}")
    bash("ideviceinstaller #{debug} #{udid} #{install} #{app_path}")
end


task :calabash_run => [:calabash_install] do
    bundle = 'export BUNDLE_ID=com.deere.MTGTetheringDemo'
    device_target = 'export DEVICE_TARGET=649fb0d4f4eeba4b25a31f66fb3142b1c7a385ed'
    endpoint = 'export DEVICE_ENDPOINT=http://192.168.1.109:37265'
    app = "export APP="
    bash("#{bundle} && #{device_target} && #{endpoint} && #{app}#{app_path} && cd MTGTethering && pwd && DEBUG=1 bundle exec cucumber -p ios -f pretty -f json -o cucumber.json")

end

task :archive do
    
    object_root = "OBJROOT=Build"
    derivedData = "-derivedDataPath Build"
    workspace = "-workspace MTGTethering.xcworkspace"
    scheme = "-scheme MTGTetheringDemo"
    build_config = "-configuration Release"
    archive_path = "-archivePath MTGTethering.xcarchive"
    swift_build = "EMBEDDED_CONTENT_CONTAINS_SWIFT=YES"

    bash("xcodebuild #{swift_build} #{object_root} #{derivedData} #{workspace} #{scheme} #{build_config} #{archive_path} clean archive")

end

task :export do

    export_archive = "-exportArchive"
    archive_path = "-archivePath MTGTethering.xcarchive"
    export_path = "-exportPath"
    ipa_name = "MTGTetheringDemo.1.0.ipa"
    export_plist = "-exportOptionsPlist exportInhousePlist.plist" 

    bash("rm -rf #{ipa_name}")
    bash("rvm use system && sleep 5 && xcodebuild #{export_archive} #{archive_path} #{export_path} #{ipa_name} #{export_plist}")

end

task :deploy do

    crashlytics_api_key = "21fe68621dc5760ff66f2a9359d72319b95420fd"
    crashlytics_build_secret = "90a4c93430a993c823f2b305a3b021738963cc900e93c303d2e7d66e4509a236"

    ipa_path = "-ipaPath MTGTetheringDemo.1.0.ipa/*.ipa"
    debug_yes = "-debug YES"
    group_aliases = "-groupAliases apputation,isg-internal-test,jdmtgtethering-dev"

    bash("MTGTethering/Crashlytics.framework/submit #{crashlytics_api_key} #{crashlytics_build_secret} #{ipa_path} #{debug_yes} #{group_aliases}")

end

task :archive_sim do
    
    object_root = "OBJROOT=Build"
    derivedData = "-derivedDataPath Build"
    workspace = "-project YukonSim/YukonSim.xcodeproj"
    scheme = "-scheme YukonSim"
    build_config = "-configuration Release"
    archive_path = "-archivePath YukonSim.xcarchive"
    swift_build = "EMBEDDED_CONTENT_CONTAINS_SWIFT=YES"

    bash("xcodebuild #{swift_build} #{object_root} #{derivedData} #{workspace} #{scheme} #{build_config} #{archive_path} clean archive")

end

sim_path = 'YukonSim.xcarchive/Products/Applications/YukonSim.app/'

task :sim_install, [:udid] => [:archive_sim] do |t, args|
    debug = '-d'
    uninstall = '-U'
    install = '-i'
    udid = "-u #{args[:udid]}"
    # udid = '-u 2961309c7c5b7d68083dd1448bc328f9ffb9f97f'
    app_id = 'com.deere.YukonSim'
    
    bash("ideviceinstaller #{debug} #{udid} #{uninstall} #{app_id}")
    bash("ideviceinstaller #{debug} #{udid} #{install} #{sim_path}")
end
