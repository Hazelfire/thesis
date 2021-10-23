import csv

classifications = {}
verified = set()
new_rows = []
with open("src/library_data/afp_packages.csv", "r") as f:
    reader = csv.DictReader(f)
    for package in reader:
        name = package['package']
        if name not in classifications:
            classifications[name] = package
        else: 
            if package['verified']:
                classifications[name] = package

with open("new_afp.csv", "w") as f:
    w = csv.DictWriter(f, fieldnames=["package","description","url","authors","category","msc","verified"])
    w.writeheader()
    w.writerows(classifications.values())
