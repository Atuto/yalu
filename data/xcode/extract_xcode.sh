#!/bin/bash

# XCode extraction tool

SCRIPTPATH=`dirname $0`
cd $SCRIPTPATH

if [ ! -f ./XCode.dmg ]; then
  echo "Cannot find XCode.dmg, did you put in the right place?"
  exit 1
fi

echo "Extracting XCode..."
dmg2img XCode.dmg XCode.img -p 5
mkdir xcode_tmp
mount -t hfsplus -o loop,ro XCode.img xcode_tmp
echo "Done!"
echo "Copying XCode contents..."
cp -r xcode_tmp/Xcode.app/* .
umount xcode_tmp
rmdir xcode_tmp
rm XCode.img

cp ./Contents/Developer/Platforms/iPhoneOS.platform/DeviceSupport/8.4/DeveloperDiskImage.dmg ..

echo "Done!"
