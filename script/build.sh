#!/bin/sh

REV=$(git rev-parse --short HEAD)

sed "s/<revision>/$REV/g" README.rev.template.md >> README.md

rustbook build

sed -i "s/@import url('..\/rust.css');/@import url('.\/rust.css');/g" _book/rustbook.css
sed -i "s/<script src='rustbook.js'><\/script>/<script src='..\/rustbook.js'><\/script>/g" $(find _book/src -type f)
sed -i "s/<script src='playpen.js'><\/script>/<script src='..\/playpen.js'><\/script>/g" $(find _book/src -type f)
cp static/css/rust.css _book
