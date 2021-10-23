from bs4 import BeautifulSoup
import requests
import csv

coq_source = requests.get('https://coq.inria.fr/library/index.html')

soup = BeautifulSoup(coq_source.text, 'html.parser')

rows = []
categories = set()
all_modules = soup.find('dl')
large_category = ""
small_category = ""
sub_category = ""
for module in all_modules.find_all('dd'):
    for theory in module.find_all('a'):
        name = theory['href'].split(".html")[0]
        category = ".".join(name.split('.')[:-1][:3])
        url = "https://coq.inria.fr/library/{}".format(theory['href'])
        categories.add(category)

with open("coq_library.csv", "w") as f:
    writer = csv.DictWriter(f, fieldnames=['package', 'authors', 'description', 'url', 'msc', 'verified'])
    writer.writeheader()
    writer.writerows([{
            'package': category,
            'authors': '',
            'description': '',
            'url': 'https://coq.inria.fr/library/',
            'msc': '',
            'verified': False
        } for category in categories])
