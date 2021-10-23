from bs4 import BeautifulSoup
import requests
import csv

source = requests.get('https://leanprover-community.github.io/mathlib-overview.html')

soup = BeautifulSoup(source.text, 'html.parser')

rows = []
categories = set()
all_modules = soup.find('main')
large_category = ""
small_category = ""
sub_category = ""
category_to_msc = {
        'Category theory': '18-XX',
        'Numbers': '11-XX',
        'Group theory': '20-XX',
        'Rings': '13-XX',
        'Ideals and quotients': '13Cxx',
        'Divisibility in integral domains': '13A05',
        'Polynomials and power series': '',
        'Algebras over a ring': '30-XX',
        'Field theory': '20-XX',
        'Homological algebra':  '18-XX',
        'Number theory':  '11-XX',
        'Transcendental numbers': '11J81',
        'Fundementals': '15Axx',
        'Duality': '15Axx',
        'Finite-dimensional vector spaces': '15A03',
        'Macrices': '15Axx',
        'Endomorphism polynomials': '15Axx',
        'Structure theory of endomorphisms': '15Axx',
        'Bilinear and quadratic forms': '15Axx',
        'General topology': '54-XX',
        'Uniform notions': '54E15',
        'Topological algebra': '55-XX',
        'Metric spaces': '54E35',
        'Normed vector spaces': '12J05',
        'Differentiability': '26A27',
        'Convexivity': '26A51',
        'Special functions': '33-XX',
        'Measures and integral calculus': '28-XX',
        'Affine and Euclidean geometry': '51-XX',
        'Differentiable manifolds': '58Axx',
        'Algebraic geometry': '14-XX',
        'Graph theory': '05Cxx',
        'Pigeonhole principles':  '05-XX',
        'Transversals': '05D15',
        'Circle dynamics': '37E10',
        'General theory': '37-XX',
        'List-like structures': '68P05',
        'Sets': '68P05',
        'Maps': '68P05',
        'Trees': '68P05',
        'Computability': '03Dxx',
        'Set theory': '03Exx'
        }
for module in all_modules.find_all('p', {'class': 'ml-4'}):
    category = module.b.get_text()
    for theory in module.find_all('a'):
        name = theory.get_text()
        rows.append({
            'package': name,
            'authors': '',
            'description': '',
            'url': theory['href'],
            'msc': category_to_msc[category] if category in category_to_msc else '',
            'verified': False
            })

with open("lean_library.csv", "w") as f:
    writer = csv.DictWriter(f, fieldnames=['package', 'authors', 'description', 'url', 'msc', 'verified'])
    writer.writeheader()
    writer.writerows(rows)
