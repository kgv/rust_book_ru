#!/bin/sh

SAVED_PWD=$(pwd)
export RUSTBOOK=$HOME/rustbook; echo "INFO:RUSTBOOK: $RUSTBOOK"

if [ ! -f "$RUSTBOOK"/target/release/rustbook ]; then
    git clone https://github.com/mkpankov/rustbook $RUSTBOOK
    cd $RUSTBOOK
    git checkout 402f5017ce79eb5e208539352678ded7b65ac527
    cargo build --release
    cd $SAVED_PWD
else
    echo "Using cached $RUSTBOOK"
fi

export PATH=$PATH:$RUSTBOOK/target/release; echo "INFO:PATH: $PATH"
