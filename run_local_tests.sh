
# Run the following to fix this error: "shell_session_update: command not found"
#rvm get head

####################

# Run the following if there are issues deploying builds to devices.
# This is necessary sometimes after updating iTunes and perhaps other Mac software related to connecting to devices.

#brew uninstall ideviceinstaller
#brew uninstall libimobiledevice
#brew install --HEAD libimobiledevice
#brew unlink libimobiledevice
#brew link libimobiledevice
#brew install ideviceinstaller
#brew unlink ideviceinstaller
#brew link ideviceinstaller

####################

#!/bin/bash
echo "Starting script"
export SIM_DEVICE_TARGET=2961309c7c5b7d68083dd1448bc328f9ffb9f97f
echo "SIM_DEVICE_TARGET=$SIM_DEVICE_TARGET"
export DEVICE_TARGET=649fb0d4f4eeba4b25a31f66fb3142b1c7a385ed
echo "DEVICE_TARGET=$DEVICE_TARGET"
export DEVICE_ENDPOINT=http://192.168.1.109:37265
echo "DEVICE_ENDPOINT=$DEVICE_ENDPOINT"
export BUNDLE_ID=com.deere.MTGTetheringDemo
echo "BUNDLE_ID=$BUNDLE_ID"
export APP=../MTGTethering.xcarchive/Products/Applications/MTGTetheringDemo.app/
echo "APP=$APP"


BUILD=1
FEATURE_COMING=0
FEATURES_LIST=""
while [[ $# > 0 ]]
do
key="$1"

case $key in
    --nobuild)
    BUILD=0
    echo "NOBUILD"
    ;;
    --feature)
	FEATURE_COMING=1
	;;
    *)
    if [ $FEATURE_COMING = 1 ]
    then
    	FEATURES_LIST="$FEATURES_LIST ./features/$key"
    	echo "FEATURES_LIST=$FEATURES_LIST"
	fi
	FEATURE_COMING=0
    ;;
esac
shift # past argument or value
done


read -p "Does this look right? y/n " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
exit 1
fi

if [ $BUILD = 1 ]
then
    rm -r -f Build
    echo "Building the local stuff"
    cd "MTGTethering"
    rm -r -f Build
    bundle install
    cd ..
    rake calabash_install[$DEVICE_TARGET]
    rake sim_install[$SIM_DEVICE_TARGET]
fi

cd "MTGTethering"
echo "Starting the tests"
echo "bundle exec cucumber -p ios $FEATURES_LIST"
bundle exec cucumber -p ios $FEATURES_LIST