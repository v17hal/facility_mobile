import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

import "package:flutter_riverpod/flutter_riverpod.dart";



import "../../core/theme/app_colors.dart";
import "../../core/network/endpoints.dart";
import "../../routes/app_routes.dart";

import "daily_schedule_controller.dart";
import "daily_actions_screen.dart";



class DailyScheduleScreen extends ConsumerWidget {

  const DailyScheduleScreen({super.key});



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final state = ref.watch(dailyScheduleControllerProvider);

    final controller = ref.read(dailyScheduleControllerProvider.notifier);





    return Scaffold(

      appBar: AppBar(

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Daily Schedule"),
            Text(
              _formatHeaderDate(state.date),
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: AppColors.greyBlue),
            ),
          ],
        ),

        actions: [
          _FacilityInlineSelector(
            facilities: state.facilities,
            selectedId: state.selectedFacilityId,
            selectedName: state.selectedFacilityName,
            onSelect: controller.selectFacility,
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _pickDate(context, controller, state.date),
          ),

        ],

      ),

      body: Stack(

        children: [

          ListView(

            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),

            children: [

              _StatsStrip(stats: state.statsData),

              const SizedBox(height: 12),

              _DateStrip(

                selected: state.date,

                onSelect: controller.setDate,

              ),

              const SizedBox(height: 12),
              _DepartmentOnlyList(
                openings: state.openings,
                departments: state.departments,
                loading: state.openingsLoading,
                selectedDepartmentId: state.selectedDepartmentId,
                onSelect: (deptId) {
                  controller.setDepartment(deptId);
                  Navigator.push(
                    context,
                    _slideRoute(
                      ShiftListScreen(
                        departmentId: deptId,
                        date: state.date,
                      ),
                    ),
                  );
                },
              ),

            ],

          ),

          if (state.loading || state.actionLoading)

            const Positioned(

              top: 0,

              left: 0,

              right: 0,

              child: LinearProgressIndicator(minHeight: 2),

            ),

        ],

      ),
      floatingActionButton: _ActionFab(
        onTap: () => _openActionMenu(
          context,
          onBroadcast: () => _openBroadcast(context),
          onScorecard: () =>
              _openScorecard(context, state.date, state.departments),
          onLogs: () => _openLogs(context),
          onOffSchedule: () => _openOffSchedule(context, state.date),
          onPeopleWorking: () => _openPeopleWorking(context, state.date),
          onAssignRotation: () => context.push(AppRoutes.rotationAssign),
          onRotations: () => context.push(AppRoutes.rotations),
          onReports: () => context.push(AppRoutes.allShift),
          onReset: () async {
            final ok =
                await _confirm(context, "Reset conflicts for this date?");
            if (!ok) return;
            final success = await controller.resetApplicants();
            if (context.mounted) {
              _showSnack(
                context,
                success ? "Reset complete" : "Reset failed",
              );
            }
          },
        ),
      ),

    );

  }

}




class _FacilityHeader extends StatelessWidget {
  const _FacilityHeader({
    required this.facilities,
    required this.selectedId,
    required this.selectedName,
    required this.onSelect,
  });

  final List<Map<String, dynamic>> facilities;
  final String? selectedId;
  final String? selectedName;
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
                      selectedName ?? "Select Facility",
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<Map<String, dynamic>>(
                    tooltip: "Select Facility",
                    onSelected: (value) {
                      final id = value["id"]?.toString() ?? "";
                      final name = value["name"]?.toString() ?? "";
                      if (id.isNotEmpty) onSelect(id, name);
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

class _StatsRow extends StatelessWidget {

  const _StatsRow({required this.stats});



  final Map<String, dynamic> stats;



  @override

  Widget build(BuildContext context) {

    final census = stats["census"] ?? 0;

    final scheduled = stats["schedule_hours"] ?? 0;

    final actual = stats["actual_hours"] ?? 0;

    final openPositions = stats["open_positions"] ?? 0;



    return Row(

      children: [

        _StatTile(label: "Census", value: "$census"),

        const SizedBox(width: 8),

        _StatTile(label: "Scheduled", value: "$scheduled hrs"),

        const SizedBox(width: 8),

        _StatTile(label: "Actual", value: "$actual hrs"),

        const SizedBox(width: 8),

        _StatTile(label: "Open", value: "$openPositions"),

      ],

    );

  }

}



class _StatTile extends StatelessWidget {

  const _StatTile({required this.label, required this.value});



  final String label;

  final String value;



  @override

  Widget build(BuildContext context) {

    return Expanded(

      child: Container(

        padding: const EdgeInsets.all(10),

        decoration: BoxDecoration(

          color: AppColors.offwhite,

          borderRadius: BorderRadius.circular(10),

          border: Border.all(color: AppColors.lightGray),

        ),

        child: Column(

          children: [

            Text(label, style: Theme.of(context).textTheme.labelLarge),

            const SizedBox(height: 4),

            Text(

              value,

              style: Theme.of(context)

                  .textTheme

                  .titleMedium

                  ?.copyWith(color: AppColors.primary),

            ),

          ],

        ),

      ),

    );

  }

}



class _DateStrip extends StatelessWidget {

  const _DateStrip({required this.selected, required this.onSelect});



  final DateTime selected;

  final ValueChanged<DateTime> onSelect;



  @override

  Widget build(BuildContext context) {

    final start = selected.subtract(const Duration(days: 7));

    final days = List.generate(15, (i) => start.add(Duration(days: i)));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.lightPink,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => onSelect(selected.subtract(const Duration(days: 1))),
          ),
          Expanded(
            child: SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: days.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final date = days[index];
                  final isSelected = _isSameDay(date, selected);
                  return InkWell(
                    onTap: () => onSelect(date),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 44,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              isSelected ? AppColors.primary : AppColors.lightGray,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _weekdayShort(date),
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.greyBlue,
                                  fontSize: 11,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${date.day}",
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color:
                                      isSelected ? Colors.white : AppColors.black,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => onSelect(selected.add(const Duration(days: 1))),
          ),
        ],
      ),
    );

  }

}



class _FilterBar extends StatelessWidget {

  const _FilterBar({

    required this.departments,

    required this.selectedDepartmentId,

    required this.onSelect,

  });



  final List<Map<String, dynamic>> departments;

  final String? selectedDepartmentId;

  final ValueChanged<String?> onSelect;



  @override

  Widget build(BuildContext context) {

    final selected = departments.firstWhere(

      (d) => d["id"]?.toString() == selectedDepartmentId,

      orElse: () => {},

    );

    return Row(

      children: [

        Expanded(

          child: Container(

            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

            decoration: BoxDecoration(

              color: AppColors.white,

              borderRadius: BorderRadius.circular(10),

              border: Border.all(color: AppColors.lightGray),

            ),

            child: Row(

              children: [

                const Icon(Icons.filter_list, size: 18, color: AppColors.greyBlue),

                const SizedBox(width: 8),

                Expanded(

                  child: Text(

                    selected["name"]?.toString() ?? "All Departments",

                    style: Theme.of(context)

                        .textTheme

                        .labelLarge

                        ?.copyWith(color: AppColors.greyBlue),

                    overflow: TextOverflow.ellipsis,

                  ),

                ),

                PopupMenuButton<String?>(

                  onSelected: onSelect,

                  itemBuilder: (context) => [

                    const PopupMenuItem(value: null, child: Text("All")),

                    ...departments.map(

                      (d) => PopupMenuItem(

                        value: d["id"]?.toString(),

                        child: Text(d["name"]?.toString() ?? ""),

                      ),

                    ),

                  ],

                  child: const Icon(Icons.keyboard_arrow_down),

                ),

              ],

            ),

          ),

        ),

      ],

    );

  }

}



class _ShiftMailbox extends StatelessWidget {

  const _ShiftMailbox({

    required this.shifts,

    required this.selectedShiftId,

    required this.loading,

    required this.onSelect,

  });



  final List<Map<String, dynamic>> shifts;

  final String? selectedShiftId;

  final bool loading;

  final ValueChanged<String?> onSelect;



  @override

  Widget build(BuildContext context) {

    if (loading) {

      return const Center(child: LinearProgressIndicator());

    }

    if (shifts.isEmpty) {

      return const SizedBox.shrink();

    }

    return SizedBox(

      height: 120,

      child: ListView.separated(

        scrollDirection: Axis.horizontal,

        itemCount: shifts.length + 1,

        separatorBuilder: (_, __) => const SizedBox(width: 10),

        itemBuilder: (context, index) {

          if (index == 0) {

            final isSelected = selectedShiftId?.isEmpty ?? true;

            return _ShiftCard(

              title: "All Shifts",

              time: "",

              subtitle: "",

              selected: isSelected,

              onTap: () => onSelect(null),

            );

          }

          final shift = shifts[index - 1];

          final shiftId = shift["shift_id"]?.toString() ?? "";

          final title = shift["title"]?.toString() ?? "Shift";

          final time = _timeRange(

            shift["start_time"]?.toString(),

            shift["end_time"]?.toString(),

          );

          final applicants = shift["applicants"] ?? 0;

          final openings = shift["total_openings"] ?? 0;

          final subtitle = "$applicants applicants - $openings openings";

          return _ShiftCard(

            title: title,

            time: time,

            subtitle: subtitle,

            selected: shiftId == selectedShiftId,

            onTap: () => onSelect(shiftId),

          );

        },

      ),

    );

  }

}



class _ShiftCard extends StatelessWidget {

  const _ShiftCard({

    required this.title,

    required this.time,

    required this.subtitle,

    required this.selected,

    required this.onTap,

  });



  final String title;

  final String time;

  final String subtitle;

  final bool selected;

  final VoidCallback onTap;



  @override

  Widget build(BuildContext context) {

    return InkWell(

      onTap: onTap,

      borderRadius: BorderRadius.circular(12),

      child: Container(

        width: 170,

        padding: const EdgeInsets.all(12),

        decoration: BoxDecoration(

          color: selected ? AppColors.primary : AppColors.white,

          borderRadius: BorderRadius.circular(12),

          border: Border.all(

            color: selected ? AppColors.primary : AppColors.lightGray,

          ),

        ),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Text(

              title,

              maxLines: 1,

              overflow: TextOverflow.ellipsis,

              style: Theme.of(context).textTheme.titleMedium?.copyWith(

                    color: selected ? Colors.white : AppColors.primary,

                    fontWeight: FontWeight.w700,

                  ),

            ),

            const SizedBox(height: 4),

            if (time.isNotEmpty)

              Text(

                time,

                style: Theme.of(context).textTheme.bodySmall?.copyWith(

                      color: selected ? Colors.white70 : AppColors.greyBlue,

                    ),

              ),

            const SizedBox(height: 6),

            if (subtitle.isNotEmpty)

              Text(

                subtitle,

                style: Theme.of(context).textTheme.labelMedium?.copyWith(

                      color: selected ? Colors.white70 : AppColors.greyBlue,

                    ),

              ),

          ],

        ),

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

class _ActionChips extends StatelessWidget {
  const _ActionChips({
    required this.onBroadcast,
    required this.onScorecard,
    required this.onLogs,
    required this.onOffSchedule,
    required this.onPeopleWorking,
    required this.onAssignRotation,
    required this.onRotations,
    required this.onReports,
    required this.onReset,
  });

  final VoidCallback onBroadcast;
  final VoidCallback onScorecard;
  final VoidCallback onLogs;
  final VoidCallback onOffSchedule;
  final VoidCallback onPeopleWorking;
  final VoidCallback onAssignRotation;
  final VoidCallback onRotations;
  final VoidCallback onReports;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final items = [
      _ActionChip(label: "Broadcast", icon: Icons.campaign, onTap: onBroadcast),
      _ActionChip(label: "Scorecard", icon: Icons.receipt_long, onTap: onScorecard),
      _ActionChip(label: "Logs", icon: Icons.list_alt, onTap: onLogs),
      _ActionChip(label: "Off Schedule", icon: Icons.event_busy, onTap: onOffSchedule),
      _ActionChip(label: "People Working", icon: Icons.people, onTap: onPeopleWorking),
      _ActionChip(label: "Assign Rotation", icon: Icons.repeat, onTap: onAssignRotation),
      _ActionChip(label: "Rotations", icon: Icons.swap_horiz, onTap: onRotations),
      _ActionChip(label: "Reports", icon: Icons.bar_chart, onTap: onReports),
      _ActionChip(label: "Reset", icon: Icons.refresh, onTap: onReset),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) => items[index],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.lightGray),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: AppColors.greyBlue),
            ),
          ],
        ),
      ),
    );
  }
}

class _MailboxSection extends StatelessWidget {

  const _MailboxSection({

    required this.openings,

    required this.selectedDepartmentId,

    required this.selectedOpeningId,

    required this.onSelectDepartment,

    required this.onSelectOpening,

    required this.onCreate,

    required this.onEdit,

    required this.onDelete,

    required this.loading,

  });


  final List<Map<String, dynamic>> openings;

  final String? selectedDepartmentId;

  final String? selectedOpeningId;

  final ValueChanged<String?> onSelectDepartment;

  final ValueChanged<Map<String, dynamic>> onSelectOpening;

  final VoidCallback onCreate;

  final VoidCallback onEdit;

  final VoidCallback onDelete;

  final bool loading;



  @override

