# CityAgriAdmin UI/UX Professional Design Guide

## Overview
This guide establishes professional, user-friendly UI/UX standards for the CityAgriAdmin system. All new features and screens should follow these guidelines.

---

## 📐 Design System

### Spacing Scale (8px base unit)
- **spacing2** (2px) - Micro spacing
- **spacing4** (4px) - Tight spacing
- **spacing8** (8px) - Default small spacing
- **spacing12** (12px) - Comfortable spacing
- **spacing16** (16px) - Standard spacing
- **spacing20** (20px) - Medium spacing
- **spacing24** (24px) - Large spacing
- **spacing32+** - Extra large spacing for major sections

**Usage:**
```dart
Padding(
  padding: const EdgeInsets.all(AppDesignSystem.spacing16),
  child: child,
)
```

### Border Radius Scale
- **radiusSmall** (8px) - Small UI elements
- **radiusMedium** (12px) - Medium elements
- **radiusLarge** (16px) - Default rounded radius
- **radiusXLarge** (20px) - Cards, dialogs
- **radiusRound** (999px) - Fully rounded (badges, avatars)

### Color Palette
- **Primary Green**: `#2E7D32` (Light), `#4CAF50` (Dark)
- **Secondary Gold**: `#D4AF37`
- **Error Red**: `#DC2626`
- **Success Green**: `#1B5E20`
- **Warning Amber**: `#F59E0B`
- **Info Blue**: `#3B82F6`
- **Neutral Gray**: `#9CA3AF`

---

## 🎨 Typography

### Text Styles Hierarchy

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| **displayLarge** | 32px | 700 | Main page titles |
| **displayMedium** | 28px | 700 | Section headers |
| **displaySmall** | 24px | 700 | Subsection headers |
| **headlineSmall** | 20px | 700 | Card titles |
| **titleLarge** | 18px | 600 | Dialog titles |
| **titleMedium** | 16px | 600 | Subheadings |
| **bodyLarge** | 16px | 400 | Main body text |
| **bodyMedium** | 14px | 400 | Regular body text |
| **bodySmall** | 12px | 400 | Secondary text |
| **labelLarge** | 14px | 500 | Button labels, form labels |
| **labelSmall** | 11px | 500 | Badges, small labels |

**Usage:**
```dart
Text(
  'Page Title',
  style: theme.textTheme.displaySmall,
)
```

---

## 🔘 Components

### Enhanced Buttons

Three button variants for different contexts:

#### 1. Primary Button (CTA)
```dart
EnhancedButton(
  label: 'Save Activity',
  onPressed: () { /* ... */ },
  variant: ButtonVariant.primary,
  size: ButtonSize.medium,
  icon: Icons.check,
)
```

**When to use:**
- Main call-to-action
- Submit, Save, Create actions
- Primary navigation

#### 2. Secondary Button
```dart
EnhancedButton(
  label: 'Cancel',
  onPressed: () { /* ... */ },
  variant: ButtonVariant.secondary,
)
```

**When to use:**
- Secondary actions
- Cancellation or going back
- Less prominent actions

#### 3. Tertiary Button
```dart
EnhancedButton(
  label: 'Learn More',
  onPressed: () { /* ... */ },
  variant: ButtonVariant.tertiary,
)
```

**When to use:**
- Links or minimal actions
- Additional options
- De-emphasized actions

#### Button Sizes
- **Small** (36px) - Compact spaces
- **Medium** (48px) - Default/recommended
- **Large** (56px) - Important actions

### Form Fields

#### Enhanced Text Input
```dart
EnhancedTextFormField(
  label: 'Activity Name',
  hint: 'Enter activity name',
  helperText: 'Name should be descriptive',
  required: true,
  validator: (value) {
    if (value?.isEmpty ?? true) return 'This field is required';
    return null;
  },
  prefixIcon: Icon(Icons.agriculture),
  maxLength: 100,
)
```

**Features:**
- Required field indicators (red asterisk)
- Focus states with primary color
- Clear error messages
- Helper text for guidance
- Icon support
- Character counter

#### Enhanced Dropdown
```dart
EnhancedDropdownField<String>(
  label: 'Sector',
  value: selectedSector,
  items: [
    DropdownMenuItem(value: 'crops', child: Text('Crop Production')),
    DropdownMenuItem(value: 'livestock', child: Text('Livestock')),
  ],
  onChanged: (value) => setState(() => selectedSector = value),
  required: true,
  prefixIcon: Icon(Icons.category),
)
```

---

## 📱 Dialog & Modals

### Enhanced Dialog
```dart
EnhancedDialog.show(
  context,
  title: 'Confirm Action',
  content: Text('Are you sure you want to delete this activity?'),
  actions: [
    EnhancedButton(
      label: 'Cancel',
      onPressed: () => Navigator.pop(context),
      variant: ButtonVariant.secondary,
    ),
    EnhancedButton(
      label: 'Delete',
      onPressed: () => _deleteActivity(),
      variant: ButtonVariant.primary,
    ),
  ],
)
```

**Features:**
- Consistent styling
- Proper header with close button
- Scrollable content
- Footer with action buttons
- Accessibility-first design

---

## ⚠️ States & Feedback

### Empty State
```dart
EnhancedEmptyState(
  icon: Icons.inbox,
  title: 'No Activities',
  message: 'Start by creating your first activity',
  actionLabel: 'Create Activity',
  onAction: () => _showAddActivityDialog(),
)
```

