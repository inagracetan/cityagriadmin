import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class NavigationProvider extends ChangeNotifier {
  List<Widget>? actions;
  Widget? fab;
  String title = 'LGU Agri App';
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  void updateLayout({List<Widget>? actions, Widget? fab, String? title, int? selectedIndex}) {
    // Only proceed if there are actual changes
    final bool hasTitleChange = title != null && this.title != title;
    final bool hasIndexChange = selectedIndex != null && _selectedIndex != selectedIndex;
    final bool hasActionsChange = actions != null; // Comparing lists is tricky, assume change if provided
    final bool hasFabChange = fab != null;

    if (!hasTitleChange && !hasIndexChange && !hasActionsChange && !hasFabChange) return;

    void update() {
      if (actions != null) this.actions = actions;
      if (fab != null) this.fab = fab;
      if (title != null) this.title = title;
      if (selectedIndex != null) _selectedIndex = selectedIndex;
      notifyListeners();
    }

    // Only use addPostFrameCallback if we are in the middle of a build
    if (WidgetsBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => update());
    } else {
      update();
    }
  }

  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }
}
