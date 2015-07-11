#!/bin/sh

SAVED_PWD=$(pwd)
export RUSTBOOK=$HOME/rustbook; echo "INFO:RUSTBOOK: $RUSTBOOK"

if [ ! -f "$RUSTBOOK"/target/release/rustbook ]; then
    git clone https://github.com/steveklabnik/rustbook $RUSTBOOK
    cd $RUSTBOOK
    git checkout 6718cda7fea65d830f6271bd4ae1a66ca5dbc81c
    cargo build --release
    cd $SAVED_PWD
else
    echo "Using cached $RUSTBOOK"
fi

export PATH=$PATH:$RUSTBOOK/target/release; echo "INFO:PATH: $PATH"
