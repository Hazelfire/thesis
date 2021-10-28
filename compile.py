import chevron
import re
import itertools
from zipfile import ZipFile
import csv
import datetime
import typing
import sys
import json
now = datetime.datetime.now().strftime("%d %B %Y")
nawazITPs = ['Isabelle', 'Coq', 'HOL', 'Agda', 'PVS', 'LEO-II', 'Watson', 'Yarrow', 'Atelier B', 'Metamath', 'Twelf', 'Mizar', 'RedPRL', 'JAPE', 'LEO-II', 'Getfol', 'Z/EVES']

addedITPs = ['Lean', 'F*', 'Idris']
ic1ExcludedITPs = ['Twelf']
ic2ExcludedITPS = [ {'name': 'Getfol', 'size': 1372} , {'name': 'RedPRL', 'size': 2680}]
outlierITPs = ['HOL Light', 'Isabelle', 'Mizar', 'Coq', 'Lean']
outlierITPs.sort()

def cited_list(items):
    return list_text(['{} [@{}]'.format(item, item.replace(" ","_")) for item in items])

def partition(items, predicate):
    return ([item for item in items if predicate(item)], [item for item in items if not predicate(item)])

def package_counts(packages):
    (unclassified, classified) = partition(packages, lambda x: x['MSC'] == '' or x['MSC'] == 'NA' or x['MSC'] == 'None' or x['MSC'] == '??-XX')
    (verified, unverified) = partition(classified, lambda x: x['Verified'])
    (excluded, not_excluded) = partition(verified, lambda x: x['MSC'].startswith('Exclude'))
    (unsure, sure) = partition(not_excluded, lambda x: x['MSC'].lower().endswith("xx"))
    (excludedDoc, notExcludedDoc) = partition(excluded, lambda x: x['MSC'] == 'Exclude-Doc')
    (excludeUtil, notExcludedUtil) = partition(notExcludedDoc, lambda x: x['MSC'] == 'Exclude-Util')
    (excludeNoDoc, notExcludedNoDoc) = partition(notExcludedUtil, lambda x: x['MSC'] == 'Exclude-Util')
    (excludeDepr, _) = partition(notExcludedNoDoc, lambda x: x['MSC'] == 'Exclude-Depr')
    return {
        'total': len(packages),
        'excluded': len(excluded),
        'excluded-doc': len(excludedDoc),
        'excluded-nodoc': len(excludeNoDoc),
        'excluded-util': len(excludeUtil),
        'excluded-depr': len(excludeDepr),
        'verified': len(verified),
        'unverified': len(unverified),
        'unclassified': len(unclassified),
        'incomplete': len(unclassified) + len(unverified) > 0,
        'sure': len(sure),
        'unsure': len(unsure),
        'needs_pro': len(unsure) > 0
        }

def incompleteDetails(summary):
    if summary['incomplete']:
       start = 'The classification was not complete, as there was'
       issue_list = []
       if summary['unverified'] > 0:
          issue_list.append('{} unverified modules'.format(summary['unverified']))
       if summary['unclassified'] > 0:
          issue_list.append('{} unclassified modules'.format(summary['unclassified']))
       return '{} {}. '.format(start, list_text(issue_list))
    else:
        return ""

def plural_modules(amount):
    if amount == 0:
        return 'no modules were'
    if amount == 1:
        return 'one module was'
    else:
        return '{} modules were'.format(amount)

def excludedDetails(summary):
    if summary['excluded'] == 0:
        return 'Of these modules no modules were excluded'
    else:
        start = 'Of these modules, {} excluded'.format(plural_modules(summary['excluded']))
        exclusion_list = []
        if summary['excluded-util'] > 0:
            exclusion_list.append('{} excluded for being a utility (EC1)'.format(plural_modules(summary['excluded-util'])))
        if summary['excluded-nodoc'] > 0:
            exclusion_list.append('{} excluded for not having documentation (EC2)'.format(plural_modules(summary['excluded-nodoc'])))
        if summary['excluded-doc'] > 0:
            exclusion_list.append('{} excluded for being only documentation (EC3)'.format(plural_modules(summary['excluded-doc'])))
        if summary['excluded-depr'] > 0:
            exclusion_list.append('{} excluded for being deprecated (EC4)'.format(plural_modules(summary['excluded-depr'])))
        return '{}. Including {}'.format(start, list_text(exclusion_list))


    
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
    'ic2ExcludedLibraries': ic2ExcludedITPS,
    'outlierITPs': list_text(outlierITPs),
    'date': now
}

