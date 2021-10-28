from bs4 import BeautifulSoup
import requests
import csv
import re
import os
import sys

directory = sys.argv[1]
source = requests.get('https://github.com/acl2/acl2/tree/master/books')

soup = BeautifulSoup(source.text, 'html.parser')

def recurse_github(repo, extension, subdir=None):
    rows = []
    source = ""
    if subdir == None:
        source = requests.get('https://github.com/{}'.format(repo))
    else:
        source = requests.get('https://github.com/{}/tree/master/{}'.format(repo, subdir))

    soup = BeautifulSoup(source.text, 'html.parser')
    for module in all_modules.find_all('a', {'class': 'js-navigation-open'}):
        matches = re.match(r"/{}/tree/master/([\d_\w]+(?:\.ml)?)".format(repo), module['href'])
        if matches:
            module_name = matches.group(1)
            print(module_name)
            url = 'https://github.com{}'.format(module['href'])
            child_soup = BeautifulSoup(requests.get(url).text, 'html.parser')
            for child_module in child_soup.find_all('a', {'class': 'js-navigation-open'}):
                print(child_module['href'])
                regex = r"/{}/blob/master/{}/(\S+.{})".format(repo,module_name,extension)
                print(regex)
                child_match = re.match(regex, child_module['href'])
                if child_match:
                    name = child_match.group(1)
                    print("{}/{}".format(module_name, name))
                    rows.append({
                        'package': "{}/{}".format(module_name, name),
                        'authors': '',
                        'description': '',
                        'url': 'https://github.com{}'.format(child_module['href']),
                        'msc': module_to_category[module_name],
                        'verified': False
                    })
    return rows

def list_directory(path):
    return [os.path.join(path,child) for child in os.listdir(path) if not child.startswith(".")]

def is_module(path, extension):
    return os.path.isdir(path) or extension.endswith(extension)

def recurse_file(directory, repo, extension, module_to_category, subdir=None):
    rows = []
    modules = [child for child in os.listdir(directory) if not child.startswith(".")]

    for module in modules:
        full_module = os.path.join(directory, module)
        if os.path.isdir(full_module):
            children = os.listdir(full_module)

            for child in children:
                child_path = os.path.join(full_module, child)
                if is_module(child_path, extension) and not child.startswith("."):
                    url = ''
                    if os.path.isdir(child_path):
                        url = 'https://github.com/{}/tree/master/{}/{}/{}'.format(repo, subdir, module, child)
                        rows.append({
                            'package': "{}/{}".format(module, child),
                            'authors': '',
                            'description': '',
                            'url': url,
                            'msc': module_to_category[module],
                            'verified': False
                        })
                    else:
                        if child.endswith(extension):
                            url = 'https://github.com/{}/blob/master/{}/{}/{}'.format(repo, subdir, module, child)
                            rows.append({
                                'package': "{}/{}".format(module, child),
                                'authors': '',
                                'description': '',
                                'url': url,
                                'msc': module_to_category[module],
                                'verified': False
                            })
    return rows
            

category_to_modules = {}
with open("./acl2_categories.csv", "r") as f:
    reader = csv.DictReader(f)
    category_to_modules = {package['package']: package['msc'] for package in reader}
    

rows = recurse_file(directory, "acl2/acl2", "lisp",category_to_modules , "books")

print(rows)
with open("acl2_library.csv", "w") as f:
    writer = csv.DictWriter(f, fieldnames=['package', 'authors', 'description', 'url', 'msc', 'verified'])
    writer.writeheader()
    writer.writerows(rows)
