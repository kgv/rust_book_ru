#!/usr/bin/env python

import glob
import logging
import re

logging.basicConfig(level=logging.DEBUG)

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
                line = line.rstrip("\n")
                results.append({
                    "line_number": index,
                    "line_string": line,
                })
    return results

# Check check line width.
def check_line_width(file):
    results = []
    with open(file, "r") as input:
        for index, line in enumerate(input):
            line = line.rstrip("\n")
            length = len(unicode(line,'utf-8'))
            if length > 80:
                results.append({
                    "line_number": index,
                    "line_string": line,
                    "line_width": length,
                })
    return results

print("")
logging.info("check relative links")
for file in glob.glob("./src/*.md"):
    results = check_relative_links(file)
    if results:
        logging.warning("check relative links: error, file: {}, count: {}".format(file, len(results)))
        for result in results:
            logging.debug("relative link error: line number: {line_number}, line: {line_string}".format(**result))
    else:
        logging.info("check relative links: ok, file: {}".format(file))

print("")
logging.info("check broken width")
for file in glob.glob("./src/*.md"):
    results = check_broken_links(file)
    if results:
        logging.warning("check broken links: error, file: {}, count: {}".format(file, len(results)))
        for result in results:
            logging.debug("broken link error: line number: {line_number}, line: {line_string}".format(**result))
    else:
        logging.info("check broken links: ok, file: {}".format(file))

print("")
logging.info("check line width")
for file in glob.glob("./src/*.md"):
    results = check_line_width(file)
    if results:
        logging.warning("check line width: error, file: {}, count: {}".format(file, len(results)))
        for result in results:
            logging.debug("line width error: line number: {line_number}, line width: {line_width}, line: {line_string}".format(**result))
    else:
        logging.info("check line width: ok, file: {}".format(file))
