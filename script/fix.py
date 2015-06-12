#!/usr/bin/env python

import glob
import logging
import tempfile
import os

logging.basicConfig(level=logging.INFO)

# Fix first line markdown header marker "#" -> "%".
def fix_header(file):
    result = False
    tmp = tempfile.NamedTemporaryFile(dir='.', delete=False).name
    with open(tmp, "w") as output, open(file, "r") as input:
        for index, line in enumerate(input):
            if index == 0 and line.startswith("#"):
                line = line.replace("#", "%", 1)
                result = True
            output.write(line)
    os.rename(tmp, file)
    return result

for file in glob.glob("./*.md"):
    fixs = {}
    result = fix_header(file)
    fixs["fix_header"] = result

    if fixs["fix_header"]:
        logging.info("fix header ok: file: {}, fix header: {}".format(file, fixs["fix_header"]))
