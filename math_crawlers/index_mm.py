import bs4
from bs4 import BeautifulSoup
import requests
import csv
import re

category_to_modules = {}
with open("./mm_categories.csv", "r") as f:
    reader = csv.DictReader(f)
    category_to_modules = {package['package']: package['msc'] for package in reader}

rows = []
def index_site(site):
    source = requests.get(site)

    soup = BeautifulSoup(source.text, 'html.parser')

    categories = set()
    # There is an unclosed p tag I need to consider
    all_modules = soup.find('p')
    category = ""
    for module in all_modules.children:
        if module.name == 'a':
            print("found Link")
            print(module.get_text())
            matches = re.match(r"PART \d+\s+([\w\s\)\(\-']+)", module.get_text())
            if matches:
                category = re.sub(r"\s+", " ", matches.group(1).strip())

            matches = re.match(r"\d+\.\d+\s+([\s\S]+)", module.get_text())

            if matches:
                name = re.sub(r"\s+", " ", matches.group(1).strip())
                url = site + module['href']
                rows.append({
                    'package': name,
                    'authors': '',
                    'description': '',
                    'url': url,
                    'msc': category_to_modules.get(category, ''),
                    'verified': False
                })
        if module.name == 'hr':
            print("Out TOC")
            break

sites = ['http://us.metamath.org/ileuni/mmtheorems.html','http://us.metamath.org/mpeuni/mmtheorems.html', 'http://us.metamath.org/nfeuni/mmtheorems.html']

for site in sites:
    index_site(site)

with open("mm_library.csv", "w") as f:
    writer = csv.DictWriter(f, fieldnames=['package', 'authors', 'description', 'url', 'msc', 'verified'])
    writer.writeheader()
    writer.writerows(rows)
