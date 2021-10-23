# A Living Review of Interactive Theorem Provers

This is a repository with all the code for Sam Nolan's 2021 Honours thesis: A
Living Review of Interactive Theorem Provers.

`itp_widget` contains the source code for the widget. Written with the help of Elm, Typescript and Vega-Lite

`index.md` contains the actual thesis in pandoc markdown form.

`compile.py` Runs mustache over the top of the `index.md` for templating, then
passes it to pandoc to compile to HTML.

`math_crawlers` contains all the crawlers used to index the libraries.
