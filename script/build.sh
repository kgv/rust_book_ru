#!/bin/sh

REV=$(git rev-parse --short HEAD)

sed "s/<revision>/$REV/g" README.rev.template.md >> README.md

rustbook build
