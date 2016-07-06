#!/bin/sh

SAVED_PWD=$(pwd)
export RUSTBOOK=$HOME/rustbook; echo "INFO:RUSTBOOK: $RUSTBOOK"

if [ ! -f "$RUSTBOOK"/target/release/rustbook ]; then
    git clone https://github.com/steveklabnik/rustbook $RUSTBOOK
    cd $RUSTBOOK
    git checkout e19eebb99443a6bf3f88e3f4e6b1dd21d3f3bf05
    cargo build --release
    cd $SAVED_PWD
else
    echo "Using cached $RUSTBOOK"
fi

export PATH=$PATH:$RUSTBOOK/target/release; echo "INFO:PATH: $PATH"
