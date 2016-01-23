#!/bin/sh

REV=$(git rev-parse --short HEAD)

sed "s/<revision>/$REV/g" README.rev.template.md >> README.md

cp static/css/rust.css .

rustbook build
