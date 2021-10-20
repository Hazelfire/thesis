#!/usr/bin/env bash
inotifywait -e close_write -m . |
while read -r directory events filename; do
  if [ "$filename" = "compile.py" ]; then
    ./buildweb.sh
  fi
  if [ "$filename" = "index.md" ]; then
    ./buildweb.sh
  fi
done
