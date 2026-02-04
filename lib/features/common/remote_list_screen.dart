import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/network/api_provider.dart";
import "../../core/network/api_service.dart";
import "../../core/theme/app_colors.dart";

class RemoteListScreen extends ConsumerWidget {
  const RemoteListScreen({
    super.key,
    required this.title,
    required this.endpoint,
    this.params,
    this.itemTitle,
    this.itemSubtitle,
  });

  final String title;
  final String endpoint;
  final Map<String, dynamic>? params;
  final String Function(dynamic item)? itemTitle;
  final String Function(dynamic item)? itemSubtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ApiService(ref.watch(apiClientProvider));
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder(
        future: api.get(endpoint, params: params),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Failed to load $title",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          final data = snapshot.data?.data;
          final list = _extractList(data);
          if (list.isEmpty) {
            return Center(
              child: Text(
                "No data",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = list[index];
              final title = itemTitle?.call(item) ?? _fallbackTitle(item, index);
              final subtitle = itemSubtitle?.call(item) ?? _fallbackSubtitle(item);
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.lightGray),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

List<dynamic> _extractList(dynamic data) {
  if (data is Map<String, dynamic>) {
    final nested = data["data"];
    if (nested is List) return nested;
    if (nested is Map<String, dynamic> && nested["results"] is List) {
      return nested["results"] as List;
    }
    if (data["results"] is List) return data["results"] as List;
  }
  if (data is List) return data;
  return [];
}

String _fallbackTitle(dynamic item, int index) {
  if (item is Map) {
    return (item["name"] ??
            item["title"] ??
            item["employee_name"] ??
            item["facility_name"] ??
            "Item ${index + 1}")
        .toString();
  }
  return "Item ${index + 1}";
}

String _fallbackSubtitle(dynamic item) {
  if (item is Map) {
    return (item["email"] ??
            item["status"] ??
            item["job_title"] ??
            item["role"] ??
            "")
        .toString();
  }
  return "";
}
