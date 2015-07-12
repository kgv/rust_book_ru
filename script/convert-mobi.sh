#!/bin/sh

BOOK_DIR=$(pwd)
CONVERTED_DIR=${BOOK_DIR}/converted

ebook-convert \
    README.html \
    "${CONVERTED_DIR}/rustbook.mobi" \
    --cover="../cover.jpg" \
    --title="Язык программирования Rust" \
    --comments="" \
    --language="ru" \
    --book-producer="" \
    --publisher="" \
    --chapter="//h:h1[@class='title']" \
    --chapter-mark="pagebreak" \
    --page-breaks-before="/" \
    --level1-toc="//h:h1[@class='title']" \
    --no-chapters-in-toc \
    --max-levels="1" \
    --breadth-first
