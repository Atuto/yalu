#!/bin/bash

SCRIPTPATH=`pwd`
cd $SCRIPTPATH

echo "Compiling MALoader..."
cd $SCRIPTPATH/maloader
make
echo $SCRIPTPATH

cd $SCRIPTPATH
cd $SCRIPTPATH/data/xcode
./extract_xcode.sh
cd ../..