  Widget build(BuildContext context) {

    final departments = _deriveDepartments(openings);

    final filtered = _filterOpeningsByDepartment(openings, selectedDepartmentId);



    return LayoutBuilder(

      builder: (context, constraints) {

        final isWide = constraints.maxWidth >= 700;

        final deptPanel = _DepartmentsPane(

          departments: departments,

          selectedId: selectedDepartmentId,

          onSelect: onSelectDepartment,

        );

        final shiftPanel = _ShiftPane(

          openings: filtered,

          selectedOpeningId: selectedOpeningId,

          onSelect: onSelectOpening,

          onCreate: onCreate,

          onEdit: onEdit,

          onDelete: onDelete,

          loading: loading,

        );



        if (isWide) {

          return Row(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              SizedBox(width: 180, child: deptPanel),

              const SizedBox(width: 12),

              Expanded(child: shiftPanel),

            ],

          );

        }

        return Column(

          children: [

            deptPanel,

            const SizedBox(height: 12),

            shiftPanel,

          ],

        );

      },

    );

  }

}



class _DepartmentsPane extends StatelessWidget {

  const _DepartmentsPane({

    required this.departments,

    required this.selectedId,

    required this.onSelect,

  });



  final List<Map<String, dynamic>> departments;

  final String? selectedId;

  final ValueChanged<String?> onSelect;



  @override

  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(

        color: AppColors.white,

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: AppColors.lightGray),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Text(

            "Departments",

            style: Theme.of(context)

                .textTheme

                .labelLarge

                ?.copyWith(color: AppColors.greyBlue),

          ),

          const SizedBox(height: 10),

          ...departments.map((dept) {

            final id = dept["id"]?.toString();

            final name = dept["name"]?.toString() ?? "";

            final count = dept["count"]?.toString() ?? "0";

            final selected = (id == selectedId) || (id == null && selectedId == null);

            return Padding(

              padding: const EdgeInsets.only(bottom: 6),

              child: InkWell(

                onTap: () => onSelect(id),

                borderRadius: BorderRadius.circular(10),

                child: Container(

                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),

                  decoration: BoxDecoration(

                    color: selected ? AppColors.primary : AppColors.offwhite,

                    borderRadius: BorderRadius.circular(10),

                  ),

                  child: Row(

                    children: [

                      Expanded(

                        child: Text(

                          name,

                          overflow: TextOverflow.ellipsis,

                          style: Theme.of(context).textTheme.labelLarge?.copyWith(

                                color: selected ? Colors.white : AppColors.black,

                              ),

                        ),

                      ),

                      Container(

                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),

                        decoration: BoxDecoration(

                          color: selected ? Colors.white : AppColors.lightPink,

                          borderRadius: BorderRadius.circular(10),

                        ),

                        child: Text(

                          count,

                          style: Theme.of(context).textTheme.labelSmall?.copyWith(

                                color: selected ? AppColors.primary : AppColors.primary,

                              ),

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



class _ShiftPane extends StatefulWidget {

  const _ShiftPane({

    required this.openings,

    required this.selectedOpeningId,

    required this.onSelect,

    required this.onCreate,

    required this.onEdit,

    required this.onDelete,

    required this.loading,

  });


  final List<Map<String, dynamic>> openings;

  final String? selectedOpeningId;

  final ValueChanged<Map<String, dynamic>> onSelect;

  final VoidCallback onCreate;

  final VoidCallback onEdit;

  final VoidCallback onDelete;

  final bool loading;



  @override

  State<_ShiftPane> createState() => _ShiftPaneState();

}



class _ShiftPaneState extends State<_ShiftPane> {

  String query = "";



  @override

  Widget build(BuildContext context) {

    final filtered = widget.openings.where((opening) {

      final name = opening["name"]?.toString().toLowerCase() ?? "";

      return name.contains(query.toLowerCase());

    }).toList();



    return Container(

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(

        color: AppColors.white,

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: AppColors.lightGray),

      ),

      child: Column(

        children: [

          Row(

            children: [

              Expanded(

                child: Text(

                  "All Departments",

                  style: Theme.of(context).textTheme.titleMedium,

                ),

              ),

              IconButton(

                onPressed: widget.onCreate,

                icon: const Icon(Icons.add_circle, color: AppColors.primary),

              ),

            ],

          ),

          const SizedBox(height: 8),

          Row(

            children: [

              Expanded(

                child: TextField(

                  decoration: const InputDecoration(

                    hintText: "Search Shifts",

                    prefixIcon: Icon(Icons.search),

                  ),

                  onChanged: (value) => setState(() => query = value),

                ),

              ),

              const SizedBox(width: 8),

              IconButton(

                onPressed: () {},

                icon: const Icon(Icons.filter_alt_outlined),

              ),

            ],

          ),

          const SizedBox(height: 12),

          if (widget.loading)

            const LinearProgressIndicator(minHeight: 2)

          else if (filtered.isEmpty)

            const Padding(

              padding: EdgeInsets.symmetric(vertical: 16),

              child: Text("No shifts found"),

            )

          else

            ListView.separated(

              shrinkWrap: true,

              physics: const NeverScrollableScrollPhysics(),

              itemCount: filtered.length,

              separatorBuilder: (_, __) => const Divider(height: 16),

              itemBuilder: (context, index) {

                final opening = filtered[index];

                final id = _openingId(opening);

                final selected = id == widget.selectedOpeningId;

                final name = opening["name"]?.toString() ?? "Shift";

                final time = _firstShiftTime(opening);

                final count = _openingsCount(opening);

                return InkWell(

                  onTap: () => widget.onSelect(opening),

                  borderRadius: BorderRadius.circular(10),

                  child: Container(

                    padding: const EdgeInsets.all(12),

                    decoration: BoxDecoration(

                      color: selected ? AppColors.lightPink : Colors.transparent,

                      borderRadius: BorderRadius.circular(10),

                      border: Border.all(

                        color: selected ? AppColors.primary : Colors.transparent,

                      ),

                    ),

                    child: Row(

                      children: [

                        Container(

                          width: 3,

                          height: 48,

                          decoration: BoxDecoration(

                            color: selected ? AppColors.primary : Colors.transparent,

                            borderRadius: BorderRadius.circular(4),

                          ),

                        ),

                        const SizedBox(width: 10),

                        Expanded(
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
                                  const SizedBox(width: 6),
                                  _Pill(text: "$count open", filled: true),
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
                            ],
                          ),
                        ),
                      ],

                    ),

                  ),

                );

              },

            ),

          const SizedBox(height: 12),

          Row(

            children: [

              Expanded(

                child: FilledButton.icon(

                  onPressed: widget.onCreate,

                  icon: const Icon(Icons.add),

                  label: const Text("New Opening"),

                ),

              ),

              const SizedBox(width: 8),

              Expanded(

                child: OutlinedButton.icon(

                  onPressed: widget.selectedOpeningId == null ? null : widget.onEdit,

                  icon: const Icon(Icons.edit_outlined),

                  label: const Text("Edit"),

                ),

              ),

              const SizedBox(width: 8),

              Expanded(

                child: OutlinedButton.icon(

                  onPressed: widget.selectedOpeningId == null ? null : widget.onDelete,

                  icon: const Icon(Icons.delete_outline),

                  label: const Text("Delete"),

                ),

              ),

            ],

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

        borderRadius: BorderRadius.circular(14),

        border: Border.all(color: AppColors.lightGray),

      ),

      child: Text(

        text,

        style: Theme.of(context)

            .textTheme

            .labelSmall

            ?.copyWith(color: AppColors.primary),

      ),

    );

  }

}



class _ActionButtons extends StatelessWidget {

  const _ActionButtons({

    required this.hasSelection,

    required this.onNew,

    required this.onEdit,

    required this.onDelete,

  });



  final bool hasSelection;

  final VoidCallback onNew;

  final VoidCallback onEdit;

  final VoidCallback onDelete;



  @override

  Widget build(BuildContext context) {

    return Row(

      children: [

        Expanded(

          child: FilledButton.icon(

            onPressed: onNew,

            icon: const Icon(Icons.add),

            label: const Text("New Opening"),

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

    );

  }

}



class _PositionsList extends StatelessWidget {

  const _PositionsList({

    required this.openings,

    required this.selectedOpeningId,

    required this.onSelect,

    required this.onDelete,

    required this.loading,

  });


  final List<Map<String, dynamic>> openings;

  final String? selectedOpeningId;

  final ValueChanged<Map<String, dynamic>> onSelect;

  final ValueChanged<Map<String, dynamic>> onDelete;

  final bool loading;



  @override

  Widget build(BuildContext context) {

    if (loading) {

      return const Center(child: CircularProgressIndicator());

    }

    if (openings.isEmpty) {

      return const Center(child: Text("No openings found"));

    }

    return ListView.separated(

      shrinkWrap: true,

      physics: const NeverScrollableScrollPhysics(),

      itemCount: openings.length,

      separatorBuilder: (_, __) => const SizedBox(height: 10),

      itemBuilder: (context, index) {

        final opening = openings[index];

        final id = _openingId(opening);

        final selected = id == selectedOpeningId;

        final title = opening["name"]?.toString() ?? "Opening";

        final department = opening["department"]?['name']?.toString() ?? "";

        final unit = opening["unit_name"]?.toString() ?? "";

        final jobTitles = (opening["job_titles"] as List?) ?? [];

        final jobLabel = jobTitles.isEmpty

            ? ""

            : jobTitles.first is Map

                ? (jobTitles.first["abbreviation"] ??

                        jobTitles.first["name"] ??

                        "")

                    .toString()

                : "";

        final extra = jobTitles.length > 1 ? "+${jobTitles.length - 1}" : "";



        return Dismissible(

          key: ValueKey("opening_$id"),

          direction: DismissDirection.endToStart,

          background: Container(

            alignment: Alignment.centerRight,

            padding: const EdgeInsets.only(right: 16),

            decoration: BoxDecoration(

              color: AppColors.red.withOpacity(0.12),

              borderRadius: BorderRadius.circular(12),

            ),

            child: const Icon(Icons.delete, color: AppColors.red),

          ),

          confirmDismiss: (_) async {

            onDelete(opening);

            return false;

          },

          child: InkWell(

            onTap: () => onSelect(opening),

            borderRadius: BorderRadius.circular(12),

            child: Container(

              padding: const EdgeInsets.all(14),

              decoration: BoxDecoration(

                color: selected ? AppColors.lightPink : Colors.white,

                borderRadius: BorderRadius.circular(12),

                border: Border.all(

                  color: selected ? AppColors.primary : AppColors.lightGray,

                ),

              ),

              child: Row(

                children: [

                  Expanded(

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        Text(

                          title,

                          style: Theme.of(context)

                              .textTheme

                              .titleMedium

                              ?.copyWith(fontWeight: FontWeight.w700),

                        ),

                        const SizedBox(height: 4),

                        Text(

                          [unit, department]

                              .where((e) => e.isNotEmpty)

                              .join(" - "),

                          style: Theme.of(context)

                              .textTheme

                              .bodyMedium

                              ?.copyWith(color: AppColors.greyBlue),

                        ),

                      ],

                    ),

                  ),

                  if (jobLabel.isNotEmpty)

                    Container(

                      padding:

                          const EdgeInsets.symmetric(horizontal: 8, vertical: 6),

                      decoration: BoxDecoration(

                        color: AppColors.offwhite,

                        borderRadius: BorderRadius.circular(10),

                        border: Border.all(color: AppColors.lightGray),

                      ),

                      child: Row(

                        children: [

                          Text(

                            jobLabel,

                            style: Theme.of(context)

                                .textTheme

                                .labelLarge

                                ?.copyWith(color: AppColors.primary),

                          ),

                          if (extra.isNotEmpty) ...[

                            const SizedBox(width: 6),

                            Container(

                              padding: const EdgeInsets.symmetric(

                                  horizontal: 6, vertical: 2),

                              decoration: BoxDecoration(

                                color: AppColors.primary,

                                borderRadius: BorderRadius.circular(10),

                              ),

                              child: Text(

                                extra,

                                style: Theme.of(context)

                                    .textTheme

                                    .labelMedium

                                    ?.copyWith(color: Colors.white),

                              ),

                            ),

                          ],

                        ],

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

}


class _EmptyShiftDetail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              color: AppColors.lightPink,
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(Icons.mail, color: AppColors.primary, size: 48),
          ),
          const SizedBox(height: 16),
          Text(
            "Please select a shift",
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            "Pick a shift to view positions and assignments.",
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.greyBlue),
          ),
        ],
      ),
    );
  }
}

class _PositionDetail extends StatelessWidget {

  const _PositionDetail({

    required this.opening,
    required this.countsSource,
    required this.controller,

    required this.selectedLayerId,

    required this.selectedShiftId,

    required this.applicants,

    required this.employees,

    required this.applicantsLoading,

    required this.employeesLoading,

    required this.selectedEmployees,

    required this.employeeSearch,

    required this.applicantSearch,

    required this.employeeSelection,

    required this.onSelectLayer,

    required this.onSelectShift,

    required this.onApplicantSearch,

    required this.onEmployeeSearch,

    required this.onSelectionFilter,

    required this.onClearSelected,

    required this.onAssign,

  });



  final Map<String, dynamic> opening;
  final Map<String, dynamic>? countsSource;
  final DailyScheduleController controller;

  final String? selectedLayerId;

  final String? selectedShiftId;

  final List<Map<String, dynamic>> applicants;

  final List<Map<String, dynamic>> employees;

  final bool applicantsLoading;

  final bool employeesLoading;

  final List<Map<String, dynamic>> selectedEmployees;

  final String employeeSearch;

  final String applicantSearch;

  final String employeeSelection;

  final ValueChanged<String> onSelectLayer;

  final ValueChanged<String> onSelectShift;

  final ValueChanged<String> onApplicantSearch;

  final ValueChanged<String> onEmployeeSearch;

  final ValueChanged<String> onSelectionFilter;

  final VoidCallback onClearSelected;

  final ValueChanged<BuildContext> onAssign;



  @override

  Widget build(BuildContext context) {

    final title = opening["name"]?.toString() ?? "Opening";

    final unit = _unitLabel(opening);

    final department = opening["department"]?["name"]?.toString() ?? "";

    final layers = _shiftLayers(opening);
    final maxSelectable =
        _maxSelectableForOpening(opening, selectedShiftId);
    final assignedEmployees =
        _assignedEmployeesForOpening(opening, selectedShiftId);
    final applicantIdByEmployeeId = <String, String>{};
    final applicantsRaw = (opening["applicants"] as List?) ?? [];
    for (final item in applicantsRaw) {
      if (item is! Map) continue;
      final applicantId = item["applicant_id"]?.toString() ??
          item["id"]?.toString();
      if (applicantId == null || applicantId.isEmpty) continue;
      final nurse = item["nurse"];
      final nurseId = nurse is Map
          ? (nurse["id"]?.toString() ??
              nurse["employee_id"]?.toString() ??
              nurse["nurse_id"]?.toString())
          : null;
      final directEmployeeId = item["employee_id"]?.toString() ??
          item["nurse_id"]?.toString();
      final key = nurseId ?? directEmployeeId;
      if (key != null && key.isNotEmpty) {
        applicantIdByEmployeeId[key] = applicantId;
      }
    }
    final counts = _shiftCountsForOpening(countsSource ?? opening);
    final currentOpeningId = _openingId(opening);
    final transferMap = <String, Map<String, String>>{};
    final source = countsSource ?? opening;
    final currentStart = opening["start_time"]?.toString();
    final currentEnd = opening["end_time"]?.toString();
    final detailList = source["shift_details"];
    if (detailList is List) {
      for (final item in detailList) {
        if (item is! Map) continue;
        final detail = Map<String, dynamic>.from(item);
        final detailId = _openingId(detail);
        final detailOpeningDailyId = detail["opening_daily_id"]?.toString() ??
            detail["daily_opening_id"]?.toString() ??
            detail["opening_daily"]?.toString() ??
            detailId;
        final detailScheduleShiftId = detail["schedule_shift_id"]?.toString() ??
            detail["shift_id"]?.toString() ??
            detail["id"]?.toString() ??
            "";
        if (detailId.isEmpty || detailId == currentOpeningId) continue;
        final sameTime =
            (detail["start_time"]?.toString() == currentStart) &&
                (detail["end_time"]?.toString() == currentEnd);
        if (!sameTime) continue;
        final applicants = (detail["applicants"] as List?) ?? [];
        for (final applicant in applicants) {
          if (applicant is! Map) continue;
          final status = applicant["status"]?.toString().toUpperCase();
          final assigned = applicant["is_assigned"] == true;
          if (status != "ACCEPTED" && !assigned) continue;
          final nurse = applicant["nurse"];
          String? empId;
          if (nurse is Map) {
            empId = nurse["id"]?.toString() ??
                nurse["employee_id"]?.toString() ??
                nurse["nurse_id"]?.toString();
          }
          empId ??= applicant["employee_id"]?.toString() ??
              applicant["nurse_id"]?.toString();
          if (empId == null || empId.isEmpty) continue;
          final applicantId = applicant["applicant_id"]?.toString() ??
              applicant["id"]?.toString() ??
              "";
          if (applicantId.isEmpty) continue;
          transferMap[empId] = {
            "applicantId": applicantId,
            "openingId": detailId,
            "openingDailyId": detailOpeningDailyId,
            "scheduleShiftId": detailScheduleShiftId,
          };
        }
      }
    }
    final assignedIds = assignedEmployees
        .map(_employeeIdFromMap)
        .whereType<String>()
        .toSet();
    final isFull = counts.total > 0 && counts.filled >= counts.total;

    Future<void> handleAssignSingle(Map<String, dynamic> employee) async {
      await _handleAssign(
        context,
        controller: controller,
        opening: opening,
        selectedEmployees: [employee],
      );
    }



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

          const SizedBox(height: 4),

          Text(

            [unit, department].where((e) => e.isNotEmpty).join(" - "),

            style: Theme.of(context)

                .textTheme

                .bodyMedium

                ?.copyWith(color: AppColors.greyBlue),

          ),

          const SizedBox(height: 12),

          if (layers.isNotEmpty) ...[

            Wrap(

              spacing: 8,

              children: layers.map((layer) {

                final id = layer["daily_opening_layer_id"]?.toString() ?? "";

                final index = layers.indexOf(layer) + 1;

                final active = id == selectedLayerId;

                return ChoiceChip(

                  label: Text("Option $index"),

                  selected: active,

                  onSelected: (_) => onSelectLayer(id),

                  selectedColor: AppColors.greyBlue,

                  labelStyle: TextStyle(

                    color: active ? Colors.white : AppColors.greyBlue,

                  ),

                );

              }).toList(),

            ),

            const SizedBox(height: 10),

          ],

          _ShiftSelector(

            layers: layers,

            selectedLayerId: selectedLayerId,

            selectedShiftId: selectedShiftId,

            onSelectShift: onSelectShift,

          ),

          const SizedBox(height: 12),
          _SectionHeader(
            title: "Positions ${counts.filled}/${counts.total} Filled",
          ),
          const SizedBox(height: 10),
          _SectionHeader(title: "Assigned"),
          const SizedBox(height: 8),
          if (assignedEmployees.isNotEmpty)
            ...assignedEmployees.map((employee) {
              final name = _employeeName(employee);
              final role = _employeeRole(employee);
              final employeeId = _employeeIdFromMap(employee);
              final applicantId = _employeeApplicantId(employee) ??
                  (employeeId != null
                      ? applicantIdByEmployeeId[employeeId]
                      : null);
              final openingDailyId = _openingId(opening);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.lightGray),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.lightGray,
                      child: const Icon(
                        Icons.person,
                        color: AppColors.greyBlue,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.lightPink,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.primary),
                            ),
                            child: Text(
                              name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                            ),
                          ),
                          if (role.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              role,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.greyBlue),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (applicantId != null)
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.primary),
                        onPressed: () async {
                          final ok = await _confirm(
                            context,
                            "Remove this employee from the shift?",
                          );
                          if (!ok) return;
                          final success = await controller.unassignApplicant(
                            openingDailyId: openingDailyId,
                            applicantId: applicantId,
                          );
                          if (context.mounted) {
                            _showSnack(
                              context,
                              success
                                  ? "Employee unassigned"
                                  : "Unassign failed",
                            );
                          }
                        },
                      )
                    else
                      const Icon(Icons.check_circle, color: AppColors.primary),
                  ],
                ),
              );
            }),
          const SizedBox(height: 12),
          _SectionHeader(title: "Available"),
          const SizedBox(height: 8),
          if (employees.isEmpty && maxSelectable <= 0)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightPink.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.lightGray),
              ),
              child: const Text("All positions are filled."),
            )
          else
            SizedBox(
              height: 360,
              child: _EmployeesAssignList(
                employees: employees,
                loading: employeesLoading,
                search: employeeSearch,
                onSearch: onEmployeeSearch,
                onAssignEmployee: handleAssignSingle,
                assignDisabled: isFull,
                assignedIds: assignedIds,
                transferMap: transferMap,
                transferDisabled: controller.state.actionLoading,
                onTransferEmployee: (employee) async {
                  final empId = _employeeIdFromMap(employee);
                  if (empId == null) return;
                  final transfer = transferMap[empId];
                  if (transfer == null) return;
                  final targetOpeningDailyId = opening["opening_daily_id"]?.toString() ??
                      opening["daily_opening_id"]?.toString() ??
                      opening["opening_daily"]?.toString() ??
                      opening["id"]?.toString() ??
                      _openingId(opening);
                  final targetLayerId = opening["opening_layer_daily_id"]?.toString() ??
                      opening["daily_opening_layer_id"]?.toString() ??
                      opening["opening_layer_id"]?.toString() ??
                      selectedLayerId;
                  debugPrint(
                    "Transfer: empId=$empId applicantId=${transfer["applicantId"]} targetOpeningDailyId=$targetOpeningDailyId targetLayerId=$targetLayerId fromOpeningId=${transfer["openingId"]}",
                  );
                    final priorOpeningDailyId =
                        transfer["openingDailyId"] ?? transfer["openingId"] ?? "";
                    if (priorOpeningDailyId.isNotEmpty) {
                      await controller.unassignApplicant(
                        openingDailyId: priorOpeningDailyId,
                        applicantId: transfer["applicantId"] ?? "",
                      );
                    }
                  final ok = await controller.updateApplicantStatusV2(
                    openingDailyId: targetOpeningDailyId,
                    applicantId: transfer["applicantId"] ?? "",
                    status: "ACCEPTED",
                  );
                  controller.applyLocalTransfer(
                    fromOpeningId: transfer["openingId"] ?? "",
                    toOpeningId: currentOpeningId,
                    employee: employee,
                  );
                  if (context.mounted) {
                    _showSnack(context, "Transferred");
                  }
                  if (ok) {
                    await controller.fetchOpenings();
                    await controller.fetchApplicants();
                    await controller.fetchEmployees();
                  }
                },
              ),
            ),

        ],
      );

  }

}



