
import pandas as pd
import os

data = [
    ["Administrative Support Services Unit", "Laundry of Table Cloths and Curtains", "Q1, Q2, Q3, Q4", "PRs Prepared", "Agri MOOE", "Other-MOE Expenses", 0, 0, "Planned", "Admin", "Various", ""],
    ["Administrative Support Services Unit", "Purified Drinking Water", "Q1, Q2, Q3, Q4", "PRs Prepared", "Agri MOOE", "Other-MOE Expenses", 0, 0, "Planned", "Admin", "Office", ""],
    ["Administrative Support Services Unit", "Seminar on Work Ethics and Administrative Guidelines & Mandates", "2025", "Conducted", "Agri MOOE", "Other-MOE Expenses", 0, 0, "Planned", "Admin", "TBA", ""],
    ["Administrative Support Services Unit", "License Renewal Processing Fee", "2025", "Processed", "Agri MOOE", "Other-MOE Expenses", 0, 0, "Planned", "Admin", "PTCL", ""],
    ["Administrative Support Services Unit", "ManCom Meeting Quarterly", "Q1, Q2, Q3, Q4", "Conducted", "Agri MOOE", "Other-MOE Expenses", 0, 0, "Planned", "Admin", "Office", "Meals/snacks, Tarp"],
    ["Administrative Support Services Unit", "Varian AAS 55B -55B CSTL Equipment", "2025", "Maintained", "Agri MOOE", "Other-MOE Expenses", 0, 0, "Planned", "Admin", "Lab", ""],
    ["Administrative Support Services Unit", "Convocation", "2025", "Conducted", "Agri MOOE", "Other-MOE Expenses", 0, 0, "Planned", "Admin", "TBA", ""],
    ["Administrative Support Services Unit", "Google Drive", "2025", "Renewed", "Agri MOOE", "Other-MOE Expenses", 0, 0, "Planned", "Admin", "Online", ""],
    ["Administrative Support Services Unit", "Tapok Mag-uuma 2025 (23rd City AFC Congress)", "2025", "Conducted", "Agri MOOE", "Other-MOE Expenses", 0, 0, "Planned", "Admin", "TBA", "Hotel & Accomodation"],
    ["Administrative Support Services Unit", "Cloud Router", "2025", "Purchased/Maintained", "Agri MOOE", "Other-MOE Expenses", 0, 0, "Planned", "Admin", "IT", ""],
    ["Administrative Support Services Unit", "Toner", "2025", "Purchased", "Agri MOOE", "Other-MOE Expenses", 0, 0, "Planned", "Admin", "Office", ""],
    ["Administrative Support Services Unit", "Distribution of LGU Financial Assistance to Farmers Affected by Flashfloods and Landslides", "2025", "Distributed", "Agri MOOE", "Other-MOE Expenses", 0, 0, "Planned", "Admin", "Field", "Meals & snacks, Tarp"],
    ["Administrative Support Services Unit", "Seminar on administrative Efficiency and Task Prioritization", "2025", "Conducted", "Agri MOOE", "Other-MOE Expenses", 0, 0, "Planned", "Admin", "TBA", ""],
    ["Administrative Support Services Unit", "Meals & Snacks Buffer", "2025", "Provided", "Agri MOOE", "Other-MOE Expenses", 0, 0, "Planned", "Admin", "Office", ""],
    ["Administrative Support Services Unit", "Aircon Main Repair", "2025", "Repaired", "Agri MOOE", "Other-MOE Expenses", 0, 0, "Planned", "Admin", "Office", "CA, ACA, FTC 3"],
    ["Administrative Support Services Unit", "JO TEV for October", "October 2025", "Processed", "Agri MOOE", "Other-MOE Expenses", 0, 0, "Planned", "Admin", "RBL-Lauag", ""],
    ["Administrative Support Services Unit", "Consultation Meeting and training needs assessment for DAMAUDARC-DPP OPERATIONS", "2025", "Conducted", "Agri MOOE", "Other-MOE Expenses", 0, 0, "Planned", "Admin", "TBA", "PAA Registration for 9 staff"]
]

columns = [
    "Sector", "Activity", "Target Date", "Indicator", "Funding Source", 
    "Object/Fund", "Budget", "Actual Exp", "Status", "Responsible", 
    "Location", "Accom"
]

df = pd.DataFrame(data, columns=columns)
output_path = os.path.join(os.getcwd(), "Other_MOOE_Import.xlsx")
df.to_excel(output_path, index=False)
print(f"File created at: {output_path}")
