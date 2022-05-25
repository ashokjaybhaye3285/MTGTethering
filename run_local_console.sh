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
read -p "Does this look right? y/n " -n 1 -r
echo 
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

BUILD=1
while [[ $# > 0 ]]
do
key="$1"

case $key in
    --nobuild)
    BUILD=0
    shift # past argument
    ;;
    *)
            # unknown option
    ;;
esac
shift # past argument or value
done

if [ $BUILD = 1 ]
then
    echo "Building the local stuff"
    cd "MTGTethering"
    bundle install
    cd ..
    rake calabash_install[$DEVICE_TARGET]
    rake sim_install[$SIM_DEVICE_TARGET]
fi

cd "MTGTethering"
echo "Starting the console"
echo "  To launch the app in the console, execute:"
echo "    start_test_server_in_background"
bundle exec calabash-ios console