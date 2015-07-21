#!/bin/sh

BOOK_DIR=$(pwd)
CONVERTED_DIR=${BOOK_DIR}/converted

ebook-convert \
    README.html \
    "${CONVERTED_DIR}/rustbook.pdf" \
    --cover="../cover.jpg" \
    --title="Язык программирования Rust" \
    --comments="" \
    --language="ru" \
    --book-producer="" \
    --publisher="" \
    --chapter="//h:h1[@class='title']" \
    --chapter-mark="none" \
    --page-breaks-before="/" \
    --level1-toc="//h:h1[@class='title']" \
    --no-chapters-in-toc \
    --max-levels="1" \
    --breadth-first \
    --margin-left="62" \
    --margin-right="62" \
    --margin-top="56" \
    --margin-bottom="56" \
    --pdf-default-font-size="16" \
    --pdf-mono-font-size="16" \
    --paper-size="a4" \
    --pdf-header-template="<p class='header'><span>Язык программирования Rust</span></p>" \
    --pdf-footer-template="<p class='footer'><span>_SECTION_</span> <span style='float:right;'>_PAGENUM_</span></p>"
