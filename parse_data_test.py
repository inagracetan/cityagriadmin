import re
import json
import uuid
from typing import Any, Dict, List, Optional

def parse_amount(s: Optional[str]) -> Optional[float]:
    if not s: return None
    # Remove commas and handle spaces between digits
    s = s.strip().replace(',', '')
    if not s: return None
    # Check if it's a number (can be negative or decimals)
    if re.match(r'^-?[\d\.]+$', s):
        try:
            return float(s)
        except:
            return None
    return None

def clean_text(s: Optional[str]) -> str:
    if not s: return ""
    # Remove multiple spaces and tabs
    return re.sub(r'\s+', ' ', s).strip()

# Mapping for sectors to match Activity model expectations
SECTOR_MAP: Dict[str, str] = {
    'CROPS': 'Crop Section',
    'ILAND FISHERIES': 'Inland Fisheries Section',
    'INLAND FISHERIES': 'Inland Fisheries Section',
    'INSTITUTIONAL DVELOPMENT SECTION': 'Institutional Development Section',
    'INSTITUTIONAL DEVELOPMENT SECTION': 'Institutional Development Section',
    'INTEGRATED AGRICULTURAL LABORATORY': 'Integrated Agricultural Laboratory',
    'PROJECT DEVELOPMENT SECTION': 'Project Section',
    'MONITORING & EVALUATION SECTION': 'Monitoring and Evaluation Section',
    'ADMINISTRATIVE SUPPORT SERVICES UNIT': 'Administrative Support Services Unit'
}

# Mapping for sub-sectors
SUBSECTOR_MAP: Dict[str, str] = {
    'Rice Program': 'Rice',
    'Corn Program': 'Corn',
    'HVCDP': 'HVCDP',
    'Organic Program': 'Organic Program'
}

# Mapping for Object of Expenditure keywords
OBJ_EXP_KEYWORDS: Dict[str, str] = {
    'Travelling Expenses': 'Travelling Expenses',
    'Training Expenses': 'Training Expenses',
    'Office Supplies': 'Office Supplies Expenses',
    'Fuel': 'Fuel/Oil Expenses',
    'Communication': 'Communication Expenses',
    'Repair': 'Repair/Maintenance Expenses',
    'Other-MOE': 'Other-MOE Expenses',
    'Personnel Development': 'Personnel Development Expenses'
}

SECTOR_KEYS_UPPER: List[str] = [k.upper() for k in SECTOR_MAP.keys()]

