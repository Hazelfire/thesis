from github import Github
from github.Repository import Repository
import os
import requests
from bs4 import BeautifulSoup
import csv
import re
import datetime

# First create a Github instance:

# using an access token
g = Github(os.environ['GITHUB_TOKEN'])

remotes = [{
    "name": "ACL2",
    "repo": "acl2/acl2"
    },{
    "name": "Isabelle",
    "repo": "seL4/isabelle",
    },{
    "name": "Metamath",
    "repo": "metamath/metamath-exe",
    },{
    "name": "Twelf",
    "repo": "standardml/twelf"
    },{
    "name": "Agda",
    "repo": "agda/agda"
    },{
    "name": "HOL4",
    "repo": "HOL-Theorem-Prover/HOL"
    },{
    "name": "HOL Light",
    "repo": "jrh13/hol-light"
    },{
    "name": "RedPRL",
    "repo": "redprl/sml-redprl"
    },{
    "name": "Coq",
    "repo": "coq/coq"
    },{
    "name": "PVS",
    "repo": "SRI-CSL/PVS"
    },{
    "name": "Lean",
    "repo": "leanprover/lean4"
    },{
    "name": "F*",
    "repo": "FStarLang/FStar"
    },{
    "name": "Idris",
    "repo": "idris-lang/Idris2"
    },{
    "name": "JAPE",
    "repo": "RBornat/jape"
    },{
    "name": "LEO-II",
    "repo": "leoprover/LEO-II"
    },{
    "name": "GETFOL",
    "repo": "getfol/GETFOL"
    }]


with open("itp_github_stats.csv", "w") as f:
    writer = csv.DictWriter(f, fieldnames=["name", "latest_release_date", "latest_release_name", "url", "release_url"])

    # Then play with your Github objects:
    writer.writeheader()
    for remote in remotes:
        print(remote['name'])
        repo = g.get_repo(remote['repo'])
        tags = repo.get_tags()
        if tags.totalCount == 0:
            commit = repo.get_branch(repo.default_branch).commit
            writer.writerow({
                'name': remote['name'],
                'latest_release_date': commit.commit.committer.date,
                'latest_release_name': 'Unversioned, last commit {}'.format(commit.commit.sha[:7]),
                'url': 'https://github.com/' + remote['repo'] + '/',
                'release_url': "https://github.com/{}/".format(remote['repo']),
                'release_url': commit.url
            })
        else:
            tag = None
            if remote['name'] == 'Isabelle':
                tag = tags[1]
            else:
                tag = tags[0]
            writer.writerow({
                'name': remote['name'],
                'latest_release_date': tag.commit.commit.committer.date,
                'latest_release_name': tag.name,
                'url': 'https://github.com/' + remote['repo'] + '/',
                'release_url': 'https://github.com/{}/releases/tag/{}'.format(remote['repo'], tag.name)
            })
    
    # Some ITPs don't have GitHub sadly
    # Alterier B I can get from here: https://www.atelierb.eu/en/atelier-b-support-maintenance/download-atelier-b/
    print("Atelier B")
    source = requests.get('https://www.atelierb.eu/en/atelier-b-support-maintenance/download-atelier-b/').text
    soup = BeautifulSoup(source, 'html.parser')
    for link in soup.find_all('a'):
        match = re.match(r"https://www.atelierb.eu/wp-content/uploads/(\d\d\d\d)/(\d\d)/atelierb-free-([\d.]+)-win32.exe", link['href'])
        if match:
            year = match.group(1)
            month = match.group(2)
            version = match.group(3)
            writer.writerow({
                'name': 'Atelier B',
                'latest_release_date': datetime.datetime.strptime("{} {}".format(month, year), "%m %Y"),
                'latest_release_name': version,
                'url': 'https://www.atelierb.eu/en/atelier-b-support-maintenance/download-atelier-b/',
                'release_url': ''
            })


    # Mizar I can get from here: http://mizar.uwb.edu.pl/~softadm/current/
    print("Mizar")
    source = requests.get('http://mizar.uwb.edu.pl/~softadm/current/').text
    soup = BeautifulSoup(source, 'html.parser')
    match = re.search(r"mizar-([\.\d]+)_[\.\d]+-arm-linux.tar\s+([\d-]+)\s+([\d:]+)", soup.find('pre').get_text())
    if match:
        version = match.group(1)
        date = match.group(2)
        writer.writerow({
            'name': 'Mizar',
            'latest_release_date': datetime.datetime.strptime("{}".format(date), "%Y-%m-%d"),
            'latest_release_name': version,
            'url': 'http://mizar.uwb.edu.pl/~softadm/current/',
            'release_url': ''
        })


    # Z/EVES can be found here: https://sourceforge.net/projects/czt/files/czt-ide/nightly/
    print("Z/EVES")
    source = requests.get('https://sourceforge.net/projects/czt/files/czt-ide/nightly/').text
    first_row = BeautifulSoup(source, 'html.parser').tbody.tr
    name = first_row.th.a.get_text()
    date = first_row.td.get_text()
    release_url = first_row.th.a['href']
    
    writer.writerow({
        'name': 'Z/EVES',
        'latest_release_date': datetime.datetime.strptime(date, "%Y-%m-%d"),
        'latest_release_name': name.strip(),
        'url': 'https://sourceforge.net/projects/czt/files/czt-ide/nightly/',
        'release_url': 'https://sourceforge.net{}'.format(release_url)
    })