mscLookup = {}

def removeBrackets(text):
     no_brackets = re.sub(r"\[[^\[\]]+\]", "", text)
     print(no_brackets)
     no_braces = re.sub(r"\{[^\{\}]+\}", "", no_brackets)
     return no_braces

with ZipFile('results/all_data.zip', 'r') as all_data:
    with all_data.open("msc.json", mode='r') as mscFile:
        msc = json.load(mscFile)
        for top_level in msc:
            mscLookup[top_level['code']] = removeBrackets(top_level['short_name'])
            for subclass in top_level['subclassifications']:
                mscLookup[subclass['code']] = removeBrackets(subclass['name'])

                for botclass in subclass['classifications']:
                    mscLookup[botclass['code']] = removeBrackets(botclass['name'])

            for botclass in top_level['classifications']:
                mscLookup[botclass['code']] = removeBrackets(botclass['name'])
                

    with all_data.open("itps.csv", mode='r') as itpsFile:
        itps = list(csv.DictReader([line.decode('utf8') for line in itpsFile.readlines()]))
        itps.sort(key=lambda x: x['Name'])
        data['itps'] = itps
        data['itpNames'] = list_text([itp['Name'] for itp in itps])
        data['citedItpNames'] = cited_list([itp['Name'] for itp in itps])
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
                    'supports': list_text([integration['prover'] for integration in  integrations if integration['name'] == generator['name']]),
                    'citation': "[{}]".format(";".join({"@{}".format(integration['citation']) for integration in integrations if integration['name'] == generator['name']}))
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
    data['clasifiedPackageCount'] = sum([int(line['Total']) for line in data['libstats']])
    data['verifiedPackageCount'] = sum([int(line['Verified']) for line in data['libstats']])
    data['unVerifiedPackageCount'] = sum([int(line['Verified']) for line in data['libstats']])
    data['classificationIncomplete'] = data['totalPackageCount'] > data['verifiedPackageCount']


    data['leanPackageCount'] = sum([int(line['Total']) for line in data['libstats'] if line['ITP'] == 'Lean'])

    data['mizarPackageCount'] = sum([int(line['Total']) for line in data['libstats'] if line['ITP'] == 'Mizar'])

