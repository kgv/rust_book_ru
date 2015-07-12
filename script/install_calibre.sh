#!/bin/sh

SAVED_PWD=$(pwd)
export CALIBRE=$HOME/calibre; echo "INFO:CALIBRE: $CALIBRE"

HARDWARE_PLATFORM_BIT=$(getconf LONG_BIT)
URL=https://code.calibre-ebook.com/dist/linux${HARDWARE_PLATFORM_BIT}
# https://raw.githubusercontent.com/kovidgoyal/calibre/master/setup/linux-installer.py

# Check hardware platform bit valid.
if [ $HARDWARE_PLATFORM_BIT -ne 32 ] && [ $HARDWARE_PLATFORM_BIT -ne 64 ]; then
    echo "ERROR:hardware platform bit: $HARDWARE_PLATFORM_BIT"
    exit -1
fi

if [ ! -f "$CALIBRE"/ebook-convert ]; then
    mkdir -p $CALIBRE
    cd $CALIBRE
    until RESULT=$(curl -sf -L -k $URL | tar -Jxv); do
        echo "ERROR:download calibre: error."
        sleep 1
    done; echo "$RESULT"
    cd $SAVED_PWD
else
    echo "Using cached $CALIBRE"
fi

export PATH=$PATH:$CALIBRE; echo "INFO:PATH: $PATH"
