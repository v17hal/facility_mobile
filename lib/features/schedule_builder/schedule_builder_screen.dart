import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/theme/app_colors.dart";
import "schedule_builder_controller.dart";

class ScheduleBuilderScreen extends ConsumerWidget {
  const ScheduleBuilderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const ScheduleBuilderDepartmentScreen();
  }
}

class ScheduleBuilderDepartmentScreen extends ConsumerWidget {
  const ScheduleBuilderDepartmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scheduleBuilderControllerProvider);
    final controller = ref.read(scheduleBuilderControllerProvider.notifier);
    final departmentList = _buildDepartmentList(state.dataList);
    final selectedId = state.selectedDepartmentId ?? "all";

    return Scaffold(
      appBar: AppBar(title: const Text("Schedule Builder")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(title: "Departments"),
          const SizedBox(height: 10),
          if (state.loading)
            const LinearProgressIndicator(minHeight: 2)
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.lightGray),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: departmentList.map((dept) {
                  final id = dept["department"]?["id"]?.toString();
                  final name = dept["department"]?["name"]?.toString() ?? "";
                  final count = dept["count"]?.toString() ?? "0";
                  final isSelected =
                      (id == selectedId) || (id == null && selectedId == "all");
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () {
                        controller.selectDepartment(id ?? "all");
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ScheduleBuilderShiftScreen(
                              departmentId: id ?? "all",
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.offwhite,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    Theme.of(context).textTheme.labelLarge?.copyWith(
                                          color: isSelected
                                              ? Colors.white
                                              : AppColors.black,
                                        ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.lightPink,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                count,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class ScheduleBuilderShiftScreen extends ConsumerStatefulWidget {
  const ScheduleBuilderShiftScreen({super.key, required this.departmentId});

  final String departmentId;

  @override
  ConsumerState<ScheduleBuilderShiftScreen> createState() =>
      _ScheduleBuilderShiftScreenState();
}

class _ScheduleBuilderShiftScreenState
    extends ConsumerState<ScheduleBuilderShiftScreen> {
  String query = "";

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scheduleBuilderControllerProvider);
    final controller = ref.read(scheduleBuilderControllerProvider.notifier);
    final departmentList = _buildDepartmentList(state.dataList);
    final selectedDepartment = _findDepartment(
      departmentList,
      widget.departmentId,
    );
    final shifts = _dedupeShifts(
      (selectedDepartment?["shifts"] as List?) ?? [],
    );
    final filtered = shifts.where((shift) {
      final name = _shiftName(shift).toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Shifts"),
        actions: [
          IconButton(
            onPressed: shifts.length < 2
                ? null
                : () => _openMergeSheet(
                      context,
                      shifts: shifts.cast<Map<String, dynamic>>(),
                      onMerge: controller.mergeOpenings,
                    ),
            icon: const Icon(Icons.merge_type),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: "Search shifts",
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => setState(() => query = value),
          ),
          const SizedBox(height: 12),
          _SectionHeader(title: "Shifts"),
          const SizedBox(height: 10),
          if (state.loading)
            const LinearProgressIndicator(minHeight: 2)
          else if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text("No shifts found"),
            )
          else
            ...filtered.map((shift) {
              final id = shift["id"]?.toString() ?? "";
              final name = _shiftName(shift);
              final time = _shiftTimeRange(shift);
              final openings = _shiftOpenings(shift);
              final units =
                  _unitsString((shift["units"] as List?) ?? const []);
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: InkWell(
                  onTap: () {
                    controller.selectShift(id);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ScheduleBuilderDetailScreen(
                          shiftId: id,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.lightGray),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            _Pill(text: "SB"),
                            const SizedBox(width: 8),
                            _Pill(text: "$openings open", filled: true),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (time.isNotEmpty)
                          Text(
                            time,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.greyBlue),
                          ),
                        const SizedBox(height: 6),
                        Text(
                          units,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.greyBlue),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openShiftEditor(
          context,
          jobTitles: state.jobTitles,
          departments: state.departments,
          units: state.units,
          colors: state.colors,
          onSave: (payload) => controller.createShift(payload),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ScheduleBuilderDetailScreen extends ConsumerWidget {
  const ScheduleBuilderDetailScreen({super.key, required this.shiftId});

  final String shiftId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scheduleBuilderControllerProvider);
    final controller = ref.read(scheduleBuilderControllerProvider.notifier);
    final shift = state.selectedShift ??
        _findShiftById(state.dataList, shiftId);
    final openings = _shiftOpeningsList(shift);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Shift Details"),
        actions: [
          IconButton(
            onPressed: shift == null
                ? null
                : () => _openShiftEditor(
                      context,
                      jobTitles: state.jobTitles,
                      departments: state.departments,
                      units: state.units,
                      colors: state.colors,
                      initialShift: shift,
                      onSave: (payload) => controller.updateShift(
                        shift["id"]?.toString() ?? "",
                        payload,
                      ),
                    ),
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            onPressed: shift == null
                ? null
                : () => _confirmDelete(
                      context,
                      onConfirm: () =>
                          controller.deleteShift(shift["id"]?.toString() ?? ""),
                    ),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: state.shiftLoading
          ? const Center(child: CircularProgressIndicator())
          : shift == null
              ? const Center(child: Text("Select a shift"))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _ShiftHeader(shift: shift),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Expanded(
                          child: _SectionHeader(title: "Shift Details"),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final id = shift["id"]?.toString() ?? "";
                            if (id.isEmpty) return;
                            final conflicts =
                                await controller.fetchJobTitleConflicts(id);
                            if (!context.mounted) return;
                            _openConflictsSheet(context, conflicts);
                          },
                          icon: const Icon(Icons.warning_amber, size: 18),
                          label: const Text("Conflicts"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _ShiftDetails(shift: shift),
                    const SizedBox(height: 16),
                    _SectionHeader(title: "Openings"),
                    const SizedBox(height: 8),
                    if (openings.isEmpty)
                      const Text("No openings found")
                    else
                      ...openings.map((opening) {
                        final unit =
                            opening["unit_name"]?.toString() ??
                            opening["unit"]?["name"]?.toString() ??
                            opening["unit"]?["title"]?.toString() ??
                            "Unit";
                        final count = opening["total_openings"] ??
                            opening["no_of_child_openings"] ??
                            opening["open_positions"] ??
                            0;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.lightGray),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      unit,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  _Pill(text: "$count open", filled: true),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "0/$count filled",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.greyBlue),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  ],
                ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: AppColors.greyBlue),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Divider(height: 1, color: AppColors.lightGray),
        ),
      ],
    );
  }
}

class _ScheduleMailbox extends StatefulWidget {
  const _ScheduleMailbox({
    required this.loading,
    required this.shiftLoading,
    required this.dataList,
    required this.selectedDepartmentId,
    required this.selectedShiftId,
    required this.selectedShift,
    required this.onSelectDepartment,
    required this.onSelectShift,
    required this.jobTitles,
    required this.departments,
    required this.units,
    required this.colors,
    required this.onCreateShift,
    required this.onUpdateShift,
    required this.onDeleteShift,
    required this.onMerge,
    required this.onCheckConflicts,
  });

  final bool loading;
  final bool shiftLoading;
  final List<Map<String, dynamic>> dataList;
  final String? selectedDepartmentId;
  final String? selectedShiftId;
  final Map<String, dynamic>? selectedShift;
  final ValueChanged<String> onSelectDepartment;
  final ValueChanged<String> onSelectShift;
  final List<Map<String, dynamic>> jobTitles;
  final List<Map<String, dynamic>> departments;
  final List<Map<String, dynamic>> units;
  final List<Map<String, dynamic>> colors;
  final Future<void> Function(Map<String, dynamic>) onCreateShift;
  final Future<void> Function(String id, Map<String, dynamic>) onUpdateShift;
  final Future<void> Function(String id) onDeleteShift;
  final Future<bool> Function(List<String> ids) onMerge;
  final Future<List<Map<String, dynamic>>> Function(String id) onCheckConflicts;

  @override
  State<_ScheduleMailbox> createState() => _ScheduleMailboxState();
}

class _ScheduleMailboxState extends State<_ScheduleMailbox> {
  String query = "";

  @override
  Widget build(BuildContext context) {
    final departmentList = _buildDepartmentList(widget.dataList);
    final selectedDepartment = _findDepartment(
      departmentList,
      widget.selectedDepartmentId,
    );
    final shifts = (selectedDepartment?["shifts"] as List?) ?? [];
    final filtered = shifts.where((shift) {
      final name = _shiftName(shift).toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();

    final detail = widget.selectedShift;
    final openings = _shiftOpeningsList(detail);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        final deptPane = _ScheduleDeptPane(
          departments: departmentList,
          selectedId: selectedDepartment?["department"]?["id"]?.toString(),
          onSelect: widget.onSelectDepartment,
        );
        final shiftsPane = _ScheduleShiftPane(
          loading: widget.loading,
          shifts: filtered.cast<Map<String, dynamic>>(),
          selectedShiftId: widget.selectedShiftId,
          query: query,
          onQuery: (value) => setState(() => query = value),
          onSelect: widget.onSelectShift,
          onAdd: () => _openShiftEditor(
            context,
            jobTitles: widget.jobTitles,
            departments: widget.departments,
            units: widget.units,
            colors: widget.colors,
            onSave: (payload) => widget.onCreateShift(payload),
          ),
          onEdit: () {
            final selected = widget.selectedShift;
            if (selected == null) return;
            _openShiftEditor(
              context,
              jobTitles: widget.jobTitles,
              departments: widget.departments,
              units: widget.units,
              colors: widget.colors,
              initialShift: selected,
              onSave: (payload) => widget.onUpdateShift(
                selected["id"]?.toString() ?? "",
                payload,
              ),
            );
          },
          onDelete: () {
            final id = widget.selectedShiftId;
            if (id == null) return;
            _confirmDelete(context, onConfirm: () => widget.onDeleteShift(id));
          },
          onMerge: () => _openMergeSheet(
            context,
            shifts: shifts.cast<Map<String, dynamic>>(),
            onMerge: widget.onMerge,
          ),
        );
        final detailPane = _ScheduleDetailPane(
          loading: widget.shiftLoading,
          shift: detail,
          openings: openings,
          onCheckConflicts: widget.onCheckConflicts,
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 200, child: deptPane),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    shiftsPane,
                    const SizedBox(height: 12),
                    Expanded(child: detailPane),
                  ],
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            deptPane,
            const SizedBox(height: 12),
            shiftsPane,
            const SizedBox(height: 12),
            Expanded(child: detailPane),
          ],
        );
      },
    );
  }
}

class _ScheduleDeptPane extends StatelessWidget {
  const _ScheduleDeptPane({
    required this.departments,
    required this.selectedId,
    required this.onSelect,
  });

  final List<Map<String, dynamic>> departments;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: "Departments"),
          const SizedBox(height: 10),
          ...departments.map((dept) {
            final id = dept["department"]?["id"]?.toString() ?? "";
            final name = dept["department"]?["name"]?.toString() ?? "";
            final count = dept["count"]?.toString() ?? "0";
            final selected = id == selectedId;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => onSelect(id),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.lightPink : AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.lightGray,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 36,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : AppColors.lightGray,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppColors.black,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : AppColors.greyBlue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          count,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ScheduleShiftPane extends StatelessWidget {
  const _ScheduleShiftPane({
    required this.loading,
    required this.shifts,
    required this.selectedShiftId,
    required this.query,
    required this.onQuery,
    required this.onSelect,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onMerge,
  });

  final bool loading;
  final List<Map<String, dynamic>> shifts;
  final String? selectedShiftId;
  final String query;
  final ValueChanged<String> onQuery;
  final ValueChanged<String> onSelect;
  final VoidCallback onAdd;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMerge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SectionHeader(title: "Shifts"),
              ),
              IconButton(
                onPressed: onAdd,
                icon: const Icon(Icons.add_circle, color: AppColors.primary),
              ),
              IconButton(
                onPressed: selectedShiftId == null ? null : onEdit,
                icon: const Icon(Icons.edit, color: AppColors.greyBlue),
              ),
              IconButton(
                onPressed: selectedShiftId == null ? null : onDelete,
                icon: const Icon(Icons.delete, color: AppColors.greyBlue),
              ),
              IconButton(
                onPressed: shifts.length < 2 ? null : onMerge,
                icon: const Icon(Icons.merge_type, color: AppColors.greyBlue),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              hintText: "Search shifts",
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: onQuery,
          ),
          const SizedBox(height: 10),
          if (loading)
            const LinearProgressIndicator(minHeight: 2)
          else if (shifts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text("No shifts found"),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: shifts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final shift = shifts[index];
                final id = shift["id"]?.toString() ?? "";
                final selected = id == selectedShiftId;
                final name = _shiftName(shift);
                final time = _shiftTimeRange(shift);
                final openings = _shiftOpenings(shift);
                final units =
                    _unitsString((shift["units"] as List?) ?? const []);
                final filledText = "0/$openings filled";
                final percent = openings > 0 ? 0.0 : 0.0;
                return InkWell(
                  onTap: () => onSelect(id),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.lightPink : AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color:
                            selected ? AppColors.primary : AppColors.lightGray,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            _Pill(text: "SB"),
                            const SizedBox(width: 8),
                            _Pill(text: "$openings open", filled: true),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (time.isNotEmpty)
                          Text(
                            time,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.greyBlue),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          units,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.greyBlue),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              filledText,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: 72,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: percent,
                                  minHeight: 6,
                                  backgroundColor:
                                      AppColors.lightPink.withOpacity(0.4),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "${(percent * 100).round()}%",
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: AppColors.greyBlue),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ScheduleDetailPane extends StatelessWidget {
  const _ScheduleDetailPane({
    required this.loading,
    required this.shift,
    required this.openings,
    required this.onCheckConflicts,
  });

  final bool loading;
  final Map<String, dynamic>? shift;
  final List<Map<String, dynamic>> openings;
  final Future<List<Map<String, dynamic>>> Function(String id) onCheckConflicts;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (shift == null) {
      return const Center(child: Text("Select a shift"));
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView(
        children: [
          Row(
            children: [
              Expanded(
                child: _SectionHeader(title: "Shift Details"),
              ),
              TextButton.icon(
                onPressed: () async {
                  final id = shift!["id"]?.toString() ?? "";
                  if (id.isEmpty) return;
                  final conflicts = await onCheckConflicts(id);
                  if (!context.mounted) return;
                  _openConflictsSheet(context, conflicts);
                },
                icon: const Icon(Icons.warning_amber, size: 18),
                label: const Text("Conflicts"),
              ),
            ],
          ),
          _ShiftDetails(shift: shift!),
          const SizedBox(height: 12),
          _SectionHeader(title: "Openings"),
          const SizedBox(height: 8),
          if (openings.isEmpty)
            const Text("No openings found")
          else
            ...openings.map((opening) {
              final unit =
                  opening["unit_name"]?.toString() ??
                  opening["unit"]?["name"]?.toString() ??
                  "Unit";
              final count = opening["total_openings"] ?? 0;
              final filledText = "0/$count filled";
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.lightGray),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            unit,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        _Pill(text: "$count open", filled: true),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      filledText,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.greyBlue),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.hasSelection,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final bool hasSelection;
  final VoidCallback onAdd;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: AppColors.white,
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text("Add"),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: hasSelection ? onEdit : null,
              icon: const Icon(Icons.edit_outlined),
              label: const Text("Edit"),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: hasSelection ? onDelete : null,
              icon: const Icon(Icons.delete_outline),
              label: const Text("Delete"),
            ),
          ),
        ],
      ),
    );
  }
}

void _confirmDelete(BuildContext context, {required VoidCallback onConfirm}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Delete Shift"),
      content: const Text("Are you sure you want to delete this shift template?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          child: const Text("Delete"),
        ),
      ],
    ),
  );
}

void _openShiftEditor(
  BuildContext context, {
  required List<Map<String, dynamic>> jobTitles,
  required List<Map<String, dynamic>> departments,
  required List<Map<String, dynamic>> units,
  required List<Map<String, dynamic>> colors,
  required Future<void> Function(Map<String, dynamic>) onSave,
  Map<String, dynamic>? initialShift,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (context) {
      return _ShiftEditorSheet(
        jobTitles: jobTitles,
        departments: departments,
        units: units,
        colors: colors,
        onSave: onSave,
        initialShift: initialShift,
      );
    },
  );
}

class _ShiftEditorSheet extends StatefulWidget {
  const _ShiftEditorSheet({
    required this.jobTitles,
    required this.departments,
    required this.units,
    required this.colors,
    required this.onSave,
    this.initialShift,
  });

  final List<Map<String, dynamic>> jobTitles;
  final List<Map<String, dynamic>> departments;
  final List<Map<String, dynamic>> units;
  final List<Map<String, dynamic>> colors;
  final Future<void> Function(Map<String, dynamic>) onSave;
  final Map<String, dynamic>? initialShift;

  @override
  State<_ShiftEditorSheet> createState() => _ShiftEditorSheetState();
}

class _ShiftEditorSheetState extends State<_ShiftEditorSheet> {
  late TextEditingController nameController;
  late TextEditingController mealController;
  late TextEditingController patientController;
  late TextEditingController openingsController;

  String? selectedDepartmentId;
  String? selectedColorId;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  bool isOptional = false;
  List<int> selectedDays = [];
  List<String> selectedJobTitles = [];
  List<String> selectedUnits = [];

  @override
  void initState() {
    super.initState();
    final shift = widget.initialShift ?? {};
    nameController = TextEditingController(text: _shiftName(shift));
    mealController =
        TextEditingController(text: _valueToText(_shiftMeal(shift)));
    patientController =
        TextEditingController(text: _valueToText(_shiftPatient(shift)));
    openingsController =
        TextEditingController(text: _valueToText(_shiftOpenings(shift)));
    selectedDepartmentId = _shiftDepartmentId(shift);
    selectedColorId = _shiftColorId(shift);
    selectedDays = _shiftDays(shift);
    selectedJobTitles = _shiftJobTitleIds(shift);
    selectedUnits = _shiftUnitIds(shift);
    final times = _shiftTimes(shift);
    startTime = times.$1;
    endTime = times.$2;
    isOptional = _shiftIsOptional(shift);
  }

  @override
  void dispose() {
    nameController.dispose();
    mealController.dispose();
    patientController.dispose();
    openingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.9;
    return SafeArea(
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                height: 4,
                width: 36,
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.initialShift == null ? "Add Shift" : "Edit Shift",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    _FieldLabel("Shift Name"),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        hintText: "Enter shift name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _FieldLabel("Department"),
                    DropdownButtonFormField<String>(
                      value: selectedDepartmentId,
                      items: widget.departments
                          .map(
                            (d) => DropdownMenuItem(
                              value: d["id"]?.toString(),
                              child: Text(d["name"]?.toString() ?? ""),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => selectedDepartmentId = value),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _FieldLabel("Shift Time"),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime:
                                    startTime ?? const TimeOfDay(hour: 7, minute: 0),
                              );
                              if (picked != null) {
                                setState(() => startTime = picked);
                              }
                            },
                            child: Text(_formatTime(startTime)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime:
                                    endTime ?? const TimeOfDay(hour: 15, minute: 0),
                              );
                              if (picked != null) {
                                setState(() => endTime = picked);
                              }
                            },
                            child: Text(_formatTime(endTime)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _NumberField(
                            label: "Meal (min)",
                            controller: mealController,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _NumberField(
                            label: "Patient",
                            controller: patientController,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _NumberField(
                            label: "Openings",
                            controller: openingsController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _FieldLabel("Days Needed"),
                    Wrap(
                      spacing: 8,
                      children: List.generate(7, (index) {
                        final selected = selectedDays.contains(index);
                        return ChoiceChip(
                          label: Text(_dayLabel(index)),
                          selected: selected,
                          selectedColor: AppColors.lightPink,
                          onSelected: (_) {
                            setState(() {
                              if (selected) {
                                selectedDays.remove(index);
                              } else {
                                selectedDays.add(index);
                              }
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    _FieldLabel("Job Titles"),
                    _MultiSelectButton(
                      label: "Select job titles",
                      count: selectedJobTitles.length,
                      onTap: () async {
                        final result = await _openMultiSelectSheet(
                          context,
                          title: "Job Titles",
                          items: widget.jobTitles,
                          selected: selectedJobTitles,
                        );
                        if (result != null) {
                          setState(() => selectedJobTitles = result);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _FieldLabel("Units"),
                    _MultiSelectButton(
                      label: "Select units",
                      count: selectedUnits.length,
                      onTap: () async {
                        final result = await _openUnitSelectSheet(
                          context,
                          units: widget.units,
                          selected: selectedUnits,
                        );
                        if (result != null) {
                          setState(() => selectedUnits = result);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _FieldLabel("Color"),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.colors.map((c) {
                        final id = c["id"]?.toString() ?? "";
                        final color = _parseColor(c) ?? AppColors.primary;
                        final selected = id == selectedColorId;
                        return InkWell(
                          onTap: () => setState(() => selectedColorId = id),
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected ? AppColors.black : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: isOptional,
                      onChanged: (value) => setState(() => isOptional = value),
                      title: const Text("Optional Shift"),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final errors = _validateShift(
                          name: nameController.text,
                          departmentId: selectedDepartmentId,
                          start: startTime,
                          end: endTime,
                          days: selectedDays,
                          jobTitles: selectedJobTitles,
                          units: selectedUnits,
                          meal: mealController.text,
                          patient: patientController.text,
                          openings: openingsController.text,
                          color: selectedColorId,
                        );
                        if (errors.isNotEmpty) {
                          _showValidation(context, errors.first);
                          return;
                        }
                        final parent = widget.initialShift?["parent_opening_data"];
                        final openingLayer =
                            widget.initialShift?["opening_layer"] as Map? ??
                                (parent is Map ? parent["opening_layer"] as Map? : null);
                        final payload = _buildShiftPayload(
                          name: nameController.text.trim(),
                          departmentId: selectedDepartmentId!,
                          start: startTime!,
                          end: endTime!,
                          days: selectedDays,
                          jobTitles: selectedJobTitles,
                          units: selectedUnits,
                          meal: int.parse(mealController.text),
                          patient: int.parse(patientController.text),
                          openings: int.parse(openingsController.text),
                          colorId: selectedColorId!,
                          isOptional: isOptional,
                          unitsData: widget.units,
                          openingId: widget.initialShift?["id"]?.toString(),
                          openingLayerId: openingLayer?["id"]?.toString(),
                        );
                        await widget.onSave(payload);
                        if (mounted) Navigator.pop(context);
                      },
                      child: const Text("Save"),
                    ),
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

class _NumberField extends StatelessWidget {
  const _NumberField({required this.label, required this.controller});
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _MultiSelectButton extends StatelessWidget {
  const _MultiSelectButton({
    required this.label,
    required this.count,
    required this.onTap,
  });

  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightGray),
          color: AppColors.offwhite,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

Future<List<String>?> _openMultiSelectSheet(
  BuildContext context, {
  required String title,
  required List<Map<String, dynamic>> items,
  required List<String> selected,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      final temp = [...selected];
      return StatefulBuilder(
        builder: (context, setState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: items.map((item) {
                        final id = item["id"]?.toString() ?? "";
                        final name = item["name"]?.toString() ?? "";
                        final checked = temp.contains(id);
                        return CheckboxListTile(
                          value: checked,
                          onChanged: (_) {
                            setState(() {
                              if (checked) {
                                temp.remove(id);
                              } else {
                                temp.add(id);
                              }
                            });
                          },
                          title: Text(name),
                          controlAffinity: ListTileControlAffinity.trailing,
                          activeColor: AppColors.primary,
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, temp),
                          child: const Text("Apply"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Future<List<String>?> _openUnitSelectSheet(
  BuildContext context, {
  required List<Map<String, dynamic>> units,
  required List<String> selected,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      final temp = [...selected];
      return StatefulBuilder(
        builder: (context, setState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Units", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: units.map((unit) {
                        final unitId = unit["id"]?.toString() ?? "";
                        final unitName = unit["name"]?.toString() ?? "";
                        final unitChecked = temp.contains(unitId);
                        final subunits = (unit["subunits"] as List?) ?? [];
                        return Column(
                          children: [
                            CheckboxListTile(
                              value: unitChecked,
                              onChanged: (_) {
                                setState(() {
                                  if (unitChecked) {
                                    temp.remove(unitId);
                                  } else {
                                    temp.add(unitId);
                                  }
                                });
                              },
                              title: Text(unitName),
                              controlAffinity: ListTileControlAffinity.trailing,
                              activeColor: AppColors.primary,
                            ),
                            ...subunits.map((sub) {
                              final subId = sub["id"]?.toString() ?? "";
                              final subName = sub["name"]?.toString() ?? "";
                              final subChecked = temp.contains(subId);
                              return Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: CheckboxListTile(
                                  value: subChecked,
                                  onChanged: (_) {
                                    setState(() {
                                      if (subChecked) {
                                        temp.remove(subId);
                                      } else {
                                        temp.add(subId);
                                      }
                                    });
                                  },
                                  title: Text(subName),
                                  controlAffinity: ListTileControlAffinity.trailing,
                                  activeColor: AppColors.primary,
                                ),
                              );
                            }),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, temp),
                          child: const Text("Apply"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

List<String> _validateShift({
  required String name,
  required String? departmentId,
  required TimeOfDay? start,
  required TimeOfDay? end,
  required List<int> days,
  required List<String> jobTitles,
  required List<String> units,
  required String meal,
  required String patient,
  required String openings,
  required String? color,
}) {
  final errors = <String>[];
  if (name.trim().isEmpty) errors.add("Shift name is required");
  if (departmentId == null || departmentId.isEmpty) {
    errors.add("Department is required");
  }
  if (start == null || end == null) errors.add("Shift time is required");
  if (days.isEmpty) errors.add("Select at least one day");
  if (jobTitles.isEmpty) errors.add("Select at least one job title");
  if (units.isEmpty) errors.add("Select at least one unit");
  if (meal.isEmpty) errors.add("Meal time is required");
  if (patient.isEmpty) errors.add("Patient count is required");
  if (openings.isEmpty) errors.add("Openings is required");
  if (color == null || color.isEmpty) errors.add("Color is required");
  return errors;
}

void _showValidation(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

Map<String, dynamic> _buildShiftPayload({
  required String name,
  required String departmentId,
  required TimeOfDay start,
  required TimeOfDay end,
  required List<int> days,
  required List<String> jobTitles,
  required List<String> units,
  required int meal,
  required int patient,
  required int openings,
  required String colorId,
  required bool isOptional,
  required List<Map<String, dynamic>> unitsData,
  String? openingId,
  String? openingLayerId,
}) {
  final unitOpenings = _buildUnitOpenings(
    selected: units,
    unitsData: unitsData,
    totalOpenings: openings,
  );
  final payload = <String, dynamic>{
    "name": name,
    "department": departmentId,
    "job_titles": jobTitles,
    "days": days,
    "total_openings": openings,
    "unit_openings": unitOpenings,
    "shift_layers": [
      {
        "order": 0,
        "start_time": _timeToApi(start),
        "end_time": _timeToApi(end),
        "meal_time": meal,
        "is_optional": isOptional,
        "patient_count": patient,
        "color": colorId,
      }
    ],
    "additional_settings": [],
  };
  if (openingId != null && openingId.isNotEmpty) {
    payload["opening_id"] = openingId;
  }
  if (openingLayerId != null && openingLayerId.isNotEmpty) {
    payload["shift_layers"][0]["opening_layer_id"] = openingLayerId;
  }
  return payload;
}

List<Map<String, dynamic>> _buildUnitOpenings({
  required List<String> selected,
  required List<Map<String, dynamic>> unitsData,
  required int totalOpenings,
}) {
  final openings = <Map<String, dynamic>>[];
  for (final unit in unitsData) {
    final unitId = unit["id"]?.toString() ?? "";
    final subunits = (unit["subunits"] as List?) ?? [];
    final selectedSubs = subunits
        .whereType<Map>()
        .where((s) => selected.contains(s["id"]?.toString() ?? ""))
        .map((s) => s["id"].toString())
        .toList();
    final hasUnit = selected.contains(unitId);
    if (hasUnit || selectedSubs.isNotEmpty) {
      openings.add({
        "total_openings": totalOpenings,
        "unit": unitId,
        "sub_unit": selectedSubs,
      });
    }
  }
  return openings;
}

String _formatTime(TimeOfDay? time) {
  if (time == null) return "Select time";
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minutes = time.minute.toString().padLeft(2, "0");
  final meridian = time.period == DayPeriod.am ? "AM" : "PM";
  return "$hour:$minutes $meridian";
}

String _timeToApi(TimeOfDay time) {
  final hh = time.hour.toString().padLeft(2, "0");
  final mm = time.minute.toString().padLeft(2, "0");
  return "$hh:$mm:00";
}

Color? _parseColor(Map<String, dynamic> color) {
  final raw = color["hex"] ??
      color["hex_code"] ??
      color["color_code"] ??
      color["code"];
  if (raw == null) return null;
  final hex = raw.toString().replaceAll("#", "");
  if (hex.length == 6) {
    return Color(int.parse("FF$hex", radix: 16));
  }
  return null;
}

String _dayLabel(int index) {
  const labels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
  return labels[index];
}

String _valueToText(Object? value) {
  if (value == null) return "";
  return value.toString();
}

String _shiftName(Map shift) {
  return (shift["name"] ??
          shift["shift_name"] ??
          shift["parent_name"] ??
          "Shift")
      .toString();
}

String _shiftTimeRange(Map shift) {
  String? start = shift["start_time"]?.toString();
  String? end = shift["end_time"]?.toString();
  final layer = shift["opening_layer"] as Map?;
  if (layer != null) {
    start ??= layer["start_time"]?.toString();
    end ??= layer["end_time"]?.toString();
  }
  if (start == null || end == null) {
    start ??= shift["parent_start_time"]?.toString();
    end ??= shift["parent_end_time"]?.toString();
  }
  if (start == null || end == null) return "";
  return _formatTimeRange(start, end);
}

String _shiftJobTitles(Map shift) {
  final titles = (shift["job_titles"] as List?) ?? [];
  if (titles.isEmpty) return "";
  return titles
      .map((t) => t["abbreviation"] ?? t["name"] ?? "")
      .where((t) => t.toString().isNotEmpty)
      .join(", ");
}

int _shiftOpenings(Map shift) {
  return shift["total_openings"] ??
      shift["no_of_child_openings"] ??
      shift["child_count"] ??
      1;
}

int _shiftMeal(Map shift) {
  final layer = shift["opening_layer"] as Map?;
  return layer?["meal_time"] ?? shift["meal_time"] ?? 0;
}

int _shiftPatient(Map shift) {
  final layer = shift["opening_layer"] as Map?;
  return layer?["patient_count"] ?? shift["patient_count"] ?? 0;
}

String? _shiftDepartmentId(Map shift) {
  final dept = shift["department"];
  if (dept is Map) return dept["id"]?.toString();
  return shift["department"]?.toString();
}

String? _shiftColorId(Map shift) {
  final layer = shift["opening_layer"] as Map?;
  if (layer?["color"] is Map) {
    return layer?["color"]?["id"]?.toString();
  }
  return layer?["color"]?.toString();
}

bool _shiftIsOptional(Map shift) {
  final layer = shift["opening_layer"] as Map?;
  return layer?["is_optional"] ?? shift["is_optional"] ?? false;
}

List<int> _shiftDays(Map shift) {
  final days = (shift["days_needed"] as List?) ?? [];
  return days.map((d) => int.tryParse(d.toString()) ?? 0).toList();
}

List<String> _shiftJobTitleIds(Map shift) {
  final titles = (shift["job_titles"] as List?) ?? [];
  return titles
      .map((t) => t["id"]?.toString())
      .whereType<String>()
      .toList();
}

List<String> _shiftUnitIds(Map shift) {
  final units = (shift["units"] as List?) ?? [];
  final selected = <String>[];
  for (final unit in units) {
    if (unit is! Map) continue;
    final id = unit["id"]?.toString();
    if (id != null) selected.add(id);
    final subunits = (unit["subunits"] as List?) ?? [];
    for (final sub in subunits) {
      if (sub is! Map) continue;
      final sid = sub["id"]?.toString();
      if (sid != null) selected.add(sid);
    }
  }
  return selected;
}

(TimeOfDay?, TimeOfDay?) _shiftTimes(Map shift) {
  String? start = shift["start_time"]?.toString();
  String? end = shift["end_time"]?.toString();
  final layer = shift["opening_layer"] as Map?;
  if (layer != null) {
    start ??= layer["start_time"]?.toString();
    end ??= layer["end_time"]?.toString();
  }
  if (start == null || end == null) {
    return (null, null);
  }
  return (_parseApiTime(start), _parseApiTime(end));
}

TimeOfDay? _parseApiTime(String value) {
  final parts = value.split(":");
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]) ?? 0;
  final m = int.tryParse(parts[1]) ?? 0;
  return TimeOfDay(hour: h, minute: m);
}

class _Header extends StatelessWidget {
  const _Header({
    required this.stats,
    required this.departmentName,
    required this.openings,
  });

  final Map<String, dynamic> stats;
  final String departmentName;
  final int openings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.lightGray)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Schedule Builder",
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: AppColors.primary),
                ),
                Text(
                  "Shift Templates",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          _StatChip(
            label: "Templates",
            value: stats["total_templates"]?.toString() ?? "0",
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: "Openings",
            value: stats["total_openings"]?.toString() ?? "0",
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lightGray),
        borderRadius: BorderRadius.circular(8),
        color: AppColors.white,
      ),
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, this.filled = false});

  final String text;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? AppColors.lightPink : AppColors.offwhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: filled ? AppColors.primary : AppColors.lightGray,
        ),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: filled ? AppColors.primary : AppColors.greyBlue,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _MobileTabs extends StatefulWidget {
  const _MobileTabs({
    required this.loading,
    required this.shiftLoading,
    required this.dataList,
    required this.department,
    required this.selectedDepartmentId,
    required this.selectedShiftId,
    required this.onSelectDepartment,
    required this.onSelectShift,
    required this.shift,
    required this.jobTitles,
    required this.departments,
    required this.units,
    required this.colors,
    required this.onCreateShift,
    required this.onUpdateShift,
    required this.onDeleteShift,
  });

  final bool loading;
  final bool shiftLoading;
  final List<Map<String, dynamic>> dataList;
  final Map<String, dynamic>? department;
  final String? selectedDepartmentId;
  final String? selectedShiftId;
  final ValueChanged<String> onSelectDepartment;
  final ValueChanged<String> onSelectShift;
  final Map<String, dynamic>? shift;
  final List<Map<String, dynamic>> jobTitles;
  final List<Map<String, dynamic>> departments;
  final List<Map<String, dynamic>> units;
  final List<Map<String, dynamic>> colors;
  final Future<void> Function(Map<String, dynamic>) onCreateShift;
  final Future<void> Function(String id, Map<String, dynamic>) onUpdateShift;
  final Future<void> Function(String id) onDeleteShift;

  @override
  State<_MobileTabs> createState() => _MobileTabsState();
}

class _MobileTabsState extends State<_MobileTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deptName =
        widget.department?["department"]?["name"]?.toString() ?? "All Departments";
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          color: AppColors.white,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  deptName,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: AppColors.primary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.lightPink,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "${_openings(widget.department)} openings",
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
        _ActionBar(
          hasSelection: widget.selectedShiftId != null,
          onAdd: () => _openShiftEditor(
            context,
            jobTitles: widget.jobTitles,
            departments: widget.departments,
            units: widget.units,
            colors: widget.colors,
            onSave: (payload) => widget.onCreateShift(payload),
          ),
          onEdit: () {
            final selected = widget.shift;
            if (selected == null) return;
            _openShiftEditor(
              context,
              jobTitles: widget.jobTitles,
              departments: widget.departments,
              units: widget.units,
              colors: widget.colors,
              initialShift: selected,
              onSave: (payload) => widget.onUpdateShift(
                selected["id"]?.toString() ?? "",
                payload,
              ),
            );
          },
          onDelete: () {
            final id = widget.selectedShiftId;
            if (id == null) return;
            _confirmDelete(context, onConfirm: () => widget.onDeleteShift(id));
          },
        ),
        TabBar(
          controller: _controller,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.greyBlue,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: "Departments"),
            Tab(text: "Shifts"),
            Tab(text: "Config"),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _controller,
            children: [
              _DepartmentsPane(
                loading: widget.loading,
                dataList: widget.dataList,
                selectedId: widget.selectedDepartmentId,
                onSelect: (id) {
                  widget.onSelectDepartment(id);
                  _controller.animateTo(1);
                },
              ),
              _ShiftsPane(
                loading: widget.loading,
                department: widget.department,
                selectedShiftId: widget.selectedShiftId,
                onSelect: (id) {
                  widget.onSelectShift(id);
                  _controller.animateTo(2);
                },
              ),
              _ConfigPane(
                loading: widget.shiftLoading,
                shift: widget.shift,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

int _openings(Map<String, dynamic>? department) {
  final shifts = (department?["shifts"] as List?) ?? [];
  return shifts.fold<int>(
    0,
    (sum, s) => sum + ((s["no_of_child_openings"] ?? 0) as int),
  );
}

List<Map<String, dynamic>> _buildDepartmentList(
  List<Map<String, dynamic>> dataList,
) {
  if (dataList.isEmpty) return const [];
  final normalized = dataList.map((d) {
    final shifts = (d["shifts"] as List? ?? []);
    return {
      ...d,
      "count": shifts.length,
    };
  }).toList();
  final firstId = normalized.first["department"]?["id"];
  if (firstId == "all") {
    final allShifts = normalized
        .skip(1)
        .expand((d) => (d["shifts"] as List? ?? []))
        .toList();
    normalized[0] = {
      ...normalized[0],
      "shifts": _dedupeShifts(allShifts),
      "count": _dedupeShifts(allShifts).length,
    };
    return normalized;
  }
  final allShifts =
      normalized.expand((d) => (d["shifts"] as List? ?? [])).toList();
  return [
    {
      "department": {"id": "all", "name": "All Departments"},
      "shifts": _dedupeShifts(allShifts),
      "count": _dedupeShifts(allShifts).length,
    },
    ...normalized,
  ];
}

Map<String, dynamic>? _findDepartment(
  List<Map<String, dynamic>> dataList,
  String? id,
) {
  if (dataList.isEmpty) return null;
  if (id == null || id.isEmpty) return dataList.first;
  return dataList.firstWhere(
    (d) => d["department"]?["id"]?.toString() == id,
    orElse: () => dataList.first,
  );
}

List<Map<String, dynamic>> _shiftOpeningsList(Map<String, dynamic>? shift) {
  if (shift == null) return const [];
  final openings = (shift["child_opening_data"] as List?) ??
      (shift["child_openings"] as List?) ??
      (shift["openings"] as List?) ??
      (shift["opening_details"] as List?) ??
      (shift["opening_data"] as List?) ??
      (shift["opening"] as List?) ??
      [];
  return openings
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

List<Map<String, dynamic>> _dedupeShifts(List<dynamic> shifts) {
  final seen = <String>{};
  final result = <Map<String, dynamic>>[];
  for (final item in shifts) {
    if (item is! Map) continue;
    final map = Map<String, dynamic>.from(item);
    final id = map["id"]?.toString();
    final name = _shiftName(map);
    final time = _shiftTimeRange(map);
    final key = id ?? "$name|$time";
    if (seen.contains(key)) continue;
    seen.add(key);
    result.add(map);
  }
  return result;
}

class _ShiftHeader extends StatelessWidget {
  const _ShiftHeader({required this.shift});

  final Map<String, dynamic> shift;

  @override
  Widget build(BuildContext context) {
    final name = _shiftName(shift);
    final time = _shiftTimeRange(shift);
    final units = _unitsString((shift["units"] as List?) ?? const []);
    final openings =
        shift["no_of_child_openings"] ?? shift["total_openings"] ?? 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              _Pill(text: "SB"),
              const SizedBox(width: 8),
              _Pill(text: "$openings open", filled: true),
            ],
          ),
          if (time.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              time,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.greyBlue),
            ),
          ],
          if (units.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              units,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.greyBlue),
            ),
          ],
        ],
      ),
    );
  }
}

class _DepartmentsPane extends StatelessWidget {
  const _DepartmentsPane({
    required this.loading,
    required this.dataList,
    required this.selectedId,
    required this.onSelect,
  });

  final bool loading;
  final List<Map<String, dynamic>> dataList;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: dataList.map((item) {
                final dept = item["department"];
                final id = dept["id"].toString();
                final name = dept["name"]?.toString() ?? "";
                final isSelected = id == selectedId;
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.lightGray,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    title: Text(name),
                    trailing: const Icon(Icons.chevron_right),
                    selected: isSelected,
                    onTap: () => onSelect(id),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _ShiftsPane extends StatelessWidget {
  const _ShiftsPane({
    required this.loading,
    required this.department,
    required this.selectedShiftId,
    required this.onSelect,
  });

  final bool loading;
  final Map<String, dynamic>? department;
  final String? selectedShiftId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final shifts = (department?["shifts"] as List?) ?? [];
    return Container(
      padding: const EdgeInsets.all(12),
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : shifts.isEmpty
              ? const Center(child: Text("No Shift available"))
              : ListView.builder(
                  itemCount: shifts.length,
                  itemBuilder: (context, index) {
                    final shift = shifts[index] as Map;
                    final id = shift["id"].toString();
                    final isActive = id == selectedShiftId;
                    final name = _shiftName(shift);
                    final timeRange = _shiftTimeRange(shift);
                    final subtitleParts = <String>[
                      if (timeRange.isNotEmpty) timeRange,
                      _shiftJobTitles(shift),
                    ]..removeWhere((e) => e.isEmpty);
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: isActive ? AppColors.primary : AppColors.lightGray,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        selected: isActive,
                        title: Text(name),
                        subtitle: Text(subtitleParts.join(" | ")),
                        trailing: const Icon(Icons.tune),
                        onTap: () => onSelect(id),
                      ),
                    );
                  },
                ),
    );
  }
}

class _ConfigPane extends StatelessWidget {
  const _ConfigPane({required this.loading, required this.shift});

  final bool loading;
  final Map<String, dynamic>? shift;

  @override
  Widget build(BuildContext context) {
    return loading
        ? const Center(child: CircularProgressIndicator())
        : shift == null
            ? const Center(child: Text("Select a shift"))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _ShiftDetails(shift: shift!),
              );
  }
}

class _ShiftDetails extends StatelessWidget {
  const _ShiftDetails({required this.shift});

  final Map<String, dynamic> shift;

  @override
  Widget build(BuildContext context) {
    final parent = (shift["parent_opening_data"] as Map?) ?? {};
    final openingLayer = (shift["opening_layer"] as Map?) ??
        (parent["opening_layer"] as Map?) ??
        {};
    final units = (shift["units"] as List?) ?? (parent["units"] as List?) ?? [];
    final jobTitles =
        (shift["job_titles"] as List?) ?? (parent["job_titles"] as List?) ?? [];
    final days =
        (shift["days_needed"] as List?) ?? (parent["days_needed"] as List?) ?? [];
    final status = openingLayer["is_optional"] == true ? "Optional" : "Required";
    final meal = openingLayer["meal_time"] ?? shift["meal_time"] ?? 0;
    final patient = openingLayer["patient_count"] ?? shift["patient_count"] ?? "-";
    final openings = (shift["child_opening_data"] as List?) ??
        (shift["child_openings"] as List?) ??
        [];
    final title = _shiftName(shift);
    final timeRange = _shiftTimeRange(shift);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (timeRange.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            timeRange,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.greyBlue),
          ),
        ],
        const SizedBox(height: 12),
        _InfoCard(
          title: "Openings",
          value: "${openings.length}",
        ),
        const SizedBox(height: 12),
        _InfoGrid(
          items: [
            {"label": "Status", "value": status},
            {"label": "Meal Break", "value": "$meal min"},
            {"label": "Units", "value": _unitsString(units)},
            {"label": "Job Titles", "value": _jobTitleString(jobTitles)},
            {"label": "Patient Ratio", "value": patient.toString()},
          ],
        ),
        const SizedBox(height: 12),
        _WeekDays(days: days),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightSkyBlue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.items});
  final List<Map<String, String>> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.lightGray),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(item["label"] ?? "",
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
              Text(
                item["value"] ?? "",
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _WeekDays extends StatelessWidget {
  const _WeekDays({required this.days});
  final List<dynamic> days;

  @override
  Widget build(BuildContext context) {
    const labels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Wrap(
        spacing: 8,
        children: List.generate(7, (index) {
          final selected = days.contains(index);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? AppColors.lightPink : AppColors.offwhite,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.lightGray,
              ),
            ),
            child: Text(
              labels[index],
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected ? AppColors.primary : AppColors.greyBlue,
                  ),
            ),
          );
        }),
      ),
    );
  }
}

String _formatTimeRange(String? start, String? end) {
  if (start == null || end == null) return "";
  return "${_to12(start)} - ${_to12(end)}";
}

String _to12(String time) {
  final parts = time.split(":");
  if (parts.length < 2) return time;
  final h = int.tryParse(parts[0]) ?? 0;
  final m = parts[1];
  final meridian = h >= 12 ? "PM" : "AM";
  final hour = h % 12 == 0 ? 12 : h % 12;
  return "$hour:$m $meridian";
}

String _unitsString(List units) {
  if (units.isEmpty) return "No unit provided";
  return units
      .map((u) => u["name"] ?? u["unit_name"] ?? u["label"] ?? "")
      .where((u) => u.toString().isNotEmpty)
      .join(", ");
}

Map<String, dynamic>? _findShiftById(
  List<Map<String, dynamic>> dataList,
  String shiftId,
) {
  for (final dept in dataList) {
    final shifts = (dept["shifts"] as List?) ?? [];
    for (final shift in shifts) {
      if (shift is! Map) continue;
      final id = shift["id"]?.toString();
      if (id == shiftId) return Map<String, dynamic>.from(shift);
    }
  }
  return null;
}

String _jobTitleString(List titles) {
  if (titles.isEmpty) return "No job title provided";
  return titles
      .map((t) => t["abbreviation"] ?? t["name"] ?? t["title"] ?? "")
      .where((t) => t.toString().isNotEmpty)
      .join(", ");
}

Future<void> _openMergeSheet(
  BuildContext context, {
  required List<Map<String, dynamic>> shifts,
  required Future<bool> Function(List<String> ids) onMerge,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      final selected = <String>{};
      return StatefulBuilder(
        builder: (context, setState) {
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.85,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      height: 4,
                      width: 36,
                      decoration: BoxDecoration(
                        color: AppColors.lightGray,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Select shifts to merge",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: shifts.length,
                        itemBuilder: (context, index) {
                          final shift = shifts[index];
                          final id = shift["id"]?.toString() ?? "";
                          final name = _shiftName(shift);
                          final checked = selected.contains(id);
                          return CheckboxListTile(
                            value: checked,
                            onChanged: (_) {
                              setState(() {
                                if (checked) {
                                  selected.remove(id);
                                } else {
                                  selected.add(id);
                                }
                              });
                            },
                            title: Text(name),
                            controlAffinity: ListTileControlAffinity.trailing,
                            activeColor: AppColors.primary,
                          );
                        },
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: selected.length < 2
                                ? null
                                : () async {
                                    final ok =
                                        await onMerge(selected.toList());
                                    if (!context.mounted) return;
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          ok
                                              ? "Merged successfully"
                                              : "Merge failed",
                                        ),
                                      ),
                                    );
                                  },
                            child: Text("Merge (${selected.length})"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> _openConflictsSheet(
  BuildContext context,
  List<Map<String, dynamic>> conflicts,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  height: 4,
                  width: 36,
                  decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Job Title Conflicts",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: conflicts.isEmpty
                      ? const Center(child: Text("No conflicts found"))
                      : ListView.separated(
                          itemCount: conflicts.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = conflicts[index];
                            final title =
                                item["title"]?.toString() ??
                                item["name"]?.toString() ??
                                "Conflict";
                            final detail = item["reason"]?.toString() ??
                                item["message"]?.toString() ??
                                "";
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: AppColors.lightGray),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.w700),
                                  ),
                                  if (detail.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      detail,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                              color: AppColors.greyBlue),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
