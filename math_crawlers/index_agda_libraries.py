from bs4 import BeautifulSoup
import requests
import csv
import re

source = requests.get('https://wiki.portal.chalmers.se/agda/Main/Libraries')

soup = BeautifulSoup(source.text, 'html.parser')

rows = []
categories = set()
page = soup.find('div', {'id': 'wikitext'})
description = ""
for library_list in page.find_all('ul'):
    print("List")
    for list_item in library_list.find_all('li'):
        text = list_item.get_text()
        if len(text.split(": ")) == 2:
            name = text.split(": ")[0].strip()
            description = text.split(": ")[1].strip()
            url = ""
            link = list_item.find('a')
            if link:
                url = link['href']
            rows.append({
                'package': name,
                'authors': '',
                'description': description,
                'url': url,
                'msc': '',
                'verified': False
            })
        else:
            link = list_item.find('a')
            print(link)
            if link:
                if link.has_attr('href'):
                    url = link['href']
                    name = link.get_text()
                    rows.append({
                        'package': name,
                        'authors': '',
                        'description': '',
                        'url': url,
                        'msc': '',
                        'verified': False
                    })



with open("agda_libraries.csv", "w") as f:
    writer = csv.DictWriter(f, fieldnames=['package', 'authors', 'description', 'url', 'msc', 'verified'])
    writer.writeheader()
    writer.writerows(rows)
