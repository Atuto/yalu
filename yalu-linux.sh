#!/bin/bash

### Initial vars ###

SCRIPTPATH=`dirname $0`
ddi="$(find $SCRIPTPATH 2> /dev/null | grep "8.4/.*.dmg$" || echo './data/DeveloperDiskImage.dmg' | head -1)"

cd $SCRIPTPATH

### Functions ###

function abort()
{
  echo "Error.  Exiting..." > &2
  exit 1;
}


### DDI mount function ###

function mount_ddi()
{
  echo "Mounting DDI..."
  ./bin/ideviceimagemounter_lin "$ddi" > /dev/null || echo "Couldn't mount DDI.  Did you put it in the right place?"
}

### Device detection function ###

function wait_for_device()
{
  echo "Waiting for device..."
  while ! (./bin/afcclient_lin deviceinfo | grep -q FSTotalBytes); do sleep 5; printf "."; done 2> /dev/null
}

### Jailbreak Functions ###
# Stage 1:
# Set up environment, install app, and swap binaries

function stage1()
{
  echo "Setting up environment..."

  ./bin/afcclient_lin put ./data/WWDC_Info_TOC.plist /yalu.plist | grep Uploaded || abort

  echo "Installing app and swapping binaries..."

  ideviceinstaller --install ./data/WWDC-TOCTOU.ipa || abort

  echo "Please wait..."

  sleep 5
  ./bin/afcclient_lin put ./data/WWDC_Info_TOU.plist /yalu.plist | grep Uploaded || abort

  echo
}

# Stage 0:
# Important stuff

function stage0()
{
  echo "Please disable Find My iPhone before continuing."
  # Waiting for device
  wait_for_device

  echo "Recreating temp directory..."
  rm -rf tmp
  mkdir tmp

  (
  echo "Creating directories on device..." > &2
  ./bin/afcclient_lin mkdir PhotoData/KimJongCracks
  ./bin/afcclient_lin mkdir PhotoData/KimJongCracks/a
  ./bin/afcclient_lin mkdir PhotoData/KimJongCracks/a/a
  ./bin/afcclient_lin mkdir PhotoData/KimJongCracks/Library
  ./bin/afcclient_lin mkdir PhotoData/KimJongCracks/Library/PrivateFrameworks
  ./bin/afcclient_lin mkdir PhotoData/KimJongCracks/Library/PrivateFrameworks/GPUToolsCore.framework

  # Stage 1
  stage1 || abort

  # Backup device data

  echo "Backing up, this could take several minutes..." > &2
  ./bin/idevicebackup2_lin backup tmp || abort
  udid="$(ls tmp | head -1)"

  echo "Mounting DDI and copying files to backup directory..." > &2

  mkdir tmp_ddi
  dmg2img -i $ddi -o ./tmp/DeveloperDiskImage.dmg
  mount -t hfsplus -o loop,ro ./tmp/DeveloperDiskImage.dmg ./tmp_ddi
  cp tmp_ddi/Applications/MobileReplayer.app/MobileReplayer tmp/MobileReplayer
  cp tmp_ddi/Applications/MobileReplayer.app/Info.plist tmp/MobileReplayerInfo.plist
  umount ./tmp_ddi
  rm -rf tmp_ddi

  echo "Compiling and copying binary file to device..." > &2

  ./bin/lipo_lin tmp/MobileReplayer -thin armv7s -output ./tmp/MobileReplayer
  ./bin/mbdbtool tmp $udid CameraRollDomain rm Media/PhotoData/KimJongCracks/a/a/MobileReplayer
  ./bin/mbdbtool tmp $udid CameraRollDomain put ./tmp/MobileReplayer Media/PhotoData/KimJongCracks/a/a/MobileReplayer || abort
  )

  # Restore modified backup
  echo "Restoring modified backup..."
  (
  ./bin/idevicebackup2_lin restore tmp --system --reboot || abort
  ) > /dev/null

  # ZZZZZZ...
  echo "Sleeping until device reboot..."
  sleep 20

  # Wait for device
  wait_for_device
  read -p "Press [Enter] key when your device finishes restoring."
  echo

  # Mount DDI
  mount_ddi

  echo "Fetching symbols..."
  # TODO: Actually, well, fetch symbols

  echo "Compiling jailbreak files..."
  cd tmp
  $SCRIPTPATH./bin/lipo -info dyld.fat | grep arm64 > /dev/null && $SCRIPTPATH./bin/lipo dyld.fat -thin arm64 -output dyld64
  $SCRIPTPATH./bin/lipo -info dyld.fat | grep Non-fat > /dev/null || ($SCRIPTPATH./bin/lipo dyld.fat -thin "$(../bin/lipo -info dyld.fat | tr ' ' '\n' | grep v7)" -output dyld; mv dyld dyld.fat) && mv dyld.fat dyld
  $SCRIPTPATH./bin/jtool_lin -e IOKit cache
  $SCRIPTPATH./bin/jtool_lin -e libsystem_kernel.dylib cache
  $SCRIPTPATH./bin/lipo -info dyld64 | grep arm64 > /dev/null && (
  $SCRIPTPATH./bin/jtool_lin -e libdyld.dylib cache64
  cd $SCRIPTPATH./data/dyldmagic_amfid
  ./make.#!/bin/sh
  cd ../..
  )
  cd $SCRIPTPATH./data/dyldmagic
  ./make.#!/bin/sh

  echo "Copying files to device..."
  cd ../..
  ./bin/afcclient_lin put ./data/dyldmagic/magic.dylib PhotoData/KimJongCracks/Library/PrivateFrameworks/GPUToolsCore.framework/GPUToolsCore
  ./bin/afcclient_lin put ./data/untether/untether drugs
  gunzip -c ./data/bootstrap.tgz > ./tmp/bootstrap.tar
  ./bin/afcclient_lin put ./tmp/bootstrap.tar PhotoData/KimJongCracks/bootstrap.tar
  ./bin/afcclient_lin put ./data/tar PhotoData/KimJongCracks/tar

  echo "Tap on the jailbreak icon to crash the kernel (or 0wn it if you're in luck!)"
}

# Let's do this!
stage0 || abort

exit 0