with open("results/classification.csv", "r") as classification:
    packages = list(csv.DictReader(classification))
    verifiedPackages = [package for package in packages if package['Verified'] == 'Yes']
    data['totalCompSciModules'] = len([package for package in verifiedPackages if package['MSC'].startswith('68')])
    data['totalAutomataModules'] = len([package for package in verifiedPackages if package['MSC'].startswith('68Q45')])
    data['totalTheoryOfData'] = len([package for package in verifiedPackages if package['MSC'].startswith('68P')])
    data['totalLogicModules'] = len([package for package in verifiedPackages if package['MSC'].startswith('03')])
    data['totalProgrammingLanguageModules'] = len([package for package in verifiedPackages if package['MSC'] == "68N15"])
    data['totalDataStructuresModules'] = len([package for package in verifiedPackages if package['MSC'] == "68P05"])
    data['totalProcessorModules'] = len([package for package in verifiedPackages if package['MSC'] == "68N20"])

    summary_stats = []

    for library in data['libraries']:
        summary = package_counts([package for package in packages if package['ITP'] == library['name'] and package['Library'] == library['section']])
        summary['ITP'] = library['name']
        summary['Library'] = library['section']
        summary['ExcludedDetails'] = excludedDetails(summary)
        summary['IncompleteDetails'] = incompleteDetails(summary)
        summary_stats.append(summary)
    summary_stats.sort(key=lambda x: - x['total'])

    data['itp_summaries'] = summary_stats

    def get_top(packages, n, key):
        packages.sort(key=key)
        grouped = [(x, [z for z in y]) for x, y in itertools.groupby(packages, key = key)]
        grouped.sort(key=lambda x: -len(x[1]))
        return grouped[:n]

    def countsToText(counts):
        if 'prover' in counts[0]:
            return list_text(['*{}* with {} modules'.format(x['prover'], x['count']) for x in counts])
        else:
            return list_text(['*{}* ({}) with {} modules'.format(x['name'], x['msc'], x['count']) for x in counts])


    top_classifications = []

    comments =  { 
         '68-XX': 'Computer Science was clearly the most popular category, mainly because ITPs like ACL2, Isabelle, HOL4 and Coq are all mainly built for the purpose of verifying software. There was a large amount of data structures of all kinds created to reason about programs. Even Mizar, a usually mathematical ITP, has several modules dedicated to the verification of software.'
       , '03-XX': 'Mathematical Logic and Foundations was common because often ITPs would start developing their libraries through laying the foundations. However, some ITPs such as Mizar have large amounts of contributions on topics such as fuzzy logic, which does not neccesarily make up its foundation but is still within this category.'
       , '11-XX': 'Number Theory consistently had a large amount of modules from most ITPs. Elementary Number theory made up the majority of this category, mainly modular arithmetic, distribution of primes and primality checking.'
       , '26-XX': 'Real Functions covers topics often considered to be part of real analysis. This classification has a strong presence in Mizar, where a large amount of real analysis is covered. But also HOL Light, which sports a strong multivariate library.'
       , '54-XX': 'Topology made up a large amount of modules. Mizar definitely dominated this space, and discusses topology widely.'
       , '06-XX': 'Orders was covered widely, mainly in discussion with lattices. Mizar has a large amount of modules dedicated to formalising continuous lattices, which are then used in the context of Domain Theory.'
       , '05-XX': 'There were a large amount of combinatorics modules, mainly from graph theory. Isabelle here has the most packages, using graph theory mainly for the purpose of verifying graph algorithms.'
       , '18-XX': 'Category theory is often in the context of functional programming and controlling effects. Haskell has popularized the use of monads for controlling effects. ITPs such as Lean reimplement those concepts in their ITPs.'
       , '13-XX': 'Discussion of Commutative Algebra was mainly restricted to ITPs interested in proving math theorems, such as Mizar or Lean. Lean has a top level module entirely on ring theory.'
       , '51-XX': 'Geometry was common among most theroem provers, with Mizar having a large amount of module about Affine Geometry.'
       , '15-XX':  'Linear Algebra was implemented in several ITPs, mainly used for the purpose of setting up vector spaces.'
       }


    # Top 15 categories
    not_excluded = [package for package in packages if not package['MSC'].startswith('Exclude') and not package['MSC'] == '']
    for classification, cat_iter in get_top(not_excluded, 10, lambda x: x['MSC'][:2]):
        cat_packages = list(cat_iter)
        total_packages = len(cat_packages)
        code = classification + "-XX"
        top_mid_categories = [{'msc': msc + 'xx', 'count': len(modules), 'name': mscLookup[msc + 'xx']} for msc, modules in get_top(cat_packages,3,lambda x: x['MSC'][:3]) if msc + 'xx' in mscLookup]
        top_low_categories = [{'msc': msc, 'count': len(modules), 'name': mscLookup[msc]} for msc, modules in get_top(cat_packages,2,lambda x: x['MSC']) if msc in mscLookup]
        top_provers = [{'prover': prover, 'count': len(modules)} for prover, modules in get_top(cat_packages,3,lambda x: x['ITP'])]
        top_classifications.append({
            'msc': code,
            'name': mscLookup[code],
            'total': total_packages,
            'top_mid_categories': countsToText(top_mid_categories),
            'top_low_categories': countsToText(top_low_categories),
            'top_provers': countsToText(top_provers),
            'comment': comments[code]
            })
    data['top_classifications'] = top_classifications



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
