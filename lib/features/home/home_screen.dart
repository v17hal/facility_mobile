import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../core/config/app_env.dart";
import "../../core/config/env_controller.dart";

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final env = ref.watch(envControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Facility Mobile"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Environment: ${_label(env)}",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            const Text(
              "This is the base shell. UI and flows will be matched to the web app.",
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.push("/settings/env"),
              child: const Text("Switch Environment"),
            ),
          ],
        ),
      ),
    );
  }
}

String _label(AppEnvironment env) {
  switch (env) {
    case AppEnvironment.dev:
      return "Dev";
    case AppEnvironment.devsc:
      return "DevSC";
    case AppEnvironment.qa:
      return "QA";
    case AppEnvironment.stage:
      return "Stage";
    case AppEnvironment.prod:
      return "Prod";
  }
}
