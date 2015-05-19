#!/bin/bash

rev=$(git rev-parse --short HEAD)

ROOT=$(pwd)

cd _book

cp ${ROOT}/additions/rust-book.min.css rust-book.css

git init
git config user.name "Travis CI"
git config user.email ""
git remote add upstream "https://${GH_TOKEN}@github.com/kgv/rust_book_ru.git"
git fetch upstream && git reset upstream/gh-pages

touch .

git add -A .

git commit -m "rebuild pages at ${rev}"
git push -q upstream HEAD:gh-pages
