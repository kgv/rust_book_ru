#!/bin/sh

SAVED_PWD=$(pwd)
export RUSTBOOK=$HOME/rustbook; echo "INFO:RUSTBOOK: $RUSTBOOK"

if [ ! -f "$RUSTBOOK"/target/release/rustbook ]; then
    git clone https://github.com/mkpankov/rustbook $RUSTBOOK
    cd $RUSTBOOK
    git checkout b3a2973a27a260dd47131d9ebec9d73007c4d407
    cargo build --release
    cd $SAVED_PWD
else
    echo "Using cached $RUSTBOOK"
fi

export PATH=$PATH:$RUSTBOOK/target/release; echo "INFO:PATH: $PATH"
