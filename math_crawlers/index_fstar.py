from bs4 import BeautifulSoup
import requests
import csv
import re

source = requests.get('https://github.com/FStarLang/FStar/tree/master/ulib')

soup = BeautifulSoup(source.text, 'html.parser')

rows = []
categories = set()
all_modules = soup.find('body')
large_category = ""
small_category = ""
sub_category = ""
for module in all_modules.find_all('a', {'class': 'js-navigation-open'}):
    print(module)
    matches = re.match(r"/FStarLang/FStar/blob/master/ulib/([\w\-.]+).fst", module['href'])
    if matches:
        name = matches.group(1)
        if len(name.split(".")) < 3:
            rows.append({
                'package': name,
                'authors': '',
                'description': '',
                'url': 'https://github.com/FStarLang/FStar/blob/master/ulib/{}'.format(name),
                'msc': '',
                'verified': False
            })

with open("fstar_library.csv", "w") as f:
    writer = csv.DictWriter(f, fieldnames=['package', 'authors', 'description', 'url', 'msc', 'verified'])
    writer.writeheader()
    writer.writerows(rows)