class _ShiftSelector extends StatelessWidget {

  const _ShiftSelector({

    required this.layers,

    required this.selectedLayerId,

    required this.selectedShiftId,

    required this.onSelectShift,

  });



  final List<Map<String, dynamic>> layers;

  final String? selectedLayerId;

  final String? selectedShiftId;

  final ValueChanged<String> onSelectShift;



  @override

  Widget build(BuildContext context) {

    if (layers.isEmpty) {

      return const SizedBox.shrink();

    }

    final layer = layers.firstWhere(

      (l) => l["daily_opening_layer_id"]?.toString() == selectedLayerId,

      orElse: () => layers.first,

    );

    final schedules = (layer["schedule_details"] as List?) ?? [];

    if (schedules.isEmpty) {

      return const Text("No shifts in this layer.");

    }

    return SizedBox(

      height: 70,

      child: ListView.separated(

        scrollDirection: Axis.horizontal,

        itemCount: schedules.length,

        separatorBuilder: (_, __) => const SizedBox(width: 8),

        itemBuilder: (context, index) {

          final schedule = schedules[index];

          if (schedule is! Map) return const SizedBox.shrink();

          final shiftId = schedule["shift_id"]?.toString() ??

              schedule["id"]?.toString() ??

              schedule["schedule_id"]?.toString() ??

              "";

          final time = _timeRange(

            schedule["start_time"]?.toString(),

            schedule["end_time"]?.toString(),

          );

          final count = schedule["applicant_count"] ?? 0;

          final selected = shiftId == selectedShiftId;

          return InkWell(

            onTap: () => onSelectShift(shiftId),

            borderRadius: BorderRadius.circular(10),

            child: Container(

              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),

              decoration: BoxDecoration(

                color: selected ? AppColors.primary : AppColors.offwhite,

                borderRadius: BorderRadius.circular(10),

                border: Border.all(

                  color: selected ? AppColors.primary : AppColors.lightGray,

                ),

              ),

              child: Column(

                mainAxisAlignment: MainAxisAlignment.center,

                children: [

                  Text(

                    time.isEmpty ? "Shift" : time,

                    style: Theme.of(context).textTheme.labelLarge?.copyWith(

                          color: selected ? Colors.white : AppColors.greyBlue,

                        ),

                  ),

                  const SizedBox(height: 4),

                  Text(

                    "$count apps",

                    style: Theme.of(context).textTheme.labelSmall?.copyWith(

                          color: selected ? Colors.white70 : AppColors.greyBlue,

                        ),

                  ),

                ],

              ),

            ),

          );

        },

      ),

    );

  }

}



class _ApplicantsList extends StatelessWidget {

  const _ApplicantsList({

    required this.applicants,

    required this.loading,

    required this.search,

    required this.onSearch,

  });



  final List<Map<String, dynamic>> applicants;

  final bool loading;

  final String search;

  final ValueChanged<String> onSearch;



  @override

