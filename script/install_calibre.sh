#!/bin/sh

ROOT=$(pwd)
export CALIBRE=$ROOT/calibre; echo "INFO:CALIBRE: $CALIBRE"

HARDWARE_PLATFORM_BIT=$(getconf LONG_BIT)
URL=https://code.calibre-ebook.com/dist/linux${HARDWARE_PLATFORM_BIT}
# https://raw.githubusercontent.com/kovidgoyal/calibre/master/setup/linux-installer.py

# Check hardware platform bit valid.
if [ $HARDWARE_PLATFORM_BIT -ne 32 ] && [ $HARDWARE_PLATFORM_BIT -ne 64 ]; then
    echo "ERROR:hardware platform bit: $HARDWARE_PLATFORM_BIT"
    exit -1
fi

mkdir -p $CALIBRE
cd $CALIBRE
curl -sf -L -k --retry 8 --retry-delay 1 $URL | tar -Jxv
cd $ROOT

export PATH=$PATH:$CALIBRE; echo "INFO:PATH: $PATH"