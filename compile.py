import chevron
from zipfile import ZipFile
import csv
import datetime
import typing
import sys
now = datetime.datetime.now().strftime("%d %B %Y")
nawazITPs = ['Isabelle', 'Coq', 'HOL', 'Agda', 'PVS', 'LEO-II', 'Watson', 'Yarrow', 'Atelier B', 'Metamath', 'Twelf', 'Mizar', 'RedPRL', 'JAPE', 'LEO-II', 'Getfol', 'Z/EVES']

addedITPs = ['Lean', 'F*', 'Idris']

def list_text(items):
    if len(items) == 1:
        return items[0]
    elif len(items) == 2:
        return " and ".join(items)

    elif len(items) > 2:
        last_two = items[-2:]
        rest = items[:-2]
        return ", ".join(rest + [", and ".join(last_two)])
        

data = {
    'RQ1': 'What usability issues and solutions have been mentioned in literature regarding ITPs?',
    'RQ2': 'To what extent to these usability issues exist at the latest versions of ITPs?',
    'RQ3': 'What, if any, ITP should be used for a specific project?',
    'nawazITPs': list_text(nawazITPs),
    'addedITPs': list_text(addedITPs),
    'date': now
}

with ZipFile('results/all_data.zip', 'r') as all_data:
    with all_data.open("itps.csv", mode='r') as itpsFile:
        itps = list(csv.DictReader([line.decode('utf8') for line in itpsFile.readlines()]))
        itps.sort(key=lambda x: x['Name'])
        data['itps'] = itps
        data['itpNames'] = list_text([itp['Name'] for itp in itps])
        data['itpCount'] = len(data['itps'])
        data['counterexampleITPs'] = [itp for itp in itps if itp['Counterexamples'] != 'No']
        data['noCounterexampleITPs'] = [itp for itp in itps if itp['Counterexamples'] == 'No']

        data['mathNotationITPs'] = [{ 'name': itp['Name'], 'description': itp['Math Notation Descriptions']} for itp in itps if itp['UTF8 Library'] == 'Yes']
        data['noMathNotationITPs'] = list_text([itp['Name'] for itp in itps if itp['UTF8 Library'] == 'No'])


    with all_data.open("counterExampleGenerators.csv", mode='r') as counterExampleGenerators:
        generatorList = list(csv.DictReader([line.decode('utf8') for line in counterExampleGenerators.readlines()]))
        generatorList.sort(key=lambda x: x['name'])
        with all_data.open("counterExampleIntegrations.csv", mode='r') as counterExampleIntegrations:
            integrations = list(csv.DictReader([line.decode('utf8') for line in counterExampleIntegrations.readlines()]))
            generatorData = []
            for generator in generatorList:
                generatorData.append({
                    'name': generator['name'],
                    'description': generator['description'],
                    'support': list_text([integration['prover'] for integration in  integrations if integration['name'] == generator['name']])
                })
            data['noCounterExampleITPS'] = list_text([itp['Name'] for itp in data['itps'] if itp['Name'] not in {integration['prover'] for integration in integrations}])
            data['counterExampleGenerators'] = generatorData
            data['counterExampleCount'] = len(generatorData)


    with all_data.open("libraries.csv", mode='r') as libraries:
        libraries = list(csv.DictReader([line.decode('utf8') for line in libraries.readlines()]))
        libraries.sort(key=lambda x: x['name'])
        data['libraries'] = libraries
        data['libraryCount'] = len(data['libraries'])

with open("results/library_stats.csv", "r") as libstats:
    libstats = list(csv.DictReader(libstats))
    libstats.sort(key=lambda x: x['ITP'])
    data['libstats'] =libstats
    data['totalPackageCount'] = sum([int(line['Total']) for line in data['libstats']])
    data['verifiedPackageCount'] = sum([int(line['Verified']) for line in data['libstats']])

    data['leanPackageCount'] = sum([int(line['Total']) for line in data['libstats'] if line['ITP'] == 'Lean'])

    data['mizarPackageCount'] = sum([int(line['Total']) for line in data['libstats'] if line['ITP'] == 'Mizar'])

with open("results/classification.csv", "r") as classification:
    packages = list(csv.DictReader(classification))
    verifiedPackages = [package for package in packages if package['Verified'] == 'Yes']
    data['totalCompSciModules'] = len([package for package in verifiedPackages if package['MSC'].startswith('68')])
    data['totalLogicModules'] = len([package for package in verifiedPackages if package['MSC'].startswith('03')])
    data['totalProgrammingLanguageModules'] = len([package for package in verifiedPackages if package['MSC'] == "68N15"])
    data['totalDataStructuresModules'] = len([package for package in verifiedPackages if package['MSC'] == "68P05"])
    data['totalProcessorModules'] = len([package for package in verifiedPackages if package['MSC'] == "68N20"])



if sys.argv[1] == 'html':
    with open('index.md', 'r') as f:
        contents = f.read()
        data['html'] = True
        result = chevron.render(contents, data)
        with open("build.html.md", "w") as out:
            out.write(result)
elif sys.argv[1] == 'latex':
    with open('index.md', 'r') as f:
        contents = f.read()
        data['latex'] = True
        result = chevron.render(contents, data)
        with open("build.tex.md", "w") as out:
            out.write(result)
