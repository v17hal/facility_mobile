import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "routes/app_router.dart";
import "core/theme/app_theme.dart";

void main() {
  runApp(const ProviderScope(child: FacilityApp()));
}

class FacilityApp extends StatelessWidget {
  const FacilityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final router = ref.watch(routerProvider);
        return MaterialApp.router(
          title: "Facility Mobile",
          theme: AppTheme.light(),
          routerConfig: router,
        );
      },
    );
  }
}
