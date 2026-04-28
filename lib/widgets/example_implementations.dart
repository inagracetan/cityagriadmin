import 'package:flutter/material.dart';
import '../core/design_system.dart';
import 'enhanced_form_fields.dart';
import 'enhanced_buttons_dialogs.dart';
import 'enhanced_states.dart';

/// Example implementations of the enhanced design system components
/// Use these as templates when building new screens and forms

class FormScreenExample extends StatefulWidget {
  const FormScreenExample({super.key});

  @override
  State<FormScreenExample> createState() => _FormScreenExampleState();
}

class _FormScreenExampleState extends State<FormScreenExample> {
  final _formKey = GlobalKey<FormState>();
  final _activityNameCtl = TextEditingController();
  final _descriptionCtl = TextEditingController();
  String? _selectedSector;
  String? _selectedStatus;
  bool _isLoading = false;

  @override
  void dispose() {
    _activityNameCtl.dispose();
    _descriptionCtl.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        EnhancedSnackBar.showSuccess(context, 'Activity saved successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        EnhancedSnackBar.showError(
          context,
          'Failed to save activity. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Activity')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDesignSystem.spacing24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Form Title
              Text(
                'Activity Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppDesignSystem.spacing20),

              // Activity Name Field
              EnhancedTextFormField(
                label: 'Activity Name',
                hint: 'e.g., Rice Planting Campaign',
                helperText: 'Give your activity a descriptive name',
                controller: _activityNameCtl,
                required: true,
                prefixIcon: const Icon(Icons.agriculture),
                maxLength: 100,
                showCounter: true,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Activity name is required';
                  }
                  if (value!.length < 3) {
                    return 'Activity name must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppDesignSystem.spacing20),

              // Sector Dropdown
              EnhancedDropdownField<String>(
                label: 'Sector',
                value: _selectedSector,
                required: true,
                prefixIcon: const Icon(Icons.category),
                items: [
                  const DropdownMenuItem(
                    value: 'crops',
                    child: Text('Crop Production'),
                  ),
                  const DropdownMenuItem(
                    value: 'livestock',
                    child: Text('Livestock'),
                  ),
                  const DropdownMenuItem(
                    value: 'fisheries',
                    child: Text('Fisheries'),
                  ),
                ],
                onChanged: (value) => setState(() => _selectedSector = value),
                validator: (value) {
                  if (value == null) return 'Please select a sector';
                  return null;
                },
              ),
              const SizedBox(height: AppDesignSystem.spacing20),

              // Description Field (Multiline)
              EnhancedTextFormField(
                label: 'Description',
                hint: 'Provide details about the activity',
                helperText:
                    'Be specific about objectives and expected outcomes',
                controller: _descriptionCtl,
                maxLines: 4,
                minLines: 3,
                maxLength: 500,
                showCounter: true,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppDesignSystem.spacing24),

              // Status Field
              EnhancedDropdownField<String>(
                label: 'Status',
                value: _selectedStatus,
                items: [
                  const DropdownMenuItem(
                    value: 'planned',
                    child: Text('Planned'),
                  ),
                  const DropdownMenuItem(
                    value: 'ongoing',
                    child: Text('Ongoing'),
                  ),
                  const DropdownMenuItem(
                    value: 'completed',
                    child: Text('Completed'),
                  ),
                ],
                onChanged: (value) => setState(() => _selectedStatus = value),
              ),
              const SizedBox(height: AppDesignSystem.spacing32),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  EnhancedButton(
                    label: 'Cancel',
                    onPressed: () => Navigator.pop(context),
                    variant: ButtonVariant.secondary,
                  ),
                  const SizedBox(width: AppDesignSystem.spacing12),
                  EnhancedButton(
                    label: 'Save Activity',
                    onPressed: _handleSubmit,
                    isLoading: _isLoading,
                    isEnabled: !_isLoading,
                    icon: const Icon(Icons.check),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Example of a list screen with loading, empty, and error states
enum _ListLoadingState { loading, empty, error, loaded }

class ListScreenExample extends StatefulWidget {
  const ListScreenExample({super.key});

  @override
  State<ListScreenExample> createState() => _ListScreenExampleState();
}

class _ListScreenExampleState extends State<ListScreenExample> {
  _ListLoadingState _state = _ListLoadingState.loading;
  List<String> _activities = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() => _state = _ListLoadingState.loading);

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // Uncomment one to see different states:
      // 1. Empty state
      // setState(() {
      //   _activities = [];
      //   _state = _ListLoadingState.empty;
      // });

      // 2. Loaded state
      setState(() {
        _activities = [
          'Rice Planting Campaign',
          'Livestock Training Program',
          'Fisheries Development Project',
        ];
        _state = _ListLoadingState.loaded;
      });

      // 3. Error state
      // setState(() {
      //   _errorMessage = 'Failed to load activities';
      //   _state = _ListLoadingState.error;
      // });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _state = _ListLoadingState.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activities'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActivities,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: switch (_state) {
        _ListLoadingState.loading => const EnhancedLoadingState(
          message: 'Loading activities...',
          showBackground: true,
        ),
        _ListLoadingState.empty => EnhancedEmptyState(
          icon: Icons.inbox,
          title: 'No Activities Yet',
          message: 'Start by creating your first activity to get things going',
          actionLabel: 'Create Activity',
          onAction: () => debugPrint('Create activity pressed'),
        ),
        _ListLoadingState.error => EnhancedErrorState(
          title: 'Oops! Something went wrong',
          message:
              _errorMessage ??
              'We encountered an error while loading activities',
          actionLabel: 'Try Again',
          onAction: _loadActivities,
        ),
        _ListLoadingState.loaded => ListView.builder(
          padding: const EdgeInsets.all(AppDesignSystem.spacing16),
          itemCount: _activities.length,
          itemBuilder: (context, index) {
            final activity = _activities[index];
            return Card(
              margin: const EdgeInsets.only(bottom: AppDesignSystem.spacing12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(AppDesignSystem.spacing16),
                leading: Container(
                  padding: const EdgeInsets.all(AppDesignSystem.spacing8),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      AppDesignSystem.radiusMedium,
                    ),
                  ),
                  child: Icon(
                    Icons.agriculture,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: Text(
                  activity,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => debugPrint('Edit: $activity'),
                  tooltip: 'Edit Activity',
                ),
              ),
            );
          },
        ),
      },
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => debugPrint('Add activity'),
        icon: const Icon(Icons.add),
        label: const Text('New Activity'),
      ),
    );
  }
}

