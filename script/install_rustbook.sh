#!/bin/sh

git clone https://github.com/steveklabnik/rustbook $RUSTBOOK
cd $RUSTBOOK
git checkout eb96cc8
cargo build --release
cd $ROOT
