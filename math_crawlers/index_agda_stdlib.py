from bs4 import BeautifulSoup
import requests
import csv
import re

source = requests.get('https://agda.github.io/agda-stdlib/Everything.html')

soup = BeautifulSoup(source.text, 'html.parser')

rows = []
categories = set()
code = soup.find('pre')
description = ""
for element in code.find_all('a'):
    print(element)
    if element.has_attr('class') and 'Comment' in element['class']:
        description += " " + element.get_text().strip()[3:]
    elif element.has_attr('class') and 'Module' in element['class']:
        module_name = element.get_text().strip() 
        top_level_module = module_name.split(".")[0]
        if top_level_module not in categories:
            print("not in categories")
            # We only include top level categories, Agda modules are very refined
            print(element['id'])
            rows.append({
                'package': top_level_module,
                'authors': '',
                'description': description.strip(),
                'url': 'https://agda.github.io/agda-stdlib/Everything.html#{}'.format(element['id']),
                'msc': '',
                'verified': False
            })
            categories.add(top_level_module)
        description = ""

with open("agda_std_library.csv", "w") as f:
    writer = csv.DictWriter(f, fieldnames=['package', 'authors', 'description', 'url', 'msc', 'verified'])
    writer.writeheader()
    writer.writerows(rows)