  Widget build(BuildContext context) {

    return Column(

      children: [

        TextField(

          decoration: const InputDecoration(

            hintText: "Search applicants",

            prefixIcon: Icon(Icons.search),

          ),

          onChanged: onSearch,

          controller: TextEditingController(text: search)

            ..selection = TextSelection.fromPosition(

              TextPosition(offset: search.length),

            ),

        ),

        const SizedBox(height: 10),

        Expanded(

          child: loading

              ? const Center(child: CircularProgressIndicator())

              : applicants.isEmpty

                  ? const Center(child: Text("No applicants"))

                  : ListView.separated(

                      itemCount: applicants.length,

                      separatorBuilder: (_, __) => const SizedBox(height: 8),

                      itemBuilder: (context, index) {

                        final applicant = applicants[index];

                        final nurse = applicant["nurse"] ?? applicant;

                        final name =

                            "${nurse["first_name"] ?? ""} ${nurse["last_name"] ?? ""}"

                                .trim();

                        final status = applicant["status"]?.toString() ?? "";

                        final job = applicant["shift_position"]?.toString() ??

                            nurse["job_title"]?.toString() ??

                            "";

                        return Container(

                          padding: const EdgeInsets.all(12),

                          decoration: BoxDecoration(

                            color: AppColors.white,

                            borderRadius: BorderRadius.circular(10),

                            border: Border.all(color: AppColors.lightGray),

                          ),

                          child: Row(

                            children: [

                              CircleAvatar(

                                backgroundColor: AppColors.offwhite,

                                child: Text(name.isNotEmpty ? name[0] : "?"),

                              ),

                              const SizedBox(width: 10),

                              Expanded(

                                child: Column(

                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [

                                    Text(

                                      name.isEmpty ? "Applicant" : name,

                                      style: Theme.of(context)

                                          .textTheme

                                          .titleMedium

                                          ?.copyWith(fontWeight: FontWeight.w700),

                                    ),

                                    if (job.isNotEmpty)

                                      Text(

                                        job,

                                        style: Theme.of(context)

                                            .textTheme

                                            .bodyMedium

                                            ?.copyWith(color: AppColors.greyBlue),

                                      ),

                                  ],

                                ),

                              ),

                              if (status.isNotEmpty)

                                Container(

                                  padding: const EdgeInsets.symmetric(

                                      horizontal: 8, vertical: 4),

                                  decoration: BoxDecoration(

                                    color: AppColors.lightPink,

                                    borderRadius: BorderRadius.circular(10),

                                  ),

                                  child: Text(

                                    status,

                                    style: Theme.of(context)

                                        .textTheme

                                        .labelSmall

                                        ?.copyWith(color: AppColors.primary),

                                  ),

                                ),

                            ],

                          ),

                        );

                      },

                    ),

        ),

      ],

    );

  }

}



class _EmployeesAssignList extends StatelessWidget {

  const _EmployeesAssignList({

    required this.employees,

    required this.loading,

    required this.search,

    required this.onSearch,

    required this.onAssignEmployee,
    required this.assignDisabled,
    required this.assignedIds,
    required this.transferMap,
    required this.onTransferEmployee,
    required this.transferDisabled,

  });



  final List<Map<String, dynamic>> employees;

  final bool loading;

  final String search;

  final ValueChanged<String> onSearch;

  final ValueChanged<Map<String, dynamic>> onAssignEmployee;
  final bool assignDisabled;
  final Set<String> assignedIds;
  final Map<String, Map<String, String>> transferMap;
  final ValueChanged<Map<String, dynamic>> onTransferEmployee;
  final bool transferDisabled;



  @override

  Widget build(BuildContext context) {

    return Column(

      children: [

        TextField(

          decoration: const InputDecoration(

            hintText: "Search employees",

            prefixIcon: Icon(Icons.search),

          ),

          onChanged: onSearch,

          controller: TextEditingController(text: search)

            ..selection = TextSelection.fromPosition(

              TextPosition(offset: search.length),

          ),

        ),

        const SizedBox(height: 10),

        Align(

          alignment: Alignment.centerLeft,

          child: Text(

            "Available",

            style: Theme.of(context)

                .textTheme

                .labelLarge

                ?.copyWith(color: AppColors.greyBlue),

          ),

        ),

        const SizedBox(height: 8),

        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : employees.isEmpty
                  ? const Center(child: Text("No employees"))
                  : ListView.separated(
                      itemCount: employees.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final employee = employees[index];
                        final employeeId = _employeeIdFromMap(employee);
                        final isAssigned =
                            employeeId != null && assignedIds.contains(employeeId);
                        final hasTransfer = employeeId != null &&
                            transferMap.containsKey(employeeId);
                        final name =
                            "${employee["first_name"] ?? ""} ${employee["last_name"] ?? ""}"
                                .trim();
                        final job = employee["job_title"]?.toString() ?? "";
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.lightGray,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.lightGray,
                                child: const Icon(
                                  Icons.person,
                                  color: AppColors.greyBlue,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name.isEmpty ? "Employee" : name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    if (job.isNotEmpty)
                                      Text(
                                        job,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(color: AppColors.greyBlue),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (hasTransfer && !isAssigned)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: SizedBox(
                                    height: 32,
                                    child: ElevatedButton(
                                      onPressed: transferDisabled
                                          ? null
                                          : () => onTransferEmployee(employee),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                      ),
                                      child: const Text("Transfer"),
                                    ),
                                  ),
                                ),
                              SizedBox(
                                height: 32,
                                child: OutlinedButton(
                                  onPressed: (assignDisabled || isAssigned)
                                      ? null
                                      : () => onAssignEmployee(employee),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: (assignDisabled || isAssigned)
                                        ? AppColors.greyBlue
                                        : AppColors.primary,
                                    side: BorderSide(
                                      color: (assignDisabled || isAssigned)
                                          ? AppColors.lightGray
                                          : AppColors.lightGray,
                                    ),
                                    backgroundColor: AppColors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                  ),
                                  child: Text(isAssigned ? "Assigned" : "Assign"),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),

      ],

    );

  }

}

Future<void> _pickDate(

  BuildContext context,

  DailyScheduleController controller,

  DateTime current,

) async {

  final picked = await showDatePicker(

    context: context,

    initialDate: current,

    firstDate: DateTime(2020),

    lastDate: DateTime(2100),

  );

  if (picked != null) controller.setDate(picked);

}



Future<void> _openOpeningEditor(

  BuildContext context, {

  required DailyScheduleController controller,

  required DailyScheduleState state,

  Map<String, dynamic>? initial,

}) async {

  final isEdit = initial != null;

  final result = await showModalBottomSheet<Map<String, dynamic>>(

    context: context,

    isScrollControlled: true,

    shape: const RoundedRectangleBorder(

      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),

    ),

    builder: (context) => DailyOpeningEditor(

      date: state.date,

      departments: state.departments,

      jobTitles: state.jobTitles,

      units: state.units,

      colors: state.colors,

      initialOpening: initial,

    ),

  );



  if (result == null) return;

  if (isEdit) {

    final id = _openingId(initial!);

    final ok = await controller.updateOpening(id, result);

    if (context.mounted) {

      _showSnack(context, ok ? "Opening updated" : "Update failed");

    }

  } else {

    final ok = await controller.createOpening(result);

    if (context.mounted) {

      _showSnack(context, ok ? "Opening created" : "Create failed");

    }

  }

}



Future<void> _handleAssign(

  BuildContext context, {

  required DailyScheduleController controller,

  required Map<String, dynamic> opening,

  required List<Map<String, dynamic>> selectedEmployees,

}) async {

  if (selectedEmployees.isEmpty) {

    _showSnack(context, "Select employees first.");

    return;

  }

  var maxSelectable =
      _maxSelectableForOpening(opening, controller.state.selectedScheduleShiftId);
  if (maxSelectable <= 0 && selectedEmployees.isNotEmpty) {
    maxSelectable = 1;
  }
  if (selectedEmployees.length > maxSelectable) {
    _showSnack(
      context,
      "Only $maxSelectable position${maxSelectable == 1 ? "" : "s"} available.",
    );
    return;
  }
  if (maxSelectable <= 0) {
    _showSnack(context, "No open positions available.");
    return;
  }



  final openingJobTitles = (opening["job_titles"] as List?)

          ?.whereType<Map>()

          .map((e) => e["id"]?.toString())

          .whereType<String>()

          .toList() ??

      [];
  final allJobTitles = controller.state.jobTitles;

  final firstEmp = selectedEmployees.first;

  final empJobTitle = firstEmp["job_title_id"]?.toString() ?? "";
  final empJobTitleLabel = firstEmp["job_title"]?.toString() ??
      firstEmp["job_title_name"]?.toString() ??
      (empJobTitle.isNotEmpty
          ? _findJobTitleLabel(opening, empJobTitle)
          : "");
  final targetDepartment = opening["department"]?["name"]?.toString() ?? "";



  final needsJobTitleChoice =
      empJobTitle.isEmpty || openingJobTitles.isEmpty || !openingJobTitles.contains(empJobTitle);
  if (needsJobTitleChoice) {

    final options = (allJobTitles.isNotEmpty
            ? allJobTitles
                .whereType<Map<String, dynamic>>()
                .map((e) => {
                      "id": e["id"]?.toString(),
                      "label": e["name"]?.toString() ??
                          e["abbreviation"]?.toString() ??
                          e["id"]?.toString() ??
                          "",
                    })
                .toList()
            : openingJobTitles
                .map((id) => {"id": id, "label": _findJobTitleLabel(opening, id)})
                .toList())
        .where((e) => (e["id"]?.toString() ?? "").isNotEmpty)
        .toList();

    final result = await showModalBottomSheet<_JobTitleChoice>(

      context: context,

      isScrollControlled: true,

      shape: const RoundedRectangleBorder(

        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),

      ),

      builder: (context) => _JobTitleConflictSheet(

        employee: firstEmp,

        jobTitleOptions: options,

        selectedId: empJobTitle,
        currentJobTitleLabel: empJobTitleLabel,
        targetDepartmentName: targetDepartment,

      ),

    );



    if (result == null) return;



    String? overrideId;

    if (result.keepCurrent) {

      await controller.ensureJobTitleOnOpening(empJobTitle);

      overrideId = empJobTitle;

    } else {
      overrideId = result.selectedJobTitleId;
      if (overrideId != null &&
          overrideId.isNotEmpty &&
          !openingJobTitles.contains(overrideId)) {
        await controller.ensureJobTitleOnOpening(overrideId);
      }
    }



    final ok = await controller.assignEmployees(

      overrideJobTitleId: overrideId,

      employees: selectedEmployees,

    );

    if (context.mounted) {
      final message = ok
          ? "Assigned"
          : controller.state.actionError ?? "Assignment failed";
      _showSnack(context, message);
    }

    return;

  }



  final ok = await controller.assignEmployees(employees: selectedEmployees);

  if (context.mounted) {
    final message =
        ok ? "Assigned" : controller.state.actionError ?? "Assignment failed";
    _showSnack(context, message);
  }

}



class _JobTitleChoice {

  const _JobTitleChoice({required this.keepCurrent, this.selectedJobTitleId});



  final bool keepCurrent;

  final String? selectedJobTitleId;

}



class _JobTitleConflictSheet extends StatefulWidget {

  const _JobTitleConflictSheet({

    required this.employee,

    required this.jobTitleOptions,

    required this.selectedId,
    required this.currentJobTitleLabel,
    required this.targetDepartmentName,

  });



  final Map<String, dynamic> employee;

  final List<Map<String, dynamic>> jobTitleOptions;

  final String selectedId;
  final String currentJobTitleLabel;
  final String targetDepartmentName;



  @override

  State<_JobTitleConflictSheet> createState() => _JobTitleConflictSheetState();

}



class _JobTitleConflictSheetState extends State<_JobTitleConflictSheet> {

  bool keepCurrent = true;

  String? selectedId;
  final TextEditingController _titleSearch = TextEditingController();



  @override

  void initState() {

    super.initState();

    final uniqueOptions = <String>{};
    for (final opt in widget.jobTitleOptions) {
      final id = opt["id"]?.toString();
      if (id != null && id.isNotEmpty) uniqueOptions.add(id);
    }
    if (uniqueOptions.contains(widget.selectedId)) {
      selectedId = widget.selectedId;
    } else if (uniqueOptions.isNotEmpty) {
      selectedId = uniqueOptions.first;
    } else {
      selectedId = null;
    }

  }

  @override
  void dispose() {
    _titleSearch.dispose();
    super.dispose();
  }



  @override

  Widget build(BuildContext context) {

    final name =

        "${widget.employee["first_name"] ?? ""} ${widget.employee["last_name"] ?? ""}"

            .trim();
    final jobTitle = widget.currentJobTitleLabel;
    final targetDept = widget.targetDepartmentName;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom +
              16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

          Row(

            children: [

              Text(

                "Cross-Department Assignment",

                style: Theme.of(context)

                    .textTheme

                    .titleMedium

                    ?.copyWith(fontWeight: FontWeight.w700),

              ),

              const Spacer(),

              IconButton(

                onPressed: () => Navigator.pop(context),

                icon: const Icon(Icons.close),

              ),

            ],

          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightGray),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text(
                    name.isNotEmpty ? name[0] : "?",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? "Employee" : name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (jobTitle.isNotEmpty) jobTitle,
                          "Current Department"
                        ].join(" • "),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.greyBlue),
                      ),
                    ],
                  ),
                ),
                if (targetDept.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.lightPink,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: Text(
                      "Assigning to\n$targetDept",
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: AppColors.primary),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Align(

            alignment: Alignment.centerLeft,

            child: Text(

              "What job title should be considered for this shift?",

              style: Theme.of(context).textTheme.bodyMedium,

            ),

          ),

          const SizedBox(height: 8),

          RadioListTile<bool>(
            value: true,
            groupValue: keepCurrent,
            onChanged: (value) => setState(() => keepCurrent = value ?? true),
            title: Text(
              jobTitle.isNotEmpty ? "Keep current title: $jobTitle" : "Keep current title",
            ),
            subtitle: Text(
              jobTitle.isNotEmpty
                  ? "Employee works as $jobTitle in Current Department"
                  : "Employee works in Current Department",
            ),
            activeColor: AppColors.primary,
          ),
          RadioListTile<bool>(
            value: false,
            groupValue: keepCurrent,
            onChanged: (value) => setState(() => keepCurrent = value ?? false),
            title: const Text("Select a different title"),
            subtitle: const Text("Choose a different title from the list"),
            activeColor: AppColors.primary,
          ),

          if (!keepCurrent) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await _showJobTitlePicker(
                  context,
                  widget.jobTitleOptions,
                  selectedId,
                );
                if (picked != null) {
                  setState(() => selectedId = picked);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Choose a job title...",
                ),
                child: Text(
                  _jobTitleLabel(widget.jobTitleOptions, selectedId) ??
                      "Choose a job title...",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          SizedBox(

            width: double.infinity,

            child: FilledButton(

              onPressed: () {
                if (!keepCurrent && (selectedId == null || selectedId!.isEmpty)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Select a job title first.")),
                  );
                  return;
                }

                Navigator.pop(

                  context,

                  _JobTitleChoice(

                    keepCurrent: keepCurrent,

                    selectedJobTitleId: selectedId,

                  ),

                );

              },

              child: const Text("Confirm"),

            ),

          ),

            ],
          ),
        ),
      ),
    );

  }

}

