import chevron
from zipfile import ZipFile
import csv
import datetime
import typing
now = datetime.datetime.now().strftime("%d %B %Y")

data = {
    'RQ1': 'What usability issues and solutions have been mentioned in literature regarding ITPs?',
    'RQ2': 'To what extent to these usability issues exist at the latest versions of ITPs?',
    'RQ3': 'What, if any, ITP should be used for a specific project?',
    'date': now
}

with ZipFile('results/all_data.zip', 'r') as all_data:
    with all_data.open("itps.csv", mode='r') as itpsFile:
        itps = list(csv.DictReader([line.decode('utf8') for line in itpsFile.readlines()]))
        data['itps'] = itps
        data['itpCount'] = len(data['itps'])
        data['counterexampleITPs'] = [itp for itp in itps if itp['Counterexamples'] != 'No']
        data['noCounterexampleITPs'] = [itp for itp in itps if itp['Counterexamples'] == 'No']

        data['mathNotationITPs'] = [itp for itp in itps if itp['UTF8 Library'] != 'No']
        data['noMathNotationITPs'] = [itp for itp in itps if itp['UTF8 Library'] == 'No']


    with all_data.open("libraries.csv", mode='r') as libraries:
        data['libraries'] = list(csv.DictReader([line.decode('utf8') for line in libraries.readlines()]))
        data['libraryCount'] = len(data['itps'])

with open("results/library_stats.csv", "r") as libstats:
    data['libstats'] = csv.DictReader(libstats)
    data['totalPackageCount'] = sum([int(line['Total']) for line in data['libstats']])
    data['verifiedPackageCount'] = sum([int(line['Verified']) for line in data['libstats']])

    data['leanPackageCount'] = sum([int(line['Total']) for line in data['libstats'] if line['ITP'] == 'Lean'])

    data['mizarPackageCount'] = sum([int(line['Total']) for line in data['libstats'] if line['ITP'] == 'Mizar'])


with open('index.md', 'r') as f:
    result = chevron.render(f, data)
    data["html"] = True
    with open("build.html.md", "w") as out:
        out.write(result)

    data["html"] = False
    data["latex"] = True
    with open("build.tex.md", "w") as out:
        out.write(result)
