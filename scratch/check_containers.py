import re
import sys

def check_file(filepath):
    print(f"Checking {filepath}...")
    with open(filepath, 'r') as f:
        lines = f.readlines()
    
    for i, line in enumerate(lines):
        if 'Container(' in line:
            snippet = "".join(lines[i:i+15])
            if 'color:' in snippet and 'decoration:' in snippet:
                # Naive check: is 'color:' followed by 'decoration:' or vice versa
                # where 'color:' is NOT inside 'BoxDecoration(' or 'BoxShadow('
                # We can check if 'color:' is at the same indentation as 'decoration:'
                
                # Let's just print it and I'll look at it.
                print(f"Potential issue at line {i+1}:")
                print(snippet)
                print("-" * 40)

check_file(r'd:\CityAgriAdmin\cityagriadmin\lib\screens\admin\add_activity_dialog.dart')
check_file(r'd:\CityAgriAdmin\cityagriadmin\lib\widgets\grid_form_fields.dart')
check_file(r'd:\CityAgriAdmin\cityagriadmin\lib\screens\admin\edit_activity_dialog.dart')