String? _jobTitleLabel(List<Map<String, dynamic>> options, String? id) {
  if (id == null || id.isEmpty) return null;
  for (final opt in options) {
    final optId = opt["id"]?.toString();
    if (optId == id) {
      return opt["label"]?.toString() ?? optId;
    }
  }
  return null;
}

Future<String?> _showJobTitlePicker(
  BuildContext context,
  List<Map<String, dynamic>> options,
  String? selectedId,
) {
  final Map<String, String> unique = {};
  for (final opt in options) {
    final id = opt["id"]?.toString();
    if (id == null || id.isEmpty) continue;
    unique.putIfAbsent(id, () => opt["label"]?.toString() ?? id);
  }
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      final controller = TextEditingController();
      String query = "";
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).padding.bottom +
                16,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              final items = unique.entries
                  .where((entry) => entry.value
                      .toLowerCase()
                      .contains(query.toLowerCase()))
                  .toList();
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: "Search job title",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) =>
                        setState(() => query = value.trim()),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 320,
                    child: ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final entry = items[index];
                        final isSelected = entry.key == selectedId;
                        return ListTile(
                          title: Text(entry.value),
                          trailing: isSelected
                              ? const Icon(Icons.check, color: AppColors.primary)
                              : null,
                          onTap: () => Navigator.pop(context, entry.key),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}

class DailyOpeningEditor extends StatefulWidget {

  const DailyOpeningEditor({

    super.key,

    required this.date,

    required this.departments,

    required this.jobTitles,

    required this.units,

    required this.colors,

    this.initialOpening,

  });



  final DateTime date;

  final List<Map<String, dynamic>> departments;

  final List<Map<String, dynamic>> jobTitles;

  final List<Map<String, dynamic>> units;

  final List<Map<String, dynamic>> colors;

  final Map<String, dynamic>? initialOpening;



  @override

  State<DailyOpeningEditor> createState() => _DailyOpeningEditorState();

}



class _DailyOpeningEditorState extends State<DailyOpeningEditor> {

  late TextEditingController nameController;

  late TextEditingController openingsController;

  late TextEditingController mealController;

  late TextEditingController patientController;



  String? selectedDepartmentId;

  List<String> selectedJobTitles = [];

  List<String> selectedUnits = [];

  String? selectedColorId;

  TimeOfDay? startTime;

  TimeOfDay? endTime;

  bool isOptional = false;



  @override

  void initState() {

    super.initState();

    final opening = widget.initialOpening ?? {};

    nameController =

        TextEditingController(text: opening["name"]?.toString() ?? "");

    openingsController =

        TextEditingController(text: "${opening["total_openings"] ?? 1}");

    mealController =

        TextEditingController(text: "${opening["meal_time"] ?? 0}");

    patientController =

        TextEditingController(text: "${opening["patient_count"] ?? 0}");



    selectedDepartmentId = opening["department"]?["id"]?.toString();

    selectedJobTitles = (opening["job_titles"] as List?)

            ?.whereType<Map>()

            .map((e) => e["id"]?.toString())

            .whereType<String>()

            .toList() ??

        [];



    if (opening["unit_id"] != null) {

      selectedUnits = [opening["unit_id"].toString()];

    }



    final layer = _firstLayer(opening);

    final schedule = _firstSchedule(layer);

    startTime = _parseApiTime(schedule["start_time"]?.toString());

    endTime = _parseApiTime(schedule["end_time"]?.toString());

    selectedColorId = schedule["color"]?.toString();

    isOptional = schedule["is_optional"] == true;

  }



  @override

  void dispose() {

    nameController.dispose();

    openingsController.dispose();

    mealController.dispose();

    patientController.dispose();

    super.dispose();

  }



  @override

  Widget build(BuildContext context) {

    final height = MediaQuery.of(context).size.height * 0.92;

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

                widget.initialOpening == null ? "New Opening" : "Edit Opening",

                style: Theme.of(context).textTheme.titleMedium,

              ),

              const SizedBox(height: 12),

