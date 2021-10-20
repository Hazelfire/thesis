#!/usr/bin/env fish
echo "Creating Template"
python compile.py html
echo "Recompiling"
pandoc --from markdown+pipe_tables --template mytemplate.md --toc -F pandoc-csv2table -F pandoc-crossref  --mathjax -C build.html.md -o index.html
