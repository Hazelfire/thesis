from bs4 import BeautifulSoup
import requests
import csv

afp_source = requests.get('https://isabelle.in.tum.de/dist/library/')

soup = BeautifulSoup(afp_source.text, 'html.parser')

all_lists = soup.find('body').find_all('ul', recursive=False)
rows = []
modules = []
library = ""
for sub_lists in all_lists:
    for library in sub_lists.find('ul').find_all('li', recursive=False):
        link = library.find('a')
        if link is not None:
            print(link)
            library_name = link['href'].split('/')[0]
            library_source = requests.get("https://isabelle.in.tum.de/dist/library/{}".format(link['href']))
            library_soup = BeautifulSoup(library_source.text, 'html.parser')
            for module in library_soup.find_all('dt'):
                module_link = module.find('a')
                module_name = "{}/{}".format(library_name,module_link.get_text())
                module_url = "https://isabelle.in.tum.de/dist/library/{}/{}".format(library_name, module_link['href'])
                rows.append({
                    'package': module_name,
                    'module': library_name,
                    'url': module_url,
                    'description': '',
                    'authors': '',
                    'msc': '00-xx',
                    'verified': False
                })

with open("isabelle_library.csv", "w") as f:
    writer = csv.DictWriter(f, fieldnames=['package', 'module', 'url', 'description', 'authors', 'msc', 'verified'])
    writer.writeheader()
    writer.writerows(rows)