              Expanded(

                child: ListView(

                  children: [

                    _FieldLabel("Opening name"),

                    TextField(

                      controller: nameController,

                      decoration: const InputDecoration(

                        hintText: "Enter opening name",

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

                    const SizedBox(height: 12),

                    Row(

                      children: [

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
                    const SizedBox(height: 16),
                    _SectionHeader(title: "Openings"),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            "Each opening can have its own floor and time",
                            style: TextStyle(color: AppColors.greyBlue),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () {
                            final current =
                                int.tryParse(openingsController.text) ?? 0;
                            final next = current + 1;
                            openingsController.text = next.toString();
                            setState(() {});
                          },
                          icon: const Icon(Icons.add),
                          label: const Text("Add Opening"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(
                      (int.tryParse(openingsController.text) ?? 1).clamp(1, 20),
                      (index) {
                        final number = index + 1;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.lightPink.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.lightGray),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        "$number",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Opening #$number",
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _FieldLabel("Select Unit and Sub Unit"),
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
                              const SizedBox(height: 10),
                              _FieldLabel("Shift Time"),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () async {
                                        final picked = await showTimePicker(
                                          context: context,
                                          initialTime: startTime ??
                                              const TimeOfDay(
                                                  hour: 7, minute: 0),
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
                                          initialTime: endTime ??
                                              const TimeOfDay(
                                                  hour: 15, minute: 0),
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
                              const SizedBox(height: 10),
                              _NumberField(
                                label: "Mealbreak (min)",
                                controller: mealController,
                              ),
                              const SizedBox(height: 10),
                              _FieldLabel("Job Titles Who Can Pick This Up"),
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
                            ],
                          ),
                        );
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

                                color: selected

                                    ? AppColors.black

                                    : Colors.transparent,

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

                      onPressed: () {

                        final errors = _validateOpening(

                          name: nameController.text,

                          departmentId: selectedDepartmentId,

                          start: startTime,

                          end: endTime,

                          jobTitles: selectedJobTitles,

                          units: selectedUnits,

                          openings: openingsController.text,

                          color: selectedColorId,

                        );

                        if (errors.isNotEmpty) {

                          _showSnack(context, errors.first);

                          return;

                        }

                        final payload = _buildDailyOpeningPayload(

                          name: nameController.text.trim(),

                          departmentId: selectedDepartmentId!,

                          date: widget.date,

                          start: startTime!,

                          end: endTime!,

                          jobTitles: selectedJobTitles,

                          units: selectedUnits,

                          meal: int.tryParse(mealController.text) ?? 0,

                          patient: int.tryParse(patientController.text) ?? 0,

                          openings: int.tryParse(openingsController.text) ?? 1,

                          colorId: selectedColorId!,

                          isOptional: isOptional,

                          unitsData: widget.units,

                        );

                        Navigator.pop(context, payload);

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

      borderRadius: BorderRadius.circular(10),

      child: Container(

        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),

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

            if (count > 0)

              Container(

                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),

                decoration: BoxDecoration(

                  color: AppColors.primary,

                  borderRadius: BorderRadius.circular(10),

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

      final selectedIds = [...selected];

      String query = "";

      return StatefulBuilder(

        builder: (context, setState) {

          final filtered = items.where((item) {

            final name = item["name"]?.toString().toLowerCase() ?? "";

            return name.contains(query.toLowerCase());

          }).toList();



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

                    Text(title, style: Theme.of(context).textTheme.titleMedium),

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

                          final item = filtered[index];

                          final id = item["id"]?.toString() ?? "";

                          final name = item["name"]?.toString() ?? "";

                          final checked = selectedIds.contains(id);

                          return CheckboxListTile(

                            value: checked,

                            onChanged: (_) {

                              setState(() {

                                if (checked) {

                                  selectedIds.remove(id);

                                } else {

                                  selectedIds.add(id);

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

                    const SizedBox(height: 8),

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

                            onPressed: () => Navigator.pop(context, selectedIds),

                            child: const Text("Apply"),

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

      final selectedIds = [...selected];

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

                Text("Units", style: Theme.of(context).textTheme.titleMedium),

                const SizedBox(height: 12),

                Expanded(

                  child: ListView(

                    children: units.map((unit) {

                      final unitId = unit["id"]?.toString() ?? "";

                      final unitName = unit["name"]?.toString() ?? "";

                      final subunits = (unit["subunits"] as List?) ?? [];

                      final unitChecked = selectedIds.contains(unitId);

                      return Column(

                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [

                          CheckboxListTile(

                            value: unitChecked,

                            onChanged: (_) {

                              if (unitChecked) {

                                selectedIds.remove(unitId);

                              } else {

                                selectedIds.add(unitId);

                              }

                              (context as Element).markNeedsBuild();

                            },

                            title: Text(unitName),

                            controlAffinity: ListTileControlAffinity.trailing,

                            activeColor: AppColors.primary,

                          ),

                          if (subunits.isNotEmpty)

                            Padding(

                              padding: const EdgeInsets.only(left: 12),

                              child: Column(

                                children: subunits.whereType<Map>().map((sub) {

                                  final subId = sub["id"]?.toString() ?? "";

                                  final subName = sub["name"]?.toString() ?? "";

                                  final checked = selectedIds.contains(subId);

                                  return CheckboxListTile(

                                    value: checked,

                                    onChanged: (_) {

                                      if (checked) {

                                        selectedIds.remove(subId);

                                      } else {

                                        selectedIds.add(subId);

                                      }

                                      (context as Element).markNeedsBuild();

                                    },

                                    title: Text(subName),

                                    controlAffinity: ListTileControlAffinity.trailing,

                                    activeColor: AppColors.primary,

                                  );

                                }).toList(),

                              ),

                            ),

                        ],

                      );

                    }).toList(),

                  ),

                ),

                const SizedBox(height: 8),

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

                        onPressed: () => Navigator.pop(context, selectedIds),

                        child: const Text("Apply"),

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

}

Map<String, dynamic> _buildDailyOpeningPayload({

  required String name,

  required String departmentId,

  required DateTime date,

  required TimeOfDay start,

  required TimeOfDay end,

  required List<String> jobTitles,

  required List<String> units,

  required int meal,

  required int patient,

  required int openings,

  required String colorId,

  required bool isOptional,

  required List<Map<String, dynamic>> unitsData,

}) {

  final unitOpenings = _buildUnitOpenings(

    selected: units,

    unitsData: unitsData,

    totalOpenings: openings,

  );



  return {

    "name": name,

    "department": departmentId,

    "job_titles": jobTitles,

    "date": _formatDate(date),

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



List<String> _validateOpening({

  required String name,

  required String? departmentId,

  required TimeOfDay? start,

  required TimeOfDay? end,

  required List<String> jobTitles,

  required List<String> units,

  required String openings,

  required String? color,

}) {

  final errors = <String>[];

  if (name.trim().isEmpty) errors.add("Opening name is required");

  if (departmentId == null || departmentId.isEmpty) {

    errors.add("Department is required");

  }

  if (start == null || end == null) errors.add("Shift time is required");

  if (jobTitles.isEmpty) errors.add("Select at least one job title");

  if (units.isEmpty) errors.add("Select at least one unit or subunit");

  if (openings.trim().isEmpty) errors.add("Openings is required");

  if (color == null || color.isEmpty) errors.add("Select a color");

  return errors;

}



Map<String, dynamic> _firstLayer(Map<String, dynamic> opening) {

  final layers = (opening["shift_layers"] as List?) ?? [];

  if (layers.isEmpty) return {};

  final first = layers.first;

  if (first is Map) return Map<String, dynamic>.from(first);

  return {};

}



Map<String, dynamic> _firstSchedule(Map<String, dynamic> layer) {

  final details = (layer["schedule_details"] as List?) ?? [];

  if (details.isEmpty) return {};

  final first = details.first;

  if (first is Map) return Map<String, dynamic>.from(first);

  return {};

}



String _formatTime(TimeOfDay? time) {

  if (time == null) return "Select time";

  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;

  final minutes = time.minute.toString().padLeft(2, "0");

  final suffix = time.period == DayPeriod.am ? "AM" : "PM";

  return "$hour:$minutes $suffix";

}



String _timeToApi(TimeOfDay time) {

  final hour = time.hour.toString().padLeft(2, "0");

  final minute = time.minute.toString().padLeft(2, "0");

  return "$hour:$minute";

}



TimeOfDay? _parseApiTime(String? value) {

  if (value == null || value.isEmpty) return null;

  final parts = value.split(":");

  if (parts.length < 2) return null;

  final h = int.tryParse(parts[0]) ?? 0;

  final m = int.tryParse(parts[1]) ?? 0;

  return TimeOfDay(hour: h, minute: m);

}



Color? _parseColor(Map<String, dynamic> colorData) {

  final hex = colorData["hex"]?.toString() ?? colorData["code"]?.toString();

  if (hex == null || hex.isEmpty) return null;

  final normalized = hex.replaceAll("#", "");

  if (normalized.length == 6) {

    return Color(int.parse("FF$normalized", radix: 16));

  }

  return null;

}



String _formatDate(DateTime date) {

  final mm = date.month.toString().padLeft(2, "0");

  final dd = date.day.toString().padLeft(2, "0");

  return "${date.year}-$mm-$dd";

}



String _openingId(Map<String, dynamic> opening) {

  return opening["opening_daily_id"]?.toString() ??
      opening["effective_parent_id"]?.toString() ??
      opening["daily_opening_id"]?.toString() ??
      opening["daily_opening"]?.toString() ??
      opening["opening_daily"]?.toString() ??
      opening["id"]?.toString() ??
      "";

}



String _weekdayShort(DateTime date) {

  const labels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

  return labels[date.weekday % 7];

}



bool _isSameDay(DateTime a, DateTime b) {

  return a.year == b.year && a.month == b.month && a.day == b.day;

}



String _timeRange(String? start, String? end) {

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



List<Map<String, dynamic>> _shiftLayers(Map<String, dynamic> opening) {

  final layers = opening["shift_layers"] as List? ?? [];

  return layers

      .whereType<Map>()

      .map((e) => Map<String, dynamic>.from(e))

      .toList();

}




List<Map<String, dynamic>> _deriveDepartments(List<Map<String, dynamic>> openings) {
  final map = <String, Map<String, dynamic>>{};
  int allCount = 0;
  for (final opening in openings) {
    allCount += 1;
    final dept = opening["department"];
    final id = dept is Map ? dept["id"]?.toString() : null;
    final name = dept is Map ? dept["name"]?.toString() : null;
    if (id == null || name == null) continue;
    map.putIfAbsent(id, () => {"id": id, "name": name, "count": 0});
    map[id]!["count"] = (map[id]!["count"] as int) + 1;
  }
  final list = map.values.toList();
  list.sort((a, b) => (a["name"]?.toString() ?? "").compareTo(
        b["name"]?.toString() ?? "",
      ));
  return [
    {"id": null, "name": "All Departments", "count": allCount},
    ...list,
  ];
}

List<Map<String, dynamic>> _filterOpeningsByDepartment(
  List<Map<String, dynamic>> openings,
  String? departmentId,
) {
  if (departmentId == null || departmentId.isEmpty) return openings;
  return openings.where((opening) {
    final dept = opening["department"];
    final id = dept is Map ? dept["id"]?.toString() : null;
    return id == departmentId;
  }).toList();
}

String _firstShiftTime(Map<String, dynamic> opening) {
  final parentStart = opening["parent_start_time"]?.toString();
  final parentEnd = opening["parent_end_time"]?.toString();
  if (parentStart != null && parentEnd != null) {
    return _timeRange(parentStart, parentEnd);
  }
  final layers = (opening["shift_layers"] as List?) ?? [];
  if (layers.isEmpty) return "";
  final layer = layers.firstWhere((_) => true, orElse: () => null);
  if (layer is! Map) return "";
  final details = (layer["schedule_details"] as List?) ?? [];
  if (details.isEmpty) return "";
  final first = details.first;
  if (first is! Map) return "";
  return _timeRange(
    first["start_time"]?.toString(),
    first["end_time"]?.toString(),
  );
}

int _openingsCount(Map<String, dynamic> opening) {
  final childCount = opening["child_count"];
  if (childCount is int) return childCount;
  final totalOpenings = opening["total_openings"] ?? opening["no_of_child_openings"];
  if (totalOpenings is int) return totalOpenings;
  final layers = (opening["shift_layers"] as List?) ?? [];
  int count = 0;
  for (final layer in layers) {
    if (layer is! Map) continue;
    final details = (layer["schedule_details"] as List?) ?? [];
    count += details.length;
  }
  return count;
}

String _openingTitle(Map<String, dynamic> opening) {
  return opening["parent_name"]?.toString() ??
      opening["title"]?.toString() ??
      opening["name"]?.toString() ??
      opening["shift_name"]?.toString() ??
      "Shift";
}

String _unitLabel(Map<String, dynamic> opening) {
  final unitData = opening["unit_data"];
  if (unitData is String && unitData.trim().isNotEmpty) {
    return unitData;
  }
  if (unitData is Map) {
    final name = unitData["name"] ??
        unitData["title"] ??
        unitData["unit_name"] ??
        unitData["label"];
    if (name != null) {
      final text = name.toString().trim();
      if (text.isNotEmpty) return text;
    }
  }
  if (unitData is List) {
    for (final item in unitData) {
      if (item is String && item.trim().isNotEmpty) {
        return item;
      }
      if (item is Map) {
        final name =
            item["name"] ?? item["title"] ?? item["unit_name"] ?? item["label"];
        if (name != null) {
          final text = name.toString().trim();
          if (text.isNotEmpty) return text;
        }
      }
    }
  }
  final fallback = opening["unit"] ??
      opening["unit_name"] ??
      opening["unit_title"] ??
      opening["department"];
  if (fallback is String && fallback.trim().isNotEmpty) {
    return fallback;
  }
  return "Whole building";
}

String _openingTime(Map<String, dynamic> opening) {
  final details = opening["shift_details"];
  if (details is Map) {
    final start = details["start_time"]?.toString();
    final end = details["end_time"]?.toString();
    if (start != null && end != null) {
      return _timeRange(start, end);
    }
  }
  if (details is List && details.isNotEmpty) {
    final first = details.first;
    if (first is Map) {
      final start = first["start_time"]?.toString();
      final end = first["end_time"]?.toString();
      if (start != null && end != null) {
        return _timeRange(start, end);
      }
    }
  }
  final scheduleDetails = opening["schedule_details"];
  if (scheduleDetails is Map) {
    final start = scheduleDetails["start_time"]?.toString();
    final end = scheduleDetails["end_time"]?.toString();
    if (start != null && end != null) {
      return _timeRange(start, end);
    }
  }
  if (scheduleDetails is List && scheduleDetails.isNotEmpty) {
    final first = scheduleDetails.first;
    if (first is Map) {
      final start = first["start_time"]?.toString();
      final end = first["end_time"]?.toString();
      if (start != null && end != null) {
        return _timeRange(start, end);
      }
    }
  }
  final scheduleShift = opening["schedule_shift"];
  if (scheduleShift is Map) {
    final start = scheduleShift["start_time"]?.toString();
    final end = scheduleShift["end_time"]?.toString();
    if (start != null && end != null) {
      return _timeRange(start, end);
    }
  }
  final parentStart = opening["parent_start_time"]?.toString();
  final parentEnd = opening["parent_end_time"]?.toString();
  if (parentStart != null && parentEnd != null) {
    return _timeRange(parentStart, parentEnd);
  }
  return _firstShiftTime(opening);
}

String _openingDateLabel(Map<String, dynamic> opening) {
  final raw = opening["date"] ??
      opening["shift_date"] ??
      opening["opening_date"] ??
      opening["schedule_date"];
  if (raw is DateTime) {
    return _formatHeaderDate(raw);
  }
  if (raw is String && raw.trim().isNotEmpty) {
    final parsed = _tryParseDate(raw.trim());
    if (parsed != null) {
      return _formatHeaderDate(parsed);
    }
  }
  return "";
}

DateTime? _tryParseDate(String value) {
  final direct = DateTime.tryParse(value);
  if (direct != null) return direct;
  final parts = value.split("/");
  if (parts.length == 3) {
    final m = int.tryParse(parts[0]);
    final d = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2].split(" ").first);
    if (m != null && d != null && y != null) {
      return DateTime(y, m, d);
    }
  }
  return null;
}

class _PositionCounts {
  const _PositionCounts({required this.filled, required this.total});

  final int filled;
  final int total;
}

_PositionCounts _shiftCountsForOpening(Map<String, dynamic> opening) {
  final mobileTotal = _asInt(opening["mobile_total_count"]);
  final mobileFilled = _asInt(opening["mobile_filled_count"]);
  if (mobileTotal != null) {
    final total = mobileTotal;
    final filled = (mobileFilled ?? 0).clamp(0, total);
    return _PositionCounts(filled: filled, total: total);
  }
  final details = opening["shift_details"];
  if (details is! List || details.isEmpty) {
    debugPrint(
      "SHIFT_COUNTS fallback: shift_details missing for ${opening["name"]} id=${_openingId(opening)} keys=${opening.keys.toList()}",
    );
    final total = _asInt(opening["child_count"]) ?? 0;
    final filled = _asInt(opening["applicant_count"]) ?? 0;
    return _PositionCounts(
      filled: filled.clamp(0, total),
      total: total,
    );
  }
  int total = 0;
  int filled = 0;
  for (final item in details) {
    if (item is! Map) continue;
    total += 1;
    final applicants = (item["applicants"] as List?) ?? [];
    final hasAssigned = applicants.any((a) {
      if (a is! Map) return false;
      final status = a["status"]?.toString().toUpperCase();
      final assigned = a["is_assigned"] == true;
      return status == "ACCEPTED" || assigned;
    });
    if (hasAssigned) filled += 1;
  }
  if (filled > total) filled = total;
  return _PositionCounts(filled: filled, total: total);
}

int _openingOpenCount(Map<String, dynamic> opening) {
  final rawShiftCount = opening["shift_count"];
  if (rawShiftCount != null) {
    debugPrint("shift_count raw: $rawShiftCount (${rawShiftCount.runtimeType})");
  }
  final rootChild = _asInt(opening["child_count"]);
  final rootApplicants = _asInt(opening["applicant_count"]);
  if (rootChild != null) {
    final open = rootChild - (rootApplicants ?? 0);
    return open < 0 ? 0 : open;
  }

  final shiftDetails = opening["shift_details"];
  if (shiftDetails is Map) {
    return 1;
  }
  if (shiftDetails is List && shiftDetails.isNotEmpty) {
    return shiftDetails.length;
  }

  final nested = opening["opening"];
  if (nested is Map) {
    final child = _asInt(nested["child_count"]);
    final applicants = _asInt(nested["applicant_count"]);
    if (child != null) {
      final open = child - (applicants ?? 0);
      return open < 0 ? 0 : open;
    }
  }

  final totalOpenings = _asInt(opening["total_openings"]) ??
      _asInt(opening["no_of_child_openings"]) ??
      _asInt(opening["open_positions"]);
  if (totalOpenings != null) return totalOpenings;

  final shiftCount = _asInt(rawShiftCount);
  if (shiftCount != null) return shiftCount;

  final shiftPositions = opening["shift_positions"];
  if (shiftPositions is List) {
    return shiftPositions.isNotEmpty ? 1 : 0;
  }

  return _openingsCount(opening);
}

_PositionCounts _positionCountsForOpening(
  Map<String, dynamic> opening,
  String? shiftId,
  int assignedCount,
) {
  final detail = _detailForShift(opening, shiftId);
  if (detail != null && identical(detail, opening)) {
    return _positionCountsForDetail(detail, useJobTitleFallback: false);
  }
  int? total;
  int? open;
  if (detail != null) {
    total = _asInt(detail["child_count"]) ??
        _asInt(detail["total_openings"]) ??
        _asInt(detail["no_of_child_openings"]) ??
        _asInt(detail["required_positions"]);
    open = _asInt(detail["open_positions"]);
  }
  total ??= _asInt(opening["child_count"]) ??
      _asInt(opening["total_openings"]) ??
      _asInt(opening["no_of_child_openings"]) ??
      _asInt(opening["open_positions"]);
  open ??= _openingOpenCount(opening);

  if (total == null && detail != null) {
    final applicantList = (detail["applicants"] as List?) ?? [];
    if (applicantList.isNotEmpty) {
      total = _asInt(detail["total_openings"]) ??
          _asInt(detail["child_count"]) ??
          _asInt(detail["no_of_child_openings"]) ??
          1;
    }
  }
  total ??= open > assignedCount ? open : assignedCount;
  if (total == 0) {
    if (detail != null) {
      final jobTitles = (detail["job_titles"] as List?) ?? [];
      final shiftPositions = (detail["shift_positions"] as List?) ?? [];
      total = jobTitles.isNotEmpty
          ? jobTitles.length
          : shiftPositions.isNotEmpty
              ? shiftPositions.length
              : 1;
    } else if (opening["shift_details"] is List &&
        (opening["shift_details"] as List).isNotEmpty) {
      total = (opening["shift_details"] as List).length;
    }
  }

  int filled = assignedCount;
  if (detail != null) {
    final applicantList = (detail["applicants"] as List?) ?? [];
    if (applicantList.isNotEmpty) {
      final accepted = applicantList.where((a) {
        if (a is! Map) return false;
        final status = a["status"]?.toString().toUpperCase();
        final assigned = a["is_assigned"] == true;
        return status == "ACCEPTED" || assigned;
      }).length;
      if (accepted > filled) filled = accepted;
    }
    final detailAssigned = _assignedEmployeesForDetail(detail).length;
    if (detailAssigned > filled) filled = detailAssigned;
  }
  if (filled > total) filled = total;
  if (filled < 0) filled = 0;
  return _PositionCounts(filled: filled, total: total);
}

_PositionCounts _positionCountsForDetail(
  Map<String, dynamic> detail, {
  bool useJobTitleFallback = true,
  bool forceSingle = false,
}) {
  int total = _asInt(detail["child_count"]) ??
      _asInt(detail["total_openings"]) ??
      _asInt(detail["no_of_child_openings"]) ??
      _asInt(detail["open_positions"]) ??
      _asInt(detail["required_positions"]) ??
      0;
  if (forceSingle) {
    total = 1;
  }
  if (total == 0 && useJobTitleFallback) {
    final jobTitles = (detail["job_titles"] as List?) ?? [];
    final shiftPositions = (detail["shift_positions"] as List?) ?? [];
    if (jobTitles.isNotEmpty) total = jobTitles.length;
    if (total == 0 && shiftPositions.isNotEmpty) total = shiftPositions.length;
  }
  final assignedCount = _assignedEmployeesForDetail(detail).length;
  final open = _asInt(detail["open_positions"]);
  final applicants = _asInt(detail["applicant_count"]);
  int filled;
  final useApplicants = applicants != null && applicants > 0;
  if (useApplicants && total > 0) {
    filled = applicants;
  } else if (open != null && total > 0) {
    filled = total - open;
  } else if (assignedCount > 0) {
    filled = assignedCount;
  } else {
    filled = 0;
  }
  final applicantList = (detail["applicants"] as List?) ?? [];
  if (applicantList.isNotEmpty) {
    final accepted = applicantList.where((a) {
      if (a is! Map) return false;
      final status = a["status"]?.toString().toUpperCase();
      final assigned = a["is_assigned"] == true;
      return status == "ACCEPTED" || assigned;
    }).length;
    if (accepted > filled) filled = accepted;
  }
  if (assignedCount > filled) filled = assignedCount;
  if (filled < 0) filled = 0;
  if (filled > total) filled = total;
  if (total == 0 && assignedCount > 0) total = assignedCount;
  if (total == 0) total = 1;
  int safeTotal = total == 0 && (open ?? 0) > 0 ? (open ?? 0) : total;
  if (safeTotal == 0 && assignedCount > 0) {
    safeTotal = assignedCount;
  }
  if (filled > safeTotal) filled = safeTotal;
  return _PositionCounts(filled: filled, total: safeTotal);
}

List<Map<String, dynamic>> _assignedEmployeesForOpening(
  Map<String, dynamic> opening,
  String? shiftId,
) {
  final results = <Map<String, dynamic>>[];
  final seenIds = <String>{};

  void addEmployee(dynamic data) {
    if (data == null) return;
    if (data is List) {
      for (final item in data) {
        addEmployee(item);
      }
      return;
    }
    if (data is Map) {
      final raw = Map<String, dynamic>.from(data);
      final candidate = (raw["employee"] is Map)
          ? Map<String, dynamic>.from(raw["employee"] as Map)
          : raw;
      final id = candidate["id"]?.toString() ??
          candidate["employee_id"]?.toString() ??
          raw["employee_id"]?.toString();
      if (id != null && id.isNotEmpty) {
        if (seenIds.contains(id)) return;
        seenIds.add(id);
      }
      results.add(candidate);
    }
  }

  final detail = _detailForShift(opening, shiftId);
  if (detail != null) {
    addEmployee(detail["accepted_employee"]);
    addEmployee(detail["accepted_employees"]);
    addEmployee(detail["assigned_employee"]);
    addEmployee(detail["assigned_employees"]);
    addEmployee(detail["filled_employees"]);
  }

  addEmployee(opening["accepted_employee"]);
  addEmployee(opening["accepted_employees"]);
  addEmployee(opening["assigned_employee"]);
  addEmployee(opening["assigned_employees"]);
  addEmployee(opening["filled_employees"]);
  final applicants = (opening["applicants"] as List?) ?? [];
  for (final item in applicants) {
    if (item is! Map) continue;
    final status = item["status"]?.toString().toUpperCase();
    final assigned = item["is_assigned"] == true;
    if (status == "ACCEPTED" || assigned) {
      final nurse = item["nurse"];
      if (nurse is Map) {
        addEmployee(nurse);
      } else {
        addEmployee(item);
      }
    }
  }

  return results;
}

List<Map<String, dynamic>> _assignedEmployeesForDetail(
  Map<String, dynamic> detail,
) {
  final results = <Map<String, dynamic>>[];
  final seenIds = <String>{};

  void addEmployee(dynamic data) {
    if (data == null) return;
    if (data is List) {
      for (final item in data) {
        addEmployee(item);
      }
      return;
    }
    if (data is Map) {
      final raw = Map<String, dynamic>.from(data);
      final candidate = (raw["employee"] is Map)
          ? Map<String, dynamic>.from(raw["employee"] as Map)
          : raw;
      final id = _employeeIdFromMap(candidate) ??
          candidate["employee_id"]?.toString() ??
          raw["employee_id"]?.toString();
      if (id != null && id.isNotEmpty) {
        if (seenIds.contains(id)) return;
        seenIds.add(id);
      }
      results.add(candidate);
    }
  }

  addEmployee(detail["accepted_employee"]);
  addEmployee(detail["accepted_employees"]);
  addEmployee(detail["assigned_employee"]);
  addEmployee(detail["assigned_employees"]);
  addEmployee(detail["filled_employees"]);
  final applicants = (detail["applicants"] as List?) ?? [];
  for (final item in applicants) {
    if (item is! Map) continue;
    final status = item["status"]?.toString().toUpperCase();
    final assigned = item["is_assigned"] == true;
    if (status == "ACCEPTED" || assigned) {
      final nurse = item["nurse"];
      if (nurse is Map) {
        addEmployee(nurse);
      } else {
        addEmployee(item);
      }
    }
  }

  return results;
}

Map<String, dynamic>? _detailForShift(
  Map<String, dynamic> opening,
  String? shiftId,
) {
  final details = opening["shift_details"];
  if (details == null) {
    // If opening already looks like a detail row, return it directly.
    final hasTiming = opening["start_time"] != null || opening["end_time"] != null;
    final hasPositions =
        opening["job_titles"] != null || opening["shift_positions"] != null;
    if (hasTiming || hasPositions) {
      return Map<String, dynamic>.from(opening);
    }
  }
  if (details is Map) return Map<String, dynamic>.from(details);
  if (details is List && details.isNotEmpty) {
    if (shiftId != null && shiftId.isNotEmpty) {
      for (final item in details) {
        if (item is! Map) continue;
        final id = item["shift_id"]?.toString() ??
            item["id"]?.toString() ??
            item["schedule_id"]?.toString() ??
            item["schedule_shift_id"]?.toString();
        if (id == shiftId) return Map<String, dynamic>.from(item);
      }
    }
    final first = details.first;
    if (first is Map) return Map<String, dynamic>.from(first);
  }
  return null;
}

String? _employeeIdFromMap(Map<String, dynamic> employee) {
  return employee["id"]?.toString() ??
      employee["employee_id"]?.toString() ??
      employee["nurse_id"]?.toString() ??
      employee["user_id"]?.toString();
}

String _employeeName(Map<String, dynamic> employee) {
  final direct = employee["name"]?.toString() ??
      employee["employee_name"]?.toString();
  if (direct != null && direct.trim().isNotEmpty) return direct;
  final first = employee["first_name"]?.toString() ?? "";
  final last = employee["last_name"]?.toString() ?? "";
  final full = "$first $last".trim();
  return full.isEmpty ? "Employee" : full;
}

String _employeeRole(Map<String, dynamic> employee) {
  return employee["job_title"]?.toString() ??
      employee["position"]?.toString() ??
      employee["role"]?.toString() ??
      "";
}

String? _employeeApplicantId(Map<String, dynamic> employee) {
  return employee["applicant_id"]?.toString() ??
      employee["application_id"]?.toString();
}

int _maxSelectableForOpening(Map<String, dynamic> opening, String? shiftId) {
  Map? detail;
  final details = opening["shift_details"];
  if (details is Map) {
    detail = details;
  } else if (details is List && shiftId != null && shiftId.isNotEmpty) {
    for (final item in details) {
      if (item is! Map) continue;
      final id = item["shift_id"]?.toString() ??
          item["id"]?.toString() ??
          item["schedule_id"]?.toString();
      if (id == shiftId) {
        detail = item;
        break;
      }
    }
  } else if (details is List && details.isNotEmpty) {
    final first = details.first;
    if (first is Map) detail = first;
  }

  if (detail != null) {
    final openPositions = _asInt(detail["open_positions"]);
    if (openPositions != null) return openPositions;
    final child = _asInt(detail["child_count"]);
    final applicants = _asInt(detail["applicant_count"]);
    if (child != null) {
      final open = child - (applicants ?? 0);
      return open < 0 ? 0 : open;
    }
    final totalOpenings = _asInt(detail["total_openings"]);
    if (totalOpenings != null) return totalOpenings;
    final positions = _asInt(detail["no_of_child_openings"]) ??
        _asInt(detail["required_positions"]);
    if (positions != null) return positions;
    final jobTitles = (detail["job_titles"] as List?) ?? [];
    if (jobTitles.isNotEmpty) return jobTitles.length;
    final shiftPositions = (detail["shift_positions"] as List?) ?? [];
    if (shiftPositions.isNotEmpty) return shiftPositions.length;
    final applicantList = (detail["applicants"] as List?) ?? [];
    if (applicantList.isNotEmpty) {
      final accepted = applicantList.where((a) {
        if (a is! Map) return false;
        final status = a["status"]?.toString().toUpperCase();
        final assigned = a["is_assigned"] == true;
        return status == "ACCEPTED" || assigned;
      }).length;
      final total = _asInt(detail["total_openings"]) ??
          _asInt(detail["child_count"]) ??
          _asInt(detail["no_of_child_openings"]) ??
          1;
      final open = total - accepted;
      return open < 0 ? 0 : open;
    }
  }

  final fallback = _openingOpenCount(opening);
  if (fallback == 0 && detail != null) return 1;
  if (fallback == 0 && details is List && details.isNotEmpty) return 1;
  return fallback;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) return int.tryParse(value);
  return null;
}

List<Map<String, dynamic>> _filterOpeningsByShift(

  List<Map<String, dynamic>> openings,

  String? shiftId,

) {

  if (shiftId == null || shiftId.isEmpty) return openings;

  return openings.where((opening) {

    final layers = (opening["shift_layers"] as List?) ?? [];

    for (final layer in layers) {

      if (layer is! Map) continue;

      final details = (layer["schedule_details"] as List?) ?? [];

      for (final detail in details) {

        if (detail is! Map) continue;

        final id = detail["shift_id"]?.toString() ?? detail["id"]?.toString();

        if (id == shiftId) return true;

      }

    }

    return false;

  }).toList();

}



Future<bool> _confirm(BuildContext context, String message) async {

  final result = await showDialog<bool>(

    context: context,

    builder: (context) => AlertDialog(

      title: const Text("Confirm"),

      content: Text(message),

      actions: [

        TextButton(

          onPressed: () => Navigator.pop(context, false),

          child: const Text("Cancel"),

        ),

        ElevatedButton(

          onPressed: () => Navigator.pop(context, true),

          child: const Text("Confirm"),

        ),

      ],

    ),

  );

  return result ?? false;

}



void _showSnack(BuildContext context, String message) {

  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

}



String _findJobTitleLabel(Map<String, dynamic> opening, String id) {

  final titles = (opening["job_titles"] as List?) ?? [];

  for (final t in titles) {

    if (t is Map && t["id"]?.toString() == id) {

      return t["name"]?.toString() ?? t["abbreviation"]?.toString() ?? id;

    }

  }

  return id;

}

class _FacilityInlineSelector extends StatelessWidget {
  const _FacilityInlineSelector({
    required this.facilities,
    required this.selectedId,
    required this.selectedName,
    required this.onSelect,
  });

  final List<Map<String, dynamic>> facilities;
  final String? selectedId;
  final String? selectedName;
  final void Function(String id, String name) onSelect;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Map<String, dynamic>>(
      tooltip: "Select Facility",
      onSelected: (value) {
        final id = value["id"]?.toString() ?? "";
        final name = value["name"]?.toString() ?? "";
        if (id.isNotEmpty) onSelect(id, name);
      },
      itemBuilder: (context) => facilities
          .map(
            (f) => PopupMenuItem<Map<String, dynamic>>(
              value: f,
              child: Text(f["name"]?.toString() ?? ""),
            ),
          )
          .toList(),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.lightGray),
        ),
        child: Row(
          children: [
            Text(
              selectedName ?? "Facility",
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 18),
          ],
        ),
      ),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.stats});

  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final items = [
      {"label": "Actual HPPD", "value": stats["actual_hppd"] ?? 0},
      {"label": "Scheduled HPPD", "value": stats["schedule_hppd"] ?? 0},
      {"label": "Target HPPD", "value": stats["target_hppd"] ?? 0},
      {"label": "Census", "value": stats["census"] ?? 0},
      {"label": "Clocked In", "value": stats["clocked_in"] ?? 0},
      {"label": "Actual Hours", "value": stats["actual_hours"] ?? 0},
      {"label": "Scheduled Hours", "value": stats["schedule_hours"] ?? 0},
      {"label": "Open Positions", "value": stats["open_positions"] ?? 0},
    ];
    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            width: 140,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.lightGray),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item["label"].toString(),
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.greyBlue),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  "${item["value"]}",
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DepartmentOnlyList extends StatelessWidget {
  const _DepartmentOnlyList({
    required this.openings,
    required this.departments,
    required this.loading,
    required this.selectedDepartmentId,
    required this.onSelect,
  });

  final List<Map<String, dynamic>> openings;
  final List<Map<String, dynamic>> departments;
  final bool loading;
  final String? selectedDepartmentId;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final derived = openings.isNotEmpty
        ? _deriveDepartments(openings)
        : [
            {"id": null, "name": "All Departments", "count": 0},
            ...departments.map((d) => {
                  "id": d["id"]?.toString(),
                  "name": d["name"]?.toString() ?? "",
                  "count": 0,
                })
          ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: "Departments"),
          const SizedBox(height: 10),
          if (loading)
            const LinearProgressIndicator(minHeight: 2)
          else
            ...derived.map((dept) {
              final id = dept["id"]?.toString();
              final name = dept["name"]?.toString() ?? "";
              final count = dept["count"]?.toString() ?? "0";
              final selected =
                  (id == selectedDepartmentId) ||
                  (id == null && selectedDepartmentId == null);
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
                        color:
                            selected ? AppColors.primary : AppColors.lightGray,
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

class ShiftListScreen extends ConsumerStatefulWidget {
  const ShiftListScreen({
    super.key,
    required this.departmentId,
    required this.date,
  });

  final String? departmentId;
  final DateTime date;

  @override
  ConsumerState<ShiftListScreen> createState() => _ShiftListScreenState();
}

class _ShiftListScreenState extends ConsumerState<ShiftListScreen> {
  String query = "";
  String filterMode = "all"; // all | open | filled

  Future<void> _openAddShiftForm(
    BuildContext context, {
    required DailyScheduleController controller,
    required DailyScheduleState state,
  }) async {
    await _openOpeningEditor(
      context,
      controller: controller,
      state: state,
      initial: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dailyScheduleControllerProvider);
    final controller = ref.read(dailyScheduleControllerProvider.notifier);
    final openings = _filterOpeningsByDepartment(
      state.openings,
      widget.departmentId,
    );
    var filtered = openings.where((opening) {
      final name = opening["name"]?.toString().toLowerCase() ?? "";
      return name.contains(query.toLowerCase());
    }).toList();
    if (filterMode != "all") {
      filtered = filtered.where((opening) {
        final assigned = _assignedEmployeesForOpening(
          opening,
          state.selectedScheduleShiftId,
        );
        final counts = _shiftCountsForOpening(opening);
        final isFilled = counts.total > 0 && counts.filled >= counts.total;
        return filterMode == "filled" ? isFilled : !isFilled;
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Shifts"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: "Search shifts",
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() => query = value),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list, color: AppColors.greyBlue),
                onSelected: (value) => setState(() => filterMode = value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: "open",
                    child: Text("Open"),
                  ),
                  const PopupMenuItem(
                    value: "filled",
                    child: Text("Filled"),
                  ),
                  const PopupMenuItem(
                    value: "all",
                    child: Text("Reset"),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionHeader(title: "Shifts"),
          const SizedBox(height: 10),
          if (state.openingsLoading)
            const LinearProgressIndicator(minHeight: 2)
          else if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text("No shifts found"),
            )
          else
            ...filtered.map((opening) {
              final id = _openingId(opening);
              final name = _openingTitle(opening);
              final time = _openingTime(opening);
              final unit = _unitLabel(opening);
              final openCount = _openingOpenCount(opening);
              final counts = _shiftCountsForOpening(opening);
              final filledText = "${counts.filled}/${counts.total} filled";
              final percent = counts.total > 0
                  ? (counts.filled / counts.total).clamp(0.0, 1.0).toDouble()
                  : 0.0;
              return InkWell(
                onTap: () {
                  controller.selectOpening(opening);
                  Navigator.push(
                    context,
                    _slideRoute(
                      OpeningDetailScreen(openingId: id),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                          _Pill(text: "SB", filled: false),
                          const SizedBox(width: 8),
                          if (counts.total > 0 &&
                              counts.filled >= counts.total)
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: AppColors.green,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            )
                          else
                            _Pill(text: "$openCount open", filled: true),
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
                        unit,
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
            }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddShiftForm(
          context,
          controller: controller,
          state: state,
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class OpeningDetailScreen extends ConsumerWidget {
  const OpeningDetailScreen({super.key, required this.openingId});

  final String openingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dailyScheduleControllerProvider);
    final controller = ref.read(dailyScheduleControllerProvider.notifier);
    final opening = state.selectedOpening;

    return WillPopScope(
      onWillPop: () async {
        await controller.fetchOpenings();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Openings"),
        ),
        body: opening == null
            ? const Center(child: Text("Select a shift"))
            : Column(
                children: [
                  Expanded(
                    child: _OpeningsList(
                      opening: opening,
                      openingId: openingId,
                      onEdit: () => _openOpeningEditor(
                        context,
                        controller: controller,
                        state: state,
                        initial: opening,
                      ),
                      onDelete: () async {
                        final ok =
                            await _confirm(context, "Delete this opening?");
                        if (!ok) return;
                        final success = await controller.deleteOpening(openingId);
                        if (context.mounted) {
                          _showSnack(
                            context,
                            success ? "Opening deleted" : "Delete failed",
                          );
                          if (success) Navigator.pop(context);
                        }
                      },
                      onOpen: (detail) {
                        controller.selectOpeningDetail(detail);
                        Navigator.push(
                          context,
                          _slideRoute(
                            PositionDetailScreen(openingId: openingId),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
        floatingActionButton: opening == null
            ? null
            : FloatingActionButton(
                onPressed: () => _openOpeningEditor(
                  context,
                  controller: controller,
                  state: state,
                  initial: null,
                ),
                child: const Icon(Icons.add),
              ),
      ),
    );
  }
}

class _OpeningsList extends StatelessWidget {
  const _OpeningsList({
    required this.opening,
    required this.openingId,
    required this.onEdit,
    required this.onDelete,
    required this.onOpen,
  });

  final Map<String, dynamic> opening;
  final String openingId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(Map<String, dynamic> detail) onOpen;

  @override
  Widget build(BuildContext context) {
    final details = opening["shift_details"];
    final items = <Map<String, dynamic>>[];
    if (details is Map) {
      items.add(Map<String, dynamic>.from(details));
    } else if (details is List) {
      for (final d in details) {
        if (d is Map) items.add(Map<String, dynamic>.from(d));
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        _OpeningSummary(opening: opening),
        const SizedBox(height: 12),
        _SectionHeader(title: "Positions"),
        const SizedBox(height: 8),
        if (items.isEmpty)
          const Text("No openings found")
        else
          ...items.map((detail) {
            final time = _timeRange(
              detail["start_time"]?.toString(),
              detail["end_time"]?.toString(),
            );
            final unit = _unitLabel(opening);
            final counts = _positionCountsForDetail(
              detail,
              useJobTitleFallback: false,
              forceSingle: true,
            );
            final filledText = "${counts.filled}/${counts.total} filled";
            final percent = counts.total > 0
                ? (counts.filled / counts.total).clamp(0.0, 1.0).toDouble()
                : 0.0;
            final assigned = _assignedEmployeesForDetail(detail);
            final assignedNames =
                assigned.map(_employeeName).where((e) => e.isNotEmpty).toList();
            return Dismissible(
              key: ValueKey("${openingId}_${detail["id"] ?? detail.hashCode}"),
              direction: DismissDirection.startToEnd,
              confirmDismiss: (_) async {
                return _confirm(context, "Delete this opening?");
              },
              onDismissed: (_) => onDelete(),
              background: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: AppColors.red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete, color: AppColors.red),
              ),
              child: InkWell(
                onTap: () => onOpen(detail),
                onLongPress: onEdit,
                borderRadius: BorderRadius.circular(10),
                child: Container(
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
                          _Pill(text: "SB", filled: false),
                          const SizedBox(width: 6),
                          if (counts.filled == counts.total && counts.total > 0)
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: AppColors.green,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        time,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.greyBlue),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        filledText,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.greyBlue),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: percent,
                          minHeight: 6,
                          backgroundColor: AppColors.lightPink.withOpacity(0.4),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                      if (assignedNames.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: assignedNames
                              .map((name) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.lightPink,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    child: Text(
                                      name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _OpeningSummary extends StatelessWidget {
  const _OpeningSummary({required this.opening});
  final Map<String, dynamic> opening;

  @override
  Widget build(BuildContext context) {
    final title = _openingTitle(opening);
    final time = _openingTime(opening);
    final dateLabel = _openingDateLabel(opening);
    final openCount = _openingOpenCount(opening);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.greyBlue,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.greyBlue),
                ),
                if (dateLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    dateLabel,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.greyBlue),
                  ),
                ],
              ],
            ),
          ),
          _Pill(text: "$openCount opening", filled: true),
        ],
      ),
    );
  }
}

class PositionDetailScreen extends ConsumerWidget {
  const PositionDetailScreen({super.key, required this.openingId});

  final String openingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dailyScheduleControllerProvider);
    final controller = ref.read(dailyScheduleControllerProvider.notifier);
    final opening = state.selectedOpeningDetail ?? state.selectedOpening;
    final countsSource = state.selectedOpening ?? opening;

    return WillPopScope(
      onWillPop: () async {
        await controller.fetchOpenings();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text("Fill Position")),
        body: opening == null
            ? const Center(child: Text("Select a shift"))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _PositionDetail(
                    opening: opening,
                    countsSource: countsSource,
                    controller: controller,
                    selectedLayerId: state.selectedLayerId,
                    selectedShiftId: state.selectedScheduleShiftId,
                    applicants: state.applicants,
                    employees: state.employees,
                    applicantsLoading: state.applicantsLoading,
                    employeesLoading: state.employeesLoading,
                    selectedEmployees: state.selectedEmployees,
                    employeeSearch: state.employeeSearch,
                    applicantSearch: state.applicantSearch,
                    employeeSelection: state.employeeSelection,
                    onSelectLayer: controller.selectLayer,
                    onSelectShift: controller.selectScheduleShift,
                    onApplicantSearch: controller.setApplicantSearch,
                    onEmployeeSearch: controller.setEmployeeSearch,
                    onSelectionFilter: controller.setEmployeeSelection,
                    onClearSelected: controller.clearSelectedEmployees,
                    onAssign: (context) => _handleAssign(
                      context,
                      controller: controller,
                      opening: opening,
                      selectedEmployees: state.selectedEmployees,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ActionFab extends StatelessWidget {
  const _ActionFab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onTap,
      backgroundColor: AppColors.primary,
      child: const Icon(Icons.menu),
    );
  }
}

void _openActionMenu(
  BuildContext context, {
  required VoidCallback onBroadcast,
  required VoidCallback onScorecard,
  required VoidCallback onLogs,
  required VoidCallback onOffSchedule,
  required VoidCallback onPeopleWorking,
  required VoidCallback onAssignRotation,
  required VoidCallback onRotations,
  required VoidCallback onReports,
  required VoidCallback onReset,
}) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return SafeArea(
        child: SizedBox(
          height: 420,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ActionItem(label: "Broadcast", onTap: () {
                Navigator.pop(context);
                onBroadcast();
              }),
              _ActionItem(label: "Scorecard", onTap: () {
                Navigator.pop(context);
                onScorecard();
              }),
              _ActionItem(label: "Logs", onTap: () {
                Navigator.pop(context);
                onLogs();
              }),
              _ActionItem(label: "Off Schedule", onTap: () {
                Navigator.pop(context);
                onOffSchedule();
              }),
              _ActionItem(label: "People Working", onTap: () {
                Navigator.pop(context);
                onPeopleWorking();
              }),
              _ActionItem(label: "Assign Rotation", onTap: () {
                Navigator.pop(context);
                onAssignRotation();
              }),
              _ActionItem(label: "Rotations", onTap: () {
                Navigator.pop(context);
                onRotations();
              }),
              _ActionItem(label: "Reports", onTap: () {
                Navigator.pop(context);
                onReports();
              }),
              _ActionItem(label: "Reset", onTap: () async {
                Navigator.pop(context);
                onReset();
              }),
            ],
          ),
        ),
      );
    },
  );
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

PageRouteBuilder _slideRoute(Widget child) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final offset = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(animation);
      return SlideTransition(position: offset, child: child);
    },
  );
}

String _formatHeaderDate(DateTime date) {
  return "${_monthName(date.month)} ${date.day}, ${date.year}";
}

String _monthName(int month) {
  const months = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
  ];
  return months[(month - 1).clamp(0, 11)];
}
void _openBroadcast(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const DailyActionListScreen(
        title: "Broadcasts",
        endpoint: Endpoints.dailyScheduleBroadcast,
      ),
    ),
  );
}

void _openLogs(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const DailyActionListScreen(
        title: "Logs",
        endpoint: Endpoints.dailyScheduleLogs,
      ),
    ),
  );
}

void _openOffSchedule(BuildContext context, DateTime date) {
  final dateStr = _formatDate(date);
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => DailyActionListScreen(
        title: "Off Schedule",
        endpoint: Endpoints.dailyScheduleOffSchedule(dateStr),
      ),
    ),
  );
}

void _openPeopleWorking(BuildContext context, DateTime date) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => DailyPeopleWorkingScreen(date: date),
    ),
  );
}

void _openScorecard(
  BuildContext context,
  DateTime date,
  List<Map<String, dynamic>> departments,
) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => DailyScorecardScreen(
        date: date,
        departments: departments,
      ),
    ),
  );
}


