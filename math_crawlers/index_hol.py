from bs4 import BeautifulSoup
import requests
import csv
import re
import os
import sys

directory = sys.argv[1]

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
            url = 'https://github.com{}'.format(module['href'])
            child_soup = BeautifulSoup(requests.get(url).text, 'html.parser')
            for child_module in child_soup.find_all('a', {'class': 'js-navigation-open'}):
                regex = r"/{}/blob/master/{}/(\S+.{})".format(repo,module_name,extension)
                child_match = re.match(regex, child_module['href'])
                if child_match:
                    name = child_match.group(1)
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
            has_source = False
            if 'src' in children:
                children = os.listdir(os.path.join(full_module, 'src'))
                has_source = True

            for child in children:
                root_module = 'src/{}'.format(child) if has_source else child
                child_path = os.path.join(full_module, root_module)
                if is_module(child_path, extension) and not child.startswith("."):
                    url = ''
                    if os.path.isdir(child_path):
                        url = 'https://github.com/{}/tree/master/{}/{}/{}'.format(repo, subdir , module, root_module)
                        rows.append({
                            'package': "{}/{}".format(module, child),
                            'authors': '',
                            'description': '',
                            'url': url,
                            'msc': module_to_category[module],
                            'verified': False
                        })
                    else:
                        if re.match(r"^.*{}$".format(extension), child):
                            url = 'https://github.com/{}/blob/master/{}/{}/{}'.format(repo, subdir, module, root_module)
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
with open("./hol_library_categories.csv", "r") as f:
    reader = csv.DictReader(f)
    category_to_modules = {package['package']: package['msc'] for package in reader}
    

rows = recurse_file(directory, "HOL-Theorem-Prover/HOL", "(?:sml)",category_to_modules , "src")

with open("hol_library.csv", "w") as f:
    writer = csv.DictWriter(f, fieldnames=['package', 'authors', 'description', 'url', 'msc', 'verified'])
    writer.writeheader()
    writer.writerows(rows)
