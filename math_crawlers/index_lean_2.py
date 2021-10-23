from bs4 import BeautifulSoup
import requests
import csv
import re

source = requests.get('https://leanprover-community.github.io/mathlib_docs/')

soup = BeautifulSoup(source.text, 'html.parser')
all_modules = soup.find('nav', {'class': 'nav'})
rows = []

category_to_msc = {
        'init': 'Exclude-Util',
        'system': 'Exclude-Util',
        'data': '68P05',
        'algebra': '08-XX',
        'algebraic_geometry': '14-XX',
        'algebraic_topology': '55-XX',
        'analysis': '26-XX',
        'category_theory': '18-XX',
        'combinatorics': '05-XX',
        'computability': '03Dxx',
        'control':  '93-XX',
        'deprecated': 'Exclude-Depr',
        'dynamics': '37-XX',
        'field_theory': '12-XX',
        'geometry':  '51-XX',
        'group_theory': '20-XX',
        'linear_algebra': '15-XX',
        'logic': '03Bxx',
        'measure_theory': '28-XX',
        'meta': 'Exclude-Util',
        'model_theory': '03Cxx',
        'order': '06-XX',
        'probability_theory': '60-XX', 
        'representation_theory': '16Gxx',
        'ring_theory': '13-XX',
        'set_theory': '03Exx',
        'tactic': 'Exclude-Util',
        'testing': 'Exclude-Util',
        'topology': '54-XX'
        }

for module in all_modules.find_all('details',recursive=False):
    category = module['data-path']
    print(category)
    for submodule in module.find_all('details',recursive=False):
        name = submodule['data-path'].replace('/','.')
        url = submodule.find('a')['href']
        rows.append({
            'package': name,
            'authors': '',
            'description': '',
            'url': url,
            'msc': category_to_msc[category] if category in category_to_msc else '',
            'verified': False
            })
    for theory in module.find_all('div', {'class': 'nav_link'},recursive=False):
        url = theory.a['href']
        match = re.match(r"https://leanprover-community.github.io/mathlib_docs/([\w_/]+).html", url)
        if match:
            name = match.group(1).replace("/", ".")
            rows.append({
                'package': name,
                'authors': '',
                'description': '',
                'url': url,
                'msc': category_to_msc[category] if category in category_to_msc else '',
                'verified': False
                })
        
with open("lean_library.csv", "w") as f:
    writer = csv.DictWriter(f, fieldnames=['package', 'authors', 'description', 'url', 'msc', 'verified'])
    writer.writeheader()
    writer.writerows(rows)
