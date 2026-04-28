
import pandas as pd
import os

# Data for 2026 Administrative Support Services Unit WFP
data = [
    ["Crops Section", "Crops Section PPAs for PR & PPMP Facilitation", "2026", "No. of PRs and PPMP facilitated", "Agri MOOE", "Other-MOE Expenses", 0.0, 0.0, "Planned", "Crops Section Head", "Office", ""],
    ["Inland Fisheries Section", "Inland Fisheries PPAs for PR & PPMP Facilitation", "2026", "No. of PRs and PPMP facilitated", "Agri MOOE", "Other-MOE Expenses", 0.0, 0.0, "Planned", "Inland Fisheries Head", "Office", ""],
    ["Institutional Development", "IDS PPAs for PR & PPMP Facilitation", "2026", "No. of PRs and PPMP facilitated", "Agri MOOE", "Other-MOE Expenses", 0.0, 0.0, "Planned", "IDS Head", "Office", ""],
    ["PMED", "PMED PPAs for PR & PPMP Facilitation", "2026", "No. of PRs and PPMP facilitated", "Agri MOOE", "Other-MOE Expenses", 0.0, 0.0, "Planned", "PMED Head", "Office", ""],
    ["Integrated Agricultural Laboratories", "License Renewal Processing Fee", "2026", "No. of license renewals processed", "Agri MOOE", "Other-MOE Expenses", 0.0, 0.0, "Planned", "Lab Head", "Lab", ""],
    ["General Administrative Services", "Admin PPAs for PR & PPMP Facilitation", "2026", "No. of PRs and PPMP facilitated", "Agri MOOE", "Other-MOE Expenses", 0.0, 0.0, "Planned", "Admin Officer", "Office", ""],
    ["Human Resource Management", "Man-Com Quarterly Meeting", "2026", "No. of Man-Com meetings conducted", "Agri MOOE", "Training Expenses", 0.0, 0.0, "Planned", "HRMO", "Conference Room", ""],
    ["Human Resource Management", "Training Workshop on Integrating the Sustainable Development Goals into the City's Agricultural and Food Security Strategies", "2026", "No. of workshops conducted", "Agri MOOE", "Training Expenses", 0.0, 0.0, "Planned", "HRMO", "TBA", ""],
    ["Human Resource Management", "Personnel Development (Mid-Year Assessment) Activity", "June 2026", "No. of assessments completed", "Agri MOOE", "Personnel Development Expenses", 0.0, 0.0, "Planned", "HRMO", "TBA", ""],
    ["Human Resource Management", "DTR & Payroll Submission Facilitation", "2026", "No. of DTRs/Payrolls facilitated", "Agri MOOE", "Other-MOE Expenses", 0.0, 0.0, "Planned", "HRMO", "Office", ""],
    ["Human Resource Management", "Office Order/Memo Preparations", "2026", "No. of Office Orders/Memos prepared", "Agri MOOE", "Other-MOE Expenses", 0.0, 0.0, "Planned", "HRMO", "Office", ""],
    ["Human Resource Management", "Monetization & Leave of Absence Facilitation", "2026", "No. of monetization/leave requests facilitated", "Agri MOOE", "Other-MOE Expenses", 0.0, 0.0, "Planned", "HRMO", "Office", ""],
    ["Office Supplies", "Office Supplies", "2026", "No. of supply PRs facilitated", "Agri MOOE", "Office Supplies Expenses", 0.0, 0.0, "Planned", "Supply Officer", "Office", ""],
    ["Communication Services", "Postage & Courier Services", "2026", "No. of postage/courier services facilitated", "Agri MOOE", "Communication Expenses", 0.0, 0.0, "Planned", "Admin Staff", "Office", ""],
    ["Communication Services", "Telephone Expenses", "2026", "No. of months telephone bills paid", "Agri MOOE", "Communication Expenses", 0.0, 0.0, "Planned", "Admin Staff", "Office", ""],
    ["Communication Services", "Internet Subscription Expenses", "2026", "No. of months internet subscription paid", "Agri MOOE", "Communication Expenses", 0.0, 0.0, "Planned", "Admin Staff", "Office", ""],
    ["Communication Services", "Communication Services", "2026", "No. of communication services maintained", "Agri MOOE", "Communication Expenses", 0.0, 0.0, "Planned", "Admin Staff", "Office", ""],
    ["Repair and Maintenance", "Buildings and other Structures", "2026", "No. of buildings maintained/repaired", "Agri MOOE", "Repair/Maintenance Expenses", 0.0, 0.0, "Planned", "GSS Head", "Various", ""],
    ["Repair and Maintenance", "Machinery and Equipment", "2026", "No. of machinery/equipment maintained", "Agri MOOE", "Repair/Maintenance Expenses", 0.0, 0.0, "Planned", "GSS Head", "Various", ""],
    ["Repair and Maintenance", "Transportation Equipment", "2026", "No. of vehicles maintained", "Agri MOOE", "Repair/Maintenance Expenses", 0.0, 0.0, "Planned", "GSS Head", "Various", ""],
    ["Travelling Expenses", "Travel Orders consolidations", "2026", "No. of travel orders consolidated", "Agri MOOE", "Travelling Expenses", 0.0, 0.0, "Planned", "Admin Staff", "Office", ""],
    ["Fuel, Oil & Lubricants", "No. of Trip Tickets, Gas Slips, Fuel Liquidation Facilitated", "2026", "No. of trip tickets/gas slips/liquidation facilitated", "Agri MOOE", "Fuel/Oil Expenses", 0.0, 0.0, "Planned", "GSS Head", "Office", ""],
    ["Revenue & Collection Services", "Monthly Accomplishment Report Submission", "2026", "No. of monthly reports submitted", "Agri MOOE", "Other-MOE Expenses", 0.0, 0.0, "Planned", "Revenue Officer", "Office", ""],
    ["General Services", "Laundry of Table Cloths and Curtains", "2026", "No. of linens laundered", "Agri MOOE", "Other-MOE Expenses", 0.0, 0.0, "Planned", "Utility Staff", "Various", ""],
    ["General Services", "Purified Drinking Water", "2026", "No. of purified water containers provided", "Agri MOOE", "Other-MOE Expenses", 0.0, 0.0, "Planned", "Utility Staff", "Office", ""],
    ["General Services", "Driver Services", "2026", "No. of driver services facilitated", "Agri MOOE", "Other-MOE Expenses", 0.0, 0.0, "Planned", "GSS Head", "Various", ""],
    ["General Services", "FTC, Chairs, Projector Booking Services", "2026", "No. of bookings facilitated", "Agri MOOE", "Other-MOE Expenses", 0.0, 0.0, "Planned", "Utility Staff", "Office", ""],
    ["General Services", "Photocopy Activities", "2026", "No. of photocopy activities facilitated", "Agri MOOE", "Other-MOE Expenses", 0.0, 0.0, "Planned", "Utility Staff", "Office", ""],
    ["General Services", "Risogragh Activities", "2026", "No. of risograph activities facilitated", "Agri MOOE", "Other-MOE Expenses", 0.0, 0.0, "Planned", "Utility Staff", "Office", ""],
    ["General Services", "Messenger Activities", "2026", "No. of messenger activities facilitated", "Agri MOOE", "Other-MOE Expenses", 0.0, 0.0, "Planned", "Utility Staff", "Office", ""],
    ["General Services", "Utility Services", "2026", "No. of utility services facilitated", "Agri MOOE", "Other-MOE Expenses", 0.0, 0.0, "Planned", "Utility Staff", "Office", ""],
]


columns = [
    "Sector", "Activity", "Target Date", "Indicator", "Funding Source", 
    "Object/Fund", "Budget", "Actual Exp", "Status", "Responsible", 
    "Location", "Accom"
]

df = pd.DataFrame(data, columns=columns)
output_path = os.path.join(os.getcwd(), "WFP_2026_Import_Template.xlsx")
df.to_excel(output_path, index=False)
print(f"File created at: {output_path}")
