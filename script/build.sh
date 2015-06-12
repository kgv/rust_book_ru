#!/bin/sh

REV=$(git rev-parse --short HEAD)

rustbook build
