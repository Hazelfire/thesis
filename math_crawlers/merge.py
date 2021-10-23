import csv
import sys

rows = {}

with open(sys.argv[1], "r") as f1:
    reader = csv.DictReader(f1)
    for line in reader:
        rows[line['package']] = line

with open(sys.argv[2], "r") as f2:
    reader = csv.DictReader(f2)
    for line in reader:
        if line['package'] in rows:
            if line['verified']:
                rows[line['package']] = line

with open(sys.argv[3], "w") as f3:
    writer = csv.DictWriter(f3, fieldnames=['package', 'authors', 'description', 'url', 'msc', 'verified'])
    writer.writeheader()
    writer.writerows(list(rows.values()))
