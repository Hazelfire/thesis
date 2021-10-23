import bs4
from bs4 import BeautifulSoup
import requests
import csv
import re

rows = []
def index_site(site):
    source = requests.get(site)

    soup = BeautifulSoup(source.text, 'html.parser')

    categories = set()
    # There is an unclosed p tag I need to consider
    all_modules = soup.find('p')
    large_category = ""
    small_category = ""
    sub_category = ""
    for module in all_modules.children:
        if module.name == 'a':
            print("found Link")
            print(module.get_text())
            matches = re.match(r"PART \d+\s+([\w\s\)\(\-']+)", module.get_text())
            if matches:
                print("no match")
                name = " ".join(re.split(r"\s", matches.group(1).strip()))
                url = "http://us.metamath.org/mpeuni/mmtheorems.html" + module['href']
                rows.append({
                    'package': name,
                    'authors': '',
                    'description': '',
                    'url': url,
                    'msc': '',
                    'verified': False
                })
        if module.name == 'hr':
            print("Out TOC")
            break

sites = ['http://us.metamath.org/ileuni/mmtheorems.html','http://us.metamath.org/mpeuni/mmtheorems.html', 'http://us.metamath.org/nfeuni/mmtheorems.html']

for site in sites:
    index_site(site)

rows.append({
    'package': 'Higher Order Logic',
    'authors': '',
    'description': '',
    'url': 'http://us.metamath.org/holuni/mmhol.html',
    'msc': '',
    'verified': False
})

rows.append({
    'package': 'Hilbert Logic',
    'authors': '',
    'description': '',
    'url': 'http://us.metamath.org/mpeuni/mmhil.html',
    'msc': '',
    'verified': False
})

rows.append({
    'package': 'Quantum Logic',
    'authors': '',
    'description': '',
    'url': 'http://us.metamath.org/qleuni/mmql.html',
    'msc': '',
    'verified': False
})

rows.append({
    'package': 'Solitaire',
    'authors': '',
    'description': '',
    'url': 'http://us.metamath.org/mmsolitaire/mms.html',
    'msc': '',
    'verified': False
})

rows.append({
    'package': 'Music',
    'authors': '',
    'description': '',
    'url': 'http://us.metamath.org/mpeuni/mmmusic.html',
    'msc': '',
    'verified': False
})

with open("mm_library.csv", "w") as f:
    writer = csv.DictWriter(f, fieldnames=['package', 'authors', 'description', 'url', 'msc', 'verified'])
    writer.writeheader()
    writer.writerows(rows)
