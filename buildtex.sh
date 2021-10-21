#!/usr/bin/env fish
echo "Creating Template"
python compile.py latex
echo "Recompiling"
pandoc --from markdown+pipe_tables --template mytemplate.tex --toc -F pandoc-csv2table -F pandoc-crossref  --mathjax -C build.tex.md -o index.tex