### Error State
```dart
EnhancedErrorState(
  title: 'Failed to Load',
  message: 'Please check your connection and try again',
  actionLabel: 'Retry',
  onAction: () => _loadData(),
)
```

### Loading State
```dart
EnhancedLoadingState(
  message: 'Loading activities...',
  showBackground: true,
)
```

### Loading Skeleton
```dart
EnhancedSkeletonList(
  itemCount: 5,
  itemHeight: 100,
  spacing: AppDesignSystem.spacing16,
)
```

---

## 🎨 Feedback & Notifications

### Snackbars

#### Success Notification
```dart
EnhancedSnackBar.showSuccess(
  context,
  'Activity saved successfully',
)
```

#### Error Notification
```dart
EnhancedSnackBar.showError(
  context,
  'Failed to save activity. Please try again.',
)
```

#### Warning Notification
```dart
EnhancedSnackBar.showWarning(
  context,
  'This action cannot be undone',
)
```

---

## 🎬 Animations & Transitions

### Duration Standards
- **Quick** (150ms) - Hover effects, state changes
- **Smooth** (300ms) - Normal transitions
- **Medium** (500ms) - Page transitions
- **Slow** (800ms) - Important state changes

**Usage:**
```dart
AnimatedContainer(
  duration: AppDesignSystem.durationSmooth,
  curve: Curves.easeInOut,
  // ... animation properties
)
```

---

## ♿ Accessibility

### Touch Targets
- Minimum touch target size: **44px × 44px** (WCAG guideline)
- Comfortable touch target: **48px × 48px** (recommended)

### Focus States
- All interactive elements must have visible focus states
- Use primary color for focus ring
- Minimum focus ring width: 2px

### Keyboard Navigation
- All buttons and inputs must be keyboard accessible
- Tab order should be logical and predictable
- Use `semanticLabel` for icon-only buttons

### Color Contrast
- Text contrast ratio: **4.5:1** minimum (WCAG AA)
- Check color combinations in both light and dark modes
- Don't rely on color alone to convey information

### Semantic Labels
```dart
IconButton(
  icon: Icons.delete,
  tooltip: 'Delete Activity',
  onPressed: () { /* ... */ },
)

Semantics(
  label: 'Activity Status: Active',
  child: Text('Active'),
)
```

---

## 📐 Layout Guidelines

### Screen Spacing
- **Top/Bottom padding**: `spacing24`
- **Side padding**: `spacing16` (mobile), `spacing24` (tablet+)
- **Content gap**: `spacing16`

### Card Layouts
```dart
Card(
  child: Padding(
    padding: const EdgeInsets.all(AppDesignSystem.spacing16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Title', style: theme.textTheme.headlineSmall),
        SizedBox(height: AppDesignSystem.spacing12),
        Text('Content', style: theme.textTheme.bodyMedium),
      ],
    ),
  ),
)
```

### Form Layout
```dart
Form(
  child: Column(
    children: [
      EnhancedTextFormField(label: 'Field 1'),
      SizedBox(height: AppDesignSystem.spacing20),
      EnhancedDropdownField(label: 'Field 2'),
      SizedBox(height: AppDesignSystem.spacing24),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          EnhancedButton(label: 'Cancel', ...),
          SizedBox(width: AppDesignSystem.spacing12),
          EnhancedButton(label: 'Submit', ...),
        ],
      ),
    ],
  ),
)
```

---

## 🌙 Dark Mode

All components automatically adapt to dark mode:
- **Light Background**: `#F9FAFB`
- **Dark Background**: `#121212`
- **Light Card**: `#FFFFFF`
- **Dark Card**: `#1E1E1E`
- **Dark Input**: `#2C2C2C`

No additional styling needed when using the provided components!

---

## ✅ Implementation Checklist

Before shipping a new feature, ensure:

- [ ] Consistent spacing using design system scale
- [ ] Proper typography hierarchy
- [ ] Color contrast meets WCAG AA standards
- [ ] Touch targets minimum 44px
- [ ] Focus states visible and accessible
- [ ] Loading, error, and empty states implemented
- [ ] Snackbars for user feedback
- [ ] Keyboard navigation works
- [ ] Works in both light and dark modes
- [ ] Micro-interactions and animations smooth
- [ ] No hardcoded colors (use theme colors)
- [ ] Form validation with helpful error messages
- [ ] Semantic HTML/Labels for screen readers

---

## 🚀 Migration Guide

### From Old to New Components

**Old Way:**
```dart
ElevatedButton(
  onPressed: onPressed,
  child: Text('Click Me'),
)
```

**New Way:**
```dart
EnhancedButton(
  label: 'Click Me',
  onPressed: onPressed,
)
```

**Old Snackbars:**
```dart
AgriUI.showError(context, message)
```

**New Snackbars:**
```dart
EnhancedSnackBar.showError(context, message)
```

---

## 📞 Questions?

Refer to these files for implementation details:
- `lib/core/design_system.dart` - Design tokens
- `lib/widgets/enhanced_form_fields.dart` - Form components
- `lib/widgets/enhanced_buttons_dialogs.dart` - Buttons & dialogs
- `lib/widgets/enhanced_states.dart` - Loading/empty/error states
