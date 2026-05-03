#!/usr/bin/env python3
# Reads $BLOCK_FILE and injects its contents into STATUS.md (in CWD)
# between the BEGIN: ci-today / END: ci-today markers. If the markers
# don't exist yet, prepends a new "Today's CI" h2 right after the
# first H1 line. Exit 42 if STATUS.md is already up-to-date.
#
# Used by update-repo-status.sh — kept as its own file so the bash
# script doesn't have to bash-interpolate arbitrary content into a
# python heredoc (block content includes backticks, brackets, pipes,
# could later include quote characters).

import os
import pathlib
import re
import sys

block = pathlib.Path(os.environ['BLOCK_FILE']).read_text().strip()
path = pathlib.Path('STATUS.md')
src = path.read_text()

BEGIN = '<!-- BEGIN: ci-today -->'
END = '<!-- END: ci-today -->'

if BEGIN in src and END in src:
    new = re.sub(
        re.escape(BEGIN) + r'\n.*?\n' + re.escape(END),
        BEGIN + '\n' + block + '\n' + END,
        src,
        count=1,
        flags=re.S,
    )
else:
    # Insert a fresh "Today's CI" h2 right after the first H1 line.
    # Picked the position because every STATUS.md in the org follows
    # the "# Title \n one-line summary \n ## first section" shape, so
    # the "Today" block lands above the human-curated TL;DR — that's
    # the order an agent doing a morning triage wants to read.
    section = (
        '\n## Today’s CI\n\n'
        + BEGIN + '\n'
        + block + '\n'
        + END + '\n'
    )
    lines = src.splitlines(keepends=True)
    insert_at = 0
    for i, line in enumerate(lines):
        if line.startswith('# '):
            insert_at = i + 1
            break
    if insert_at < len(lines) and lines[insert_at].strip() == '':
        insert_at += 1
    new = ''.join(lines[:insert_at]) + section + ''.join(lines[insert_at:])

repo = os.environ.get('REPO_NAME', '?')
if new == src:
    print(f'[{repo}] no change')
    sys.exit(42)
path.write_text(new)
print(f'[{repo}] updated')
