from bs4 import BeautifulSoup
import requests
import csv
import re

source = requests.get('https://github.com/nasa/pvslib')

soup = BeautifulSoup(source.text, 'html.parser')

rows = []
categories = set()
all_modules = soup.find('table')
large_category = ""
small_category = ""
sub_category = ""
for module in all_modules.find_all('tr'):
    link = module.find('a')
    if link:
        url = link['href']
        name = link.get_text().strip()
        description = module.find_all('td')[1].get_text().strip()
        rows.append({
            'package': name,
            'authors': '',
            'description': description,
            'url': 'https://github.com{}'.format(url),
            'msc': '',
            'verified': False
        })

with open("pvs_library.csv", "w") as f:
    writer = csv.DictWriter(f, fieldnames=['package', 'authors', 'description', 'url', 'msc', 'verified'])
    writer.writeheader()
    writer.writerows(rows)
