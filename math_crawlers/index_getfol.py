from bs4 import BeautifulSoup
import requests
import csv
import re

source = requests.get('https://github.com/getfol/GETFOL/tree/master/axiom')

soup = BeautifulSoup(source.text, 'html.parser')

rows = []
categories = set()
all_modules = soup.find('body')
large_category = ""
small_category = ""
sub_category = ""
for module in all_modules.find_all('a', {'class': 'js-navigation-open'}):
    print(module)
    matches = re.match(r"/getfol/GETFOL/blob/master/axiom/([\w\-.]+).tst", module['href'])
    if matches:
        name = matches.group(1)
        if len(name.split(".")) < 3:
            rows.append({
                'package': name,
                'authors': '',
                'description': '',
                'url': 'https://github.com/getfol/GETFOL/blob/master/axiom/{}.tst'.format(name),
                'msc': '',
                'verified': False
            })

with open("getfol_library.csv", "w") as f:
    writer = csv.DictWriter(f, fieldnames=['package', 'authors', 'description', 'url', 'msc', 'verified'])
    writer.writeheader()
    writer.writerows(rows)
