from bs4 import BeautifulSoup
import requests
import csv
import bibtexparser
from pylatexenc.latex2text import LatexNodes2Text

source = requests.get('https://fm.mizar.org/fm.bib')
rows = []
categories = set()
bib_database = bibtexparser.loads(source.text)
decoder = LatexNodes2Text()
for entry in bib_database.entries:
    print(entry)
    if entry['ENTRYTYPE'].lower() == 'ARTICLE'.lower():
        url = ""
        if 'url' in entry:
            url = entry['url']
        else:
            url = 'http://mizar.org/version/current/html/{}.html'.format(entry['ID'].lower().split(".abs")[0])
        description = ""
        if 'summary' in entry:
            description = entry['summary']
        name = entry['title']
        authors = entry['author']
        rows.append({
            'package': decoder.latex_to_text(name),
            'authors': decoder.latex_to_text(authors),
            'description': '',
            'url': url,
            'msc': '',
            'verified': False
        })

with open("mizar_library.csv", "w") as f:
    writer = csv.DictWriter(f, fieldnames=['package', 'authors', 'description', 'url', 'msc', 'verified'])
    writer.writeheader()
    writer.writerows(rows)
