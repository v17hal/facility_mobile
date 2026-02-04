import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/config/app_env.dart";
import "../../core/config/env_controller.dart";

class EnvSwitcherScreen extends ConsumerWidget {
  const EnvSwitcherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(envControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Environment"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Select environment (applies immediately).",
          ),
          const SizedBox(height: 12),
          for (final env in AppEnvironment.values)
            RadioListTile<AppEnvironment>(
              value: env,
              groupValue: current,
              title: Text(_label(env)),
              onChanged: (value) async {
                if (value == null) return;
                await ref.read(envControllerProvider.notifier).setEnv(value);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Switched to ${_label(value)}")),
                  );
                }
              },
            ),
        ],
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
