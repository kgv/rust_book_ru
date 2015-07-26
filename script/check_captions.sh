#!/usr/bin/env zsh
# Warning: this script should be sourced, not executed

msort -w -l <(for f in $(find src -name '*.md'); do head -n 1 $f | perl -ne '/^% (.*?)$/ && print "$1\n"' ; done) 2>/dev/null > captions_in_md
msort -l -w <(cat SUMMARY.md | perl -ne '/\[([\w(), `!-]+)/ && print "$1\n"') 2>/dev/null > captions_in_summary
nohup meld captions_in_md captions_in_summary &
