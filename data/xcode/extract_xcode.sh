#!/bin/bash

# XCode extraction tool

SCRIPTPATH=`dirname $0`
cd $SCRIPTPATH

if [ ! -f ./XCode.dmg ]; then
  echo "Cannot find XCode.dmg, did you put in the right place?"
  exit 1
fi

dmg2img XCode.dmg XCode.img
mkdir xcode_tmp
mount -t hfsplus -o loop,ro XCode.img xcode_tmp
cp -r xcode_tmp/* .
umount xcode_tmp

cp ./Contents/Platforms/iPhoneOS.platform/DeviceSupport/8.4/DeveloperDiskImage.dmg ..

echo "Extracted!"
