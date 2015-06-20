#!/bin/sh

ROOT=$(pwd)
export RUSTBOOK=$ROOT/rustbook; echo "INFO:RUSTBOOK: $RUSTBOOK"

git clone https://github.com/steveklabnik/rustbook $RUSTBOOK
cd $RUSTBOOK
git checkout 6718cda
cargo build --release
cd $ROOT

export PATH=$PATH:$RUSTBOOK/target/release; echo "INFO:PATH: $PATH"
