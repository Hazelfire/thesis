from bs4 import BeautifulSoup
import requests
import csv
import re

source = requests.get('https://github.com/acl2/acl2/tree/master/books')

soup = BeautifulSoup(source.text, 'html.parser')

rows = []
categories = set()
all_modules = soup.find('body')
large_category = ""
small_category = ""
sub_category = ""
for module in all_modules.find_all('a', {'class': 'js-navigation-open'}):
    print(module)
    matches = re.match(r"/acl2/acl2/tree/master/books/([\w\-]+)", module['href'])
    if matches:
        name = matches.group(1)
        rows.append({
            'package': name,
            'authors': '',
            'description': '',
            'url': 'https://github.com/acl2/acl2/tree/master/books/{}'.format(name),
            'msc': '',
            'verified': False
        })

with open("acl2_library.csv", "w") as f:
    writer = csv.DictWriter(f, fieldnames=['package', 'authors', 'description', 'url', 'msc', 'verified'])
    writer.writeheader()
    writer.writerows(rows)
