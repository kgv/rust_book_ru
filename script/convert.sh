#!/bin/sh

ROOT=$(pwd)
BOOK_DIR=${ROOT}/_book
CONVERTED_DIR=${BOOK_DIR}/converted

mkdir -p $CONVERTED_DIR
cd $BOOK_DIR
cp ${ROOT}/static/css/rust-book-pdf.min.css rust-book.css

parallel ::: "${ROOT}/script/convert-epub.sh" \
         "${ROOT}/script/convert-mobi.sh" \
         "${ROOT}/script/convert-pdf.sh"

cd $ROOT
