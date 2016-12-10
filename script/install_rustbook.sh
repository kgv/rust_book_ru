#!/bin/sh

SAVED_PWD=$(pwd)
export RUSTBOOK=$HOME/rustbook; echo "INFO:RUSTBOOK: $RUSTBOOK"

if [ ! -f "$RUSTBOOK"/target/release/rustbook ]; then
    git clone https://github.com/mkpankov/rustbook $RUSTBOOK
    cd $RUSTBOOK
    git checkout 3c83f12cb55b3e90873df7f97812cacca15e985f
    cargo build --release
    cd $SAVED_PWD
else
    echo "Using cached $RUSTBOOK"
fi

export PATH=$PATH:$RUSTBOOK/target/release; echo "INFO:PATH: $PATH"
