#!/bin/sh

ROOT=$(pwd)
BOOK_DIR=${ROOT}/_book
REV=$(git rev-parse --short HEAD)

cd $BOOK_DIR
cp ${ROOT}/static/css/rust-book.min.css rustbook.css
sed -i "s/@import url('..\/rust.css');/@import url('.\/rust.css');/g" rustbook.css

git init
git config user.name "travis-ci.org"
git config user.email "travis-ci.org@users.noreply.github.com"

git remote add upstream "https://${GH_PAGES}@github.com/ruRust/rust_book_ru.git"
git fetch upstream
git reset upstream/gh-pages

touch .

git add -A .

git commit -m "rebuild pages at $REV"
git push -q upstream HEAD:gh-pages

cd $ROOT
