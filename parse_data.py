import json
import re

with open('raw_data.txt', 'r', encoding='utf-8') as f:
    lines = f.readlines()

activities = []
current_sector = 'Crop Section'
current_sub_sector = ''

for line in lines:
    line = line.strip()
    if not line:
        continue
    if line.startswith('CROPS'):
        current_sector = 'Crop Section'
        continue
    if line.startswith('Iland Fisheries'):
        current_sector = 'Inland Fisheries Section'
        continue
    if line.startswith('Institutional Dvelopment Section'):
        current_sector = 'Institutional Development Section'
        continue
    if line.startswith('Integrated Agricultural Laboratory'):
        current_sector = 'Integrated Agricultural Laboratory'
        continue
    if line.startswith('Project Development Section'):
        current_sector = 'Project Development Section'
        continue
    if line.startswith('Monitoring & Evaluation Section'):
        current_sector = 'Monitoring and Evaluation Section'
        continue
    if line.startswith('Administrative Support Services Unit'):
        current_sector = 'Administrative Support Services Unit'
        continue
    
    # Sub-sectors
    if line == 'Rice Program':
        current_sub_sector = 'Rice'
        continue
    if line == 'Corn Program':
        current_sub_sector = 'Corn'
        continue
    if line == 'HVCDP':
        current_sub_sector = 'HVCDP'
        continue
    if line == 'Organic Program':
        current_sub_sector = 'Organic Program'
        continue

    # Try to match numbered activities: e.g. "1\tUpland Hybrid..." or "1 Travelling Expenses"
    match = re.search(r'^(\d+)\s+(.+)', line)
    
    # We will just print the matched lines to see what we get
    # It's better to manually or semi-manually process because of nested structures and irregular tabs
print("Parsed sectors and lines structure done")
