#!/bin/bash

ROOT=$(pwd)
BUILD_DIR="${ROOT}/_book"
BIN_BOOK="${BUILD_DIR}/converted"

cd ${BUILD_DIR}

mkdir -p $BIN_BOOK

cp ${ROOT}/additions/rust-book-pdf.min.css rust-book.css

ebook-convert --version

ebook-convert \
	README.html \
	"${BIN_BOOK}/rustbook.epub" \
	--cover="../cover.jpg" \
	--title="Язык программирования Rust" \
	--comments="" \
	--language="ru" \
	--book-producer="" \
	--publisher="" \
	--chapter="descendant-or-self::*[contains(concat(' ', normalize-space(@class), ' '), ' book-chapter ')]" \
	--chapter-mark="pagebreak" \
	--page-breaks-before="/" \
	--level1-toc="descendant-or-self::*[contains(concat(' ', normalize-space(@class), ' '), ' book-chapter-1 ')]" \
	--level2-toc="descendant-or-self::*[contains(concat(' ', normalize-space(@class), ' '), ' book-chapter-2 ')]" \
	--level3-toc="descendant-or-self::*[contains(concat(' ', normalize-space(@class), ' '), ' book-chapter-3 ')]" \
	--no-chapters-in-toc \
	--max-levels="1" \
	--breadth-first \
	--dont-split-on-page-breaks

ebook-convert \
	README.html \
	"${BIN_BOOK}/rustbook.mobi" \
	--cover="../cover.jpg" \
	--title="Язык программирования Rust" \
	--comments="" \
	--language="ru" \
	--book-producer="" \
	--publisher="" \
	--chapter="descendant-or-self::*[contains(concat(' ', normalize-space(@class), ' '), ' book-chapter ')]" \
	--chapter-mark="pagebreak" \
	--page-breaks-before="/" \
	--level1-toc="descendant-or-self::*[contains(concat(' ', normalize-space(@class), ' '), ' book-chapter-1 ')]" \
	--level2-toc="descendant-or-self::*[contains(concat(' ', normalize-space(@class), ' '), ' book-chapter-2 ')]" \
	--level3-toc="descendant-or-self::*[contains(concat(' ', normalize-space(@class), ' '), ' book-chapter-3 ')]" \
	--no-chapters-in-toc \
	--max-levels="1" \
	--breadth-first

ebook-convert \
	README.html \
	"${BIN_BOOK}/rustbook.pdf" \
	--cover="../cover.jpg" \
	--title="Язык программирования Rust" \
	--comments="" \
	--language="ru" \
	--book-producer="" \
	--publisher="" \
	--chapter="descendant-or-self::*[contains(concat(' ', normalize-space(@class), ' '), ' book-chapter ')]" \
	--chapter-mark="pagebreak" \
	--page-breaks-before="/" \
	--level1-toc="descendant-or-self::*[contains(concat(' ', normalize-space(@class), ' '), ' book-chapter-1 ')]" \
	--level2-toc="descendant-or-self::*[contains(concat(' ', normalize-space(@class), ' '), ' book-chapter-2 ')]" \
	--level3-toc="descendant-or-self::*[contains(concat(' ', normalize-space(@class), ' '), ' book-chapter-3 ')]" \
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
