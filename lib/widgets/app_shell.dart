import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

import "../routes/app_routes.dart";

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Facility"),
      ),
      drawer: _AppDrawer(),
      body: child,
    );
  }
}

class _AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final current = GoRouterState.of(context).uri.toString();
    final grouped = <String, List<AppRoute>>{};
    for (final item in AppRoutes.menu) {
      final key = item.group ?? "General";
      grouped.putIfAbsent(key, () => []).add(item);
    }
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.white),
            child: Text("Facility"),
          ),
          for (final entry in grouped.entries) ...[
            if (entry.key != "General")
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  entry.key,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: Colors.grey[700]),
                ),
              ),
            for (final item in entry.value)
              ListTile(
                title: Text(item.label),
                selected: current == item.path,
                onTap: () {
                  Navigator.of(context).pop();
                  context.go(item.path);
                },
              ),
            const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}
