# TODO - Object of Expenditure dropdown + automatic row expansion

## Step 1: Update dropdown source
- [ ] Modify `lib/screens/admin/add_activity_dialog.dart` so the “Object of Expenditure” dropdown options come from `budgetLines` (filter by selected `fundSource`) instead of `AppConstants.getFilteredObjectsOfExpenditure(...)`.

## Step 2: Normalize training OE naming
- [ ] Ensure “Training Expenses” selection matches the actual `budget_lines.object_of_expenditure` value.
- [ ] Handle “Training Expenses” vs “Trainings and Seminar Expenses” (and other minor naming variants) consistently so row expansion targets the right budget lines.

## Step 3: Keep auto-add row logic consistent
- [ ] Adjust `_addRowsForExpenditure()` / fundSource lookup so it uses normalized OE values.

## Step 4: Validate
- [ ] Run `flutter analyze`.
- [ ] Run a quick build/test if project has configured tests.
- [ ] Manual UI verification: selecting “Training Expenses” expands rows for all fund sources with that OE.

