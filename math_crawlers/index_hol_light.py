from bs4 import BeautifulSoup
import requests
import csv
import re

source = requests.get('https://github.com/jrh13/hol-light')

soup = BeautifulSoup(source.text, 'html.parser')

rows = []
categories = set()
all_modules = soup.find('body')
large_category = ""
small_category = ""
sub_category = ""
for module in all_modules.find_all('a', {'class': 'js-navigation-open'}):
    print(module)
    matches = re.match(r"/jrh13/hol-light/(?:tree|blob)/master/([\d_\w]+(?:\.ml)?)", module['href'])
    if matches:
        name = matches.group(1)
        print(name)
        rows.append({
            'package': name,
            'authors': '',
            'description': '',
            'url': 'https://github.com{}'.format(module['href']),
            'msc': '',
            'verified': False
        })

with open("hol_light_library.csv", "w") as f:
    writer = csv.DictWriter(f, fieldnames=['package', 'authors', 'description', 'url', 'msc', 'verified'])
    writer.writeheader()
    writer.writerows(rows)
