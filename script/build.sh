#!/bin/sh

REV=$(git rev-parse --short HEAD)

sed "s/<revision>/$REV/g" README.rev.template.md >> README.md

rustbook build

sed -i "s/@import url('..\/rust.css');/@import url('.\/rust.css');/g" _book/rustbook.css
cp static/css/rust.css _book
