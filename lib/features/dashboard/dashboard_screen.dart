import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/theme/app_colors.dart";
import "dashboard_controller.dart";

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardControllerProvider);
    final controller = ref.read(dashboardControllerProvider.notifier);

    final stats = state.stats ?? {};
    final daily = (stats["daily_stats"] as Map?) ?? {};
    final hours = (stats["hours"] as Map?) ?? {};
    final overtime = (stats["overtime_hours"] as Map?) ?? {};
    final actualHours = daily["actual_hours"] ?? 0;
    final actualApplicants = daily["actual_applicant_count"] ?? 0;

    final rows = [
      {"label": "Open Positions", "value": daily["open_positions"] ?? 0},
      {"label": "Scheduled Hours", "value": "${daily["schedule_hours"] ?? 0} Hrs"},
      {"label": "Posted Hours", "value": "${daily["posted_hours"] ?? 0} Hrs"},
      {"label": "Actual Hours", "value": "${daily["actual_hours"] ?? 0} Hrs"},
      {"label": "Clocked In Employee", "value": "${daily["actual_applicant_count"] ?? 0}"},
      {"label": "Scheduled Employee", "value": "${daily["scheduled_applicant_count"] ?? 0}"},
      {"label": "Overtime", "value": "${overtime["confirmed_overtime_hours"] ?? 0} Hrs"},
      {"label": "Shift applicants", "value": stats["shift_applicants"] ?? 0},
      {"label": "Missed Punches", "value": stats["missed_punches"] ?? 0},
      {"label": "Invited Nurses", "value": stats["invited_nurses"] ?? 0},
      {"label": "Messages", "value": stats["unread_messages"] ?? 0},
      {"label": "Walk-in Nurses", "value": "${stats["walk_in_nurses"] ?? 0} Hrs"},
      {"label": "Active Employees", "value": stats["active_nurses"] ?? 0},
      {"label": "Unassigned Employees", "value": stats["unassigned_nurses"] ?? 0},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 64),
            children: [
              _FacilitySelector(
                name: state.selectedFacilityName ?? "Select Facility",
                facilities: state.facilities,
                onSelect: controller.selectFacility,
              ),
              const SizedBox(height: 12),
              _DateRow(
                date: state.date,
                onPrev: () => controller.setDate(
                  state.date.subtract(const Duration(days: 1)),
                ),
                onNext: () => controller.setDate(
                  state.date.add(const Duration(days: 1)),
                ),
                onPick: (picked) => controller.setDate(picked),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _ChipButton(label: "Overtime", onTap: () {}),
                    const SizedBox(width: 8),
                    _ChipButton(label: "Download PDF", onTap: () {}),
                    const SizedBox(width: 8),
                    _FilterButton(
                      count: state.selectedDepartments.length,
                      onTap: () => _openDepartmentFilter(
                        context,
                        state.departments,
                        state.selectedDepartments,
                        controller.toggleDepartment,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyLarge,
                  children: [
                    const TextSpan(text: "You have "),
                    TextSpan(
                      text: "$actualApplicants",
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(text: actualApplicants == 1 ? " person" : " people"),
                    const TextSpan(text: " working "),
                    TextSpan(
                      text: "$actualHours",
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const TextSpan(text: " hours today"),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...rows.map(
                (row) => _StatRow(
                  label: row["label"].toString(),
                  value: row["value"].toString(),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
          if (state.loading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.date,
    required this.onPrev,
    required this.onNext,
    required this.onPick,
  });

  final DateTime date;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrev,
          ),
          Expanded(
            child: Center(
              child: Text(
                "${date.day}",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) onPick(picked);
            },
            child: Text(
              "${date.month}/${date.day}/${date.year}",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.grey3),
          borderRadius: BorderRadius.circular(8),
          color: AppColors.white,
        ),
        child: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: AppColors.black),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _QuickSummaryCard extends StatelessWidget {
  const _QuickSummaryCard({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTight = constraints.maxWidth < 420;
        final titleText = Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
          maxLines: isTight ? 2 : 1,
          overflow: TextOverflow.ellipsis,
        );
        final valueText = FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(
            value,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(color: AppColors.primary),
          ),
        );

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.lightSkyBlue,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lightGray),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleText,
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: valueText,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FacilitySelector extends StatelessWidget {
  const _FacilitySelector({
    required this.name,
    required this.facilities,
    required this.onSelect,
  });

  final String name;
  final List<Map<String, dynamic>> facilities;
  final void Function(String id, String name) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: const Icon(Icons.favorite, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<Map<String, dynamic>>(
                    tooltip: "Select Facility",
                    onSelected: (value) {
                      final id = value["id"]?.toString() ?? "";
                      final name = value["name"]?.toString() ?? "";
                      onSelect(id, name);
                    },
                    itemBuilder: (context) => facilities
                        .map(
                          (f) => PopupMenuItem<Map<String, dynamic>>(
                            value: f,
                            child: Text(f["name"]?.toString() ?? ""),
                          ),
                        )
                        .toList(),
                    child: const Icon(Icons.keyboard_arrow_down),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.lightGray),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.filter_list, size: 18, color: AppColors.greyBlue),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                "Departments",
                style: Theme.of(context).textTheme.labelLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "$count",
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

void _openDepartmentFilter(
  BuildContext context,
  List<Map<String, dynamic>> departments,
  List<String> selected,
  ValueChanged<String> onToggle,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      String query = "";
      return StatefulBuilder(
        builder: (context, setState) {
          final filtered = departments.where((d) {
            final name = d["name"]?.toString().toLowerCase() ?? "";
            return name.contains(query.toLowerCase());
          }).toList();
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 4,
                  width: 32,
                  decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                Text("Departments",
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    hintText: "Search",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => query = value),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final dept = filtered[index];
                      final id = dept["id"]?.toString() ?? "";
                      final name = dept["name"]?.toString() ?? "";
                      final isSelected = selected.contains(id);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (_) => onToggle(id),
                        title: Text(name),
                        controlAffinity: ListTileControlAffinity.trailing,
                        activeColor: AppColors.primary,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      );
    },
  );
}