/// Example of a confirmation dialog
class DialogExample extends StatelessWidget {
  const DialogExample({super.key});

  void _showDeleteConfirmation(BuildContext context) {
    EnhancedDialog.show(
      context,
      title: 'Delete Activity',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning, size: 48, color: Colors.orange.shade600),
          const SizedBox(height: AppDesignSystem.spacing16),
          Text(
            'Are you sure you want to delete "Rice Planting Campaign"?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppDesignSystem.spacing8),
          Text(
            'This action cannot be undone.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
      actions: [
        EnhancedButton(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
          variant: ButtonVariant.secondary,
          size: ButtonSize.medium,
        ),
        EnhancedButton(
          label: 'Delete',
          onPressed: () {
            Navigator.pop(context);
            EnhancedSnackBar.showSuccess(context, 'Activity deleted');
          },
          variant: ButtonVariant.primary,
          size: ButtonSize.medium,
          icon: const Icon(Icons.delete),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dialog Examples')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _showDeleteConfirmation(context),
              child: const Text('Show Delete Confirmation'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Example of different button variants
class ButtonsExample extends StatelessWidget {
  const ButtonsExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Button Examples')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDesignSystem.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Primary Buttons
            Text(
              'Primary Buttons',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppDesignSystem.spacing16),
            EnhancedButton(
              label: 'Large Button',
              onPressed: () {},
              size: ButtonSize.large,
            ),
            const SizedBox(height: AppDesignSystem.spacing12),
            EnhancedButton(
              label: 'Medium Button',
              onPressed: () {},
              size: ButtonSize.medium,
              icon: const Icon(Icons.check),
            ),
            const SizedBox(height: AppDesignSystem.spacing12),
            EnhancedButton(
              label: 'Small Button',
              onPressed: () {},
              size: ButtonSize.small,
            ),
            const SizedBox(height: AppDesignSystem.spacing32),

            // Secondary Buttons
            Text(
              'Secondary Buttons',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppDesignSystem.spacing16),
            EnhancedButton(
              label: 'Secondary Action',
              onPressed: () {},
              variant: ButtonVariant.secondary,
              size: ButtonSize.medium,
            ),
            const SizedBox(height: AppDesignSystem.spacing32),

            // Tertiary Buttons
            Text(
              'Tertiary Buttons',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppDesignSystem.spacing16),
            EnhancedButton(
              label: 'Learn More',
              onPressed: () {},
              variant: ButtonVariant.tertiary,
              size: ButtonSize.medium,
            ),
            const SizedBox(height: AppDesignSystem.spacing32),

            // Loading State
            Text(
              'Loading State',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppDesignSystem.spacing16),
            EnhancedButton(
              label: 'Processing...',
              onPressed: () {},
              isLoading: true,
            ),
            const SizedBox(height: AppDesignSystem.spacing32),

            // Disabled State
            Text(
              'Disabled State',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppDesignSystem.spacing16),
            EnhancedButton(
              label: 'Disabled Button',
              onPressed: () {},
              isEnabled: false,
            ),
          ],
        ),
      ),
    );
  }
}
