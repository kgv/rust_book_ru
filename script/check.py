#!/usr/bin/env python

import glob
import logging
import re

logging.basicConfig(level=logging.INFO)

# Check links contains "../".
def check_relative_links(file):
    regex = re.compile("\[[^]]+\]\(\.\./[^)]*\)")
    results = []
    with open(file, "r") as input:
        for index, line in enumerate(input):
            result = regex.search(line)
            if result != None:
                results.append({
                    "line_number": index,
                    "line_string": line.strip(),
                })
    return results

# Check links contains "\n".
def check_broken_links(file):
    regex = re.compile("\[[^]]+\]\([^)]*[\n|$]")
    results = []
    with open(file, "r") as input:
        for index, line in enumerate(input):
            result = regex.search(line)
            if result != None:
                results.append({
                    "line_number": index,
                    "line_string": line.strip(),
                })
    return results

# Check check line width.
def check_line_width(file):
    results = []
    with open(file, "r") as input:
        for index, line in enumerate(input):
            if len(line) > 81:
                results.append({
                    "line_number": index,
                    "line_string": line.strip(),
                    "line_width": len(line),
                })
    return results

for file in glob.glob("./src/*.md"):
    checks = {}
    results = check_relative_links(file)
    checks["relative_links"] = results
    results = check_broken_links(file)
    checks["broken_links"] = results
    results = check_line_width(file)
    checks["line_width"] = results

    if checks["relative_links"] or checks["broken_links"] or checks["line_width"]:
        logging.warning("check error: file: {}, relative links: {}, broken links: {}, line width: {}".format(file, len(checks["relative_links"]), len(checks["broken_links"]), len(checks["line_width"])))
        if checks["relative_links"]:
            for result in checks["relative_links"]:
                logging.debug("relative link error: line number: {line_number}, line: {line_string}".format(**result))

        if checks["broken_links"]:
            for result in checks["broken_links"]:
                logging.debug("broken link error: line number: {line_number}, line: {line_string}".format(**result))

        if checks["line_width"]:
            for result in checks["line_width"]:
                logging.debug("line width error: line number: {line_number}, line width: {line_width}, line: {line_string}".format(**result))
    else:
        logging.info("check ok: file: {}".format(file))
