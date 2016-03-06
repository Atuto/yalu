#!/bin/bash

SCRIPTPATH=`dirname $0`
cd $SCRIPTPATH
rm -f magic.dylib

DYLD_BSS="$(../../bin/jtool_lin -l ../cache/cache.libdyld.dylib | grep __bss | head -c 16 | tail -c 10)"
