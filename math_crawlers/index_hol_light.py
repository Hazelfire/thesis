from bs4 import BeautifulSoup
import requests
import csv
import re

source = requests.get('https://github.com/jrh13/hol-light')

soup = BeautifulSoup(source.text, 'html.parser')
module_to_category = { '100':  ''
  , 'Arithmetic': '03F30'
  , 'Boyer_Moore': '68W32'
  , 'Complex': '30-XX'
  , 'Examples': 'Exclude-Doc'
  , 'Formal_ineqs': '26Dxx'
  , 'Functionspaces': '30-XX'
  , 'GL': '03F45'
  , 'Geometric_Algebra': '14-XX'
  , 'Help': 'Exclude-Doc'
  , 'IEEE': '68P05'
  , 'IsabelleLight': 'Exclude-Util'
  , 'Jordan': '54-XX'
  , 'LP_arith': '90C05'
  , 'Library': ''
  , 'Logic': '03-XX'
  , 'Minisat': '68V15'
  , 'Mizarlight': 'Exclude-Util'
  , 'Model': 'Exclude-Util'
  , 'Multivariate': '26Bxx'
  , 'Ntrie': '68Q65'
  , 'Permutation': '06-XX'
  , 'ProofTrace': 'Exclude-Util'
  , 'Proofrecording': 'Exclude-Util'
  , 'QBF': '68R07'
  , 'Quaternions': '11R52'
  , 'RichterHilbertAxiomGeometry': '51-xx'
  , 'Rqe': 'Exclude-NoDoc'
  , 'Tutorial': 'Exclude-Doc'
  , 'Unity': '68Q10'
  , 'miz3': 'Exclude-Util'
  }

rows = []
categories = set()
all_modules = soup.find('body')
large_category = ""
small_category = ""
sub_category = ""
for module in all_modules.find_all('a', {'class': 'js-navigation-open'}):
    matches = re.match(r"/jrh13/hol-light/tree/master/([\d_\w]+(?:\.ml)?)", module['href'])
    if matches:
        module_name = matches.group(1)
        print(module_name)
        url = 'https://github.com{}'.format(module['href'])
        child_soup = BeautifulSoup(requests.get(url).text, 'html.parser')
        for child_module in child_soup.find_all('a', {'class': 'js-navigation-open'}):
            print(child_module['href'])
            regex = r"/jrh13/hol-light/blob/master/{}/(\S+.[hm]l)".format(module_name)
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


with open("hol_light_library.csv", "w") as f:
    writer = csv.DictWriter(f, fieldnames=['package', 'authors', 'description', 'url', 'msc', 'verified'])
    writer.writeheader()
    writer.writerows(rows)