def process_file():
    try:
        with open('raw_data.txt', 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except FileNotFoundError:
        print("Error: raw_data.txt not found.")
        return

    activities: List[Dict[str, Any]] = []
    current_sector: str = 'Crop Section'
    current_sub_sector: Optional[str] = None
    current_activity: Optional[Dict[str, Any]] = None

    for line in lines:
        line = line.strip('\n')
        if not line.strip():
            continue
            
        s_line = line.strip()
        
        # Check for sector headers
        found_sector = False
        upper_s_line = s_line.upper()
        for key, val in SECTOR_MAP.items():
            if upper_s_line.startswith(key):
                current_sector = val
                current_sub_sector = None
                current_activity = None
                found_sector = True
                break
        if found_sector: continue
            
        # Check for sub-sector headers
        mapped_sub = SUBSECTOR_MAP.get(s_line)
        if mapped_sub:
            current_sub_sector = mapped_sub
            current_activity = None
            continue

        # Split by tabs
        parts = line.split('\t')
        parts = [p.strip() for p in parts]
        
        # Check if it starts with an activity number (e.g., "1", "2")
        first_part = parts[0] if parts else ""
        match = re.match(r'^(\d+)\s*(.*)$', first_part)
        
        if match:
            act_no = match.group(1)
            act_name = match.group(2)
            
            # If name wasn't in the first part, it might be in the second
            if not act_name and len(parts) > 1:
                act_name = parts[1]
                
            if act_name and len(act_name) >= 2:
                amounts = []
                for i, p in enumerate(parts):
                    if i == 0 and p == act_no: continue
                    val = parse_amount(p)
                    if val is not None:
                        if '/' in p or '-' in p: continue
                        amounts.append(val)
                        
                budget = 0.0
                actual = 0.0
                if len(amounts) >= 2:
                    actual = amounts[0]
                    budget = amounts[0] + amounts[1]
                elif len(amounts) == 1:
                    budget = amounts[0]
                    actual = 0.0
                    
                funding_source = 'Agri MOOE'
                upper_raw = line.upper()
                if '20% DF' in upper_raw:
                     funding_source = 'Special Funds'
                else:
                    for p in parts:
                        if 'CDRRMO' in p.upper():
                            funding_source = 'Special Funds'
                            break
                
                status = 'Planned'
                if 'OBRE & ABSTRACT' in upper_raw: status = 'Obre & Abstract Signature'
                elif 'PR' in upper_raw: status = 'PR Prepared'
                elif 'PO' in upper_raw: status = 'PO Prepared'
                
                obj_exp = None
                search_text = f"{current_sector} {current_sub_sector or ''} {act_name}".upper()
                for key, val in OBJ_EXP_KEYWORDS.items():
                    if key.upper().split(' ')[0] in search_text:
                        obj_exp = val
                        break
                
                activity: Dict[str, Any] = {
                    'id': str(uuid.uuid4()),
                    'sector': current_sector,
                    'sub_sector': current_sub_sector,
                    'activity_name': clean_text(act_name),
                    'performance_indicator': 'As per plan',
                    'target_no': 1,
                    'funding_source': funding_source,
                    'object_of_expenditure': obj_exp,
                    'special_fund_source': '20% DF' if funding_source == 'Special Funds' else None,
                    'q1_budget': budget,
                    'q2_budget': 0.0,
                    'q3_budget': 0.0,
                    'q4_budget': 0.0,
                    'actual_expenditure': actual,
                    'responsible_person': 'TBD',
                    'status': status,
                    'target_date': '2026',
                    'breakdown': []
                }
                activities.append(activity)
                current_activity = activity
                continue
            
        # If not already an activity match, it might be a breakdown item
        if not current_activity:
            continue
            
        sub_name = ""
        sub_amount = 0.0
        found_name = False
        potential_amounts = []
        
        for p in parts:
            if not p: continue
            val = parse_amount(p)
            if val is not None:
                if '/' in p or '-' in p: continue
                potential_amounts.append(val)
            elif not found_name:
                # Use the global SECTOR_KEYS_UPPER
                if len(p) > 2 and p.upper() not in SECTOR_KEYS_UPPER:
                    sub_name = p
                    found_name = True
        
        # FINAL GUARD: Ensure current_activity is still not None and we found a name
        if found_name and current_activity:
            if potential_amounts:
                sub_amount = potential_amounts[0]
            
            # Double check type for safety before calling .get()
            if isinstance(current_activity, dict):
                main_name = current_activity.get('activity_name', '')
                if not isinstance(main_name, str):
                    main_name = str(main_name or '')
                
                # Check sub_name type too
                s_name = str(sub_name)

                if s_name.lower() != main_name.lower():
                    bd_items = current_activity.get('breakdown')
                    if isinstance(bd_items, list):
                        bd_items.append({
                            'name': clean_text(sub_name),
                            'amount': sub_amount
                        })

    # Final mapping to match Firebase export structure
    output = {
        'activities': activities
    }

    try:
        with open('seed_data.json', 'w', encoding='utf-8') as f:
            json.dump(output, f, indent=2)
        print(f"Successfully parsed {len(activities)} activities into seed_data.json")
    except Exception as e:
        print(f"Error saving seed_data.json: {e}")

if __name__ == "__main__":
    process_file()
