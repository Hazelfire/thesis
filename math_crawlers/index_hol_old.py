from bs4 import BeautifulSoup
import requests
import csv
import re

source = requests.get('https://github.com/HOL-Theorem-Prover/HOL/tree/develop/src')

soup = BeautifulSoup(source.text, 'html.parser')

rows = []
categories = set()
all_modules = soup.find('body')
large_category = ""
small_category = ""
sub_category = ""
for module in all_modules.find_all('a', {'class': 'js-navigation-open'}):
    print(module)
    matches = re.match(r"/HOL-Theorem-Prover/HOL/tree/develop/src/(\w+)", module['href'])
    if matches:
        name = matches.group(1)
        rows.append({
            'package': name,
            'authors': '',
            'description': '',
            'url': 'https://github.com/HOL-Theorem-Prover/HOL/tree/develop/src/{}'.format(name),
            'msc': '',
            'verified': False
        })

with open("hol_library.csv", "w") as f:
    writer = csv.DictWriter(f, fieldnames=['package', 'authors', 'description', 'url', 'msc', 'verified'])
    writer.writeheader()
    writer.writerows(rows)
