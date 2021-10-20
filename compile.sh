#!/usr/bin/env fish
node compile.js
pandoc index.md --filter pandoc-crossref --citeproc --bibliography references.bib -o index.pdf
pandoc --template mytemplate.tex --toc -F pandoc-csv2table -F pandoc-crossref  --listings -C index.md -o index.tex
pandoc --template mytemplate.md --toc -F pandoc-csv2table -F pandoc-crossref  --mathjax -C index.md -o index.html
