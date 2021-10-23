from bs4 import BeautifulSoup
import requests
import csv

afp_source = requests.get('https://www.isa-afp.org/topics.html')


soup = BeautifulSoup(afp_source.text, 'html.parser')

def categories_to_string(large, small, sub):
    if small == "":
        return large
    elif sub == "":
        return large + "/" + small
    else:
        return large + "/" + small + "/" + sub
# This website is painfully formatted.
rows = []
all_lists = soup.find(attrs={'class':"descr"}).tbody.tr.td
large_category = ""
small_category = ""
sub_category = ""
for child in all_lists.children:
    if child.name == 'h2':
        large_category = child.contents[0]
        sub_category = ""
        small_category = ""

    if child.name == 'h3':
        small_category = child.contents[0]
        sub_category = ""

    if child.name == 'div':
        if child['class'] == ['list']:
            for item in child.children:
                if item.name == 'a':
                    print(item.contents[0])
                    website = 'https://www.isa-afp.org/entries/{}.html'.format(item.contents[0])
                    source = index = requests.get(website).text
                    childSoup = BeautifulSoup(source, 'html.parser')
                    description = " ".join(childSoup.find(attrs={'class', 'abstract'}).get_text().strip().split())
                    authors = " ".join(childSoup.find('table', attrs={'class': 'data'}).tbody.findAll('tr')[1].findAll('td')[1].get_text().strip().split())
                    print(authors)
                    print(description)

                    rows.append({
                        'name': item.contents[0],
                        'url': website,
                        'category': categories_to_string(large_category,small_category, sub_category),
                        'description': description,
                        'authors': authors
                    })
                if item.name == 'strong':
                    sub_category = item.contents[0][0:-1]
print(rows)
with open("afp_packages.csv", "w") as f:
    writer = csv.DictWriter(f, fieldnames=['category', 'url', 'name', 'description', 'authors'])
    writer.writeheader()
    writer.writerows(rows)
