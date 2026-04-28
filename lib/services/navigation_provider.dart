import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  List<Widget>? actions;
  Widget? fab;
  String title = 'LGU Agri App';

  void updateLayout({List<Widget>? actions, Widget? fab, String? title}) {
    // Post frame to avoid build conflicts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      this.actions = actions;
      this.fab = fab;
      if (title != null) this.title = title;
      notifyListeners();
    });
  }
}
