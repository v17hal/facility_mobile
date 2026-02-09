import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:file_picker/file_picker.dart";
import "package:dio/dio.dart";

import "../../core/theme/app_colors.dart";
import "../../core/network/api_provider.dart";
import "../../core/network/api_service.dart";
import "../../core/network/endpoints.dart";
import "employees_controller.dart";
import "employee_form_screen.dart";
import "employee_detail_screen.dart";
import "employee_detail_controller.dart";

class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});

  @override
  ConsumerState<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends ConsumerState<EmployeesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final TextEditingController _search;
  late final ScrollController _scroll;

  final _tabItems = const [
    _TabItem(label: "Active", tab: EmployeesTab.active),
    _TabItem(label: "Blocked", tab: EmployeesTab.blocked),
    _TabItem(label: "Terminated", tab: EmployeesTab.terminated),
    _TabItem(label: "Walk-in", tab: EmployeesTab.walkIn),
    _TabItem(label: "Supervisors", tab: EmployeesTab.supervisors),
    _TabItem(label: "Schedulers", tab: EmployeesTab.schedulers),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _tabItems.length, vsync: this);
    _search = TextEditingController();
    _scroll = ScrollController();
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) {
        ref.read(employeesControllerProvider.notifier).setTab(
              _tabItems[_tabs.index].tab,
            );
      }
    });
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 240) {
        final activeTab = ref.read(employeesControllerProvider).activeTab;
        if (activeTab != EmployeesTab.supervisors &&
            activeTab != EmployeesTab.schedulers) {
          ref.read(employeesControllerProvider.notifier).fetchEmployees();
        }
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(employeesControllerProvider);
    final controller = ref.read(employeesControllerProvider.notifier);

    if (_tabItems[_tabs.index].tab != state.activeTab) {
      final newIndex = _tabItems.indexWhere((t) => t.tab == state.activeTab);
      if (newIndex != -1) {
        _tabs.animateTo(newIndex);
      }
    }
    if (_search.text != state.search) {
      _search.text = state.search;
      _search.selection = TextSelection.fromPosition(
        TextPosition(offset: _search.text.length),
      );
    }

    final filterCount = state.selectedDepartments.length +
        state.selectedJobTitles.length +
        (state.credentialStatus != "CREDENTIAL_ALL" ? 1 : 0) +
        (state.ordering.isNotEmpty ? 1 : 0);

    final isSecondary = state.activeTab == EmployeesTab.supervisors ||
        state.activeTab == EmployeesTab.schedulers;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Employees"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _FacilitySelector(
              name: state.selectedFacilityName ?? "Select Facility",
              facilities: state.facilities,
              onSelect: controller.selectFacility,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              if (state.activeTab == EmployeesTab.walkIn) {
                _openWalkInForm(context, ref, state, controller);
                return;
              }
              final created = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const EmployeeFormScreen(),
                ),
              );
              if (created == true) {
                controller.fetchEmployees(reset: true);
              }
            },
          ),
          if (!isSecondary)
            IconButton(
              icon: const Icon(Icons.filter_alt_outlined),
              onPressed: () => _openFilterSheet(context, state, controller),
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == "bulk_invite") {
                _openBulkInviteSheet(context, ref);
              }
              if (value == "manual_invite") {
                _openManualInviteSheet(context, ref);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: "bulk_invite",
                child: Text("Bulk Invite"),
              ),
              const PopupMenuItem(
                value: "manual_invite",
                child: Text("Manual Invite"),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (isSecondary) {
                controller.fetchSecondary();
              } else {
                controller.fetchEmployees(reset: true);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.white,
            child: TabBar(
              controller: _tabs,
              isScrollable: true,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.greyBlue,
              indicatorColor: AppColors.primary,
              tabs: _tabItems.map((t) => Tab(text: t.label)).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: controller.updateSearch,
                    decoration: InputDecoration(
                      hintText: "Search employees",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: state.search.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _search.clear();
                                controller.updateSearch("");
                              },
                            ),
                      filled: true,
                      fillColor: AppColors.offwhite,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                if (!isSecondary) ...[
                  const SizedBox(width: 8),
                  _FilterBadge(
                    count: filterCount,
                    onTap: () => _openFilterSheet(context, state, controller),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _SectionHeader(
              title: _tabItems[_tabs.index].label,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: _tabItems.map((tab) {
                if (tab.tab == EmployeesTab.supervisors ||
                    tab.tab == EmployeesTab.schedulers) {
                  return _SchedulerList(
                    loading: state.secondaryLoading,
                    data: tab.tab == EmployeesTab.supervisors
                        ? state.supervisors
                        : state.schedulers,
                  );
                }
                return _EmployeesList(
                  controller: _scroll,
                  loading: state.loading,
                  loadingMore: state.loadingMore,
                  data: state.employees,
                  onResend: controller.resendInvite,
                  onCancel: controller.cancelInvite,
                  onWageHistory: (employee) async {
                    final id = _employeeIdForActions(employee);
                    if (id.isEmpty) return;
                    await ref
                        .read(employeeDetailControllerProvider(id).notifier)
                        .fetchWageHistory();
                    if (!context.mounted) return;
                    final name =
                        "${employee["first_name"] ?? ""} ${employee["last_name"] ?? ""}"
                            .trim();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      builder: (_) => WageHistorySheet(
                        employeeName: name.isEmpty ? "Employee" : name,
                        employeeId: id,
                      ),
                    );
                  },
                  onAssignWalkIn: (employee) =>
                      _openWalkInAssignSheet(context, ref, employee),
                  onViewWalkInShifts: (employee) =>
                      _openWalkInShiftHistory(context, ref, employee),
                  isWalkIn: tab.tab == EmployeesTab.walkIn,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _openWalkInForm(
  BuildContext context,
  WidgetRef ref,
  EmployeesState state,
  EmployeesController controller,
) async {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _WalkInFormSheet(
      jobTitles: state.jobTitles,
      onSaved: () => controller.fetchEmployees(reset: true),
    ),
  );
}

class _WalkInFormSheet extends ConsumerStatefulWidget {
  const _WalkInFormSheet({
    required this.jobTitles,
    required this.onSaved,
  });

  final List<Map<String, dynamic>> jobTitles;
  final VoidCallback onSaved;

  @override
  ConsumerState<_WalkInFormSheet> createState() => _WalkInFormSheetState();
}

class _WalkInFormSheetState extends ConsumerState<_WalkInFormSheet> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  String? gender;
  String? jobTitle;
  bool saving = false;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  "Add Walk-in Nurse",
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
            TextField(
              controller: _first,
              decoration: const InputDecoration(
                labelText: "First name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _last,
              decoration: const InputDecoration(
                labelText: "Last name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Phone",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: gender,
              items: const [
                DropdownMenuItem(value: "Male", child: Text("Male")),
                DropdownMenuItem(value: "Female", child: Text("Female")),
                DropdownMenuItem(value: "Other", child: Text("Other")),
              ],
              onChanged: (value) => setState(() => gender = value),
              decoration: const InputDecoration(
                labelText: "Gender",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: jobTitle,
              items: widget.jobTitles
                  .map(
                    (e) => DropdownMenuItem(
                      value: e["name"]?.toString() ?? "",
                      child: Text(e["name"]?.toString() ?? ""),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => jobTitle = value),
              decoration: const InputDecoration(
                labelText: "Job Title",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: saving ? null : () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            setState(() => saving = true);
                            final api = ApiService(ref.read(apiClientProvider));
                            final payload = FormData.fromMap({
                              "first_name": _first.text.trim(),
                              "last_name": _last.text.trim(),
                              "gender": gender ?? "",
                              "mobile": _phone.text.replaceAll(RegExp(r"\\D"), ""),
                              "email": _email.text.trim(),
                              "country_code": "+1",
                              "job_title": jobTitle ?? "",
                            });
                            try {
                              await api.post(Endpoints.walkInEmployees, data: payload);
                              widget.onSaved();
                              if (context.mounted) Navigator.pop(context);
                            } catch (_) {
                              // no-op; UI can surface in future
                            } finally {
                              if (mounted) setState(() => saving = false);
                            }
                          },
                    child: const Text("Save"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openBulkInviteSheet(BuildContext context, WidgetRef ref) async {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const _BulkInviteSheet(),
  );
}

Future<void> _openManualInviteSheet(BuildContext context, WidgetRef ref) async {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const _ManualInviteSheet(),
  );
}

class _BulkInviteSheet extends ConsumerStatefulWidget {
  const _BulkInviteSheet();

  @override
  ConsumerState<_BulkInviteSheet> createState() => _BulkInviteSheetState();
}

class _BulkInviteSheetState extends ConsumerState<_BulkInviteSheet> {
  String? filePath;
  bool validating = false;
  bool inviting = false;
  String? validationMessage;

  @override
  Widget build(BuildContext context) {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  "Bulk Invite",
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
            OutlinedButton.icon(
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ["csv"],
                );
                if (result != null && result.files.single.path != null) {
                  setState(() => filePath = result.files.single.path);
                }
              },
              icon: const Icon(Icons.upload_file),
              label: Text(filePath == null ? "Choose CSV" : "Change CSV"),
            ),
            if (filePath != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  filePath!.split("\\").last,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (validationMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                validationMessage!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.greyBlue),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: validating || filePath == null
                        ? null
                        : () async {
                            setState(() {
                              validating = true;
                              validationMessage = null;
                            });
                            try {
                              final api =
                                  ApiService(ref.read(apiClientProvider));
                              final form = FormData.fromMap({
                                "file": await MultipartFile.fromFile(filePath!),
                              });
                              await api.post(
                                Endpoints.employeesBulkValidate,
                                data: form,
                              );
                              setState(() {
                                validationMessage = "File validated.";
                              });
                            } catch (_) {
                              setState(() {
                                validationMessage = "Validation failed.";
                              });
                            } finally {
                              if (mounted) setState(() => validating = false);
                            }
                          },
                    child: Text(validating ? "Validating..." : "Validate"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: inviting || filePath == null
                        ? null
                        : () async {
                            setState(() => inviting = true);
                            try {
                              final api =
                                  ApiService(ref.read(apiClientProvider));
                              final form = FormData.fromMap({
                                "file": await MultipartFile.fromFile(filePath!),
                              });
                              await api.post(
                                Endpoints.employeesBulkInvite,
                                data: form,
                              );
                              if (context.mounted) Navigator.pop(context);
                            } catch (_) {
                              // no-op
                            } finally {
                              if (mounted) setState(() => inviting = false);
                            }
                          },
                    child: Text(inviting ? "Inviting..." : "Invite"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualInviteSheet extends ConsumerStatefulWidget {
  const _ManualInviteSheet();

  @override
  ConsumerState<_ManualInviteSheet> createState() => _ManualInviteSheetState();
}

class _ManualInviteSheetState extends ConsumerState<_ManualInviteSheet> {
  final _items = <_ManualInviteRow>[
    _ManualInviteRow(),
  ];
  bool sending = false;

  void _addRow() {
    setState(() => _items.add(_ManualInviteRow()));
  }

  void _removeRow(int index) {
    setState(() => _items.removeAt(index));
  }

  Future<void> _submit() async {
    setState(() => sending = true);
    try {
      final payload = {
        "employees": _items
            .map((row) => row.toPayload())
            .where((row) =>
                (row["email"]?.toString().isNotEmpty ?? false) ||
                (row["mobile"]?.toString().isNotEmpty ?? false))
            .toList(),
      };
      if ((payload["employees"] as List).isEmpty) {
        if (mounted) Navigator.pop(context);
        return;
      }
      final api = ApiService(ref.read(apiClientProvider));
      await api.post(
        Endpoints.employeesBulkInviteManual,
        data: payload,
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  void dispose() {
    for (final row in _items) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  "Manual Invite",
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
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.lightGray),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                "Invite ${index + 1}",
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const Spacer(),
                              if (_items.length > 1)
                                IconButton(
                                  onPressed: () => _removeRow(index),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: item.firstName,
                            decoration: const InputDecoration(
                              labelText: "First name",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: item.lastName,
                            decoration: const InputDecoration(
                              labelText: "Last name",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: item.email,
                            decoration: const InputDecoration(
                              labelText: "Email",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: item.mobile,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: "Phone",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: item.countryCode,
                            decoration: const InputDecoration(
                              labelText: "Country code",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: item.jobTitle,
                            decoration: const InputDecoration(
                              labelText: "Job title",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _addRow,
                    icon: const Icon(Icons.add),
                    label: const Text("Add another"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: sending ? null : () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: sending ? null : _submit,
                    child: const Text("Send Invites"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualInviteRow {
  _ManualInviteRow()
      : firstName = TextEditingController(),
        lastName = TextEditingController(),
        email = TextEditingController(),
        mobile = TextEditingController(),
        countryCode = TextEditingController(text: "+1"),
        jobTitle = TextEditingController();

  final TextEditingController firstName;
  final TextEditingController lastName;
  final TextEditingController email;
  final TextEditingController mobile;
  final TextEditingController countryCode;
  final TextEditingController jobTitle;

  Map<String, dynamic> toPayload() {
    return {
      "first_name": firstName.text.trim(),
      "last_name": lastName.text.trim(),
      "email": email.text.trim(),
      "mobile": mobile.text.trim(),
      "country_code": countryCode.text.trim(),
      "job_title": jobTitle.text.trim(),
    };
  }

  void dispose() {
    firstName.dispose();
    lastName.dispose();
    email.dispose();
    mobile.dispose();
    countryCode.dispose();
    jobTitle.dispose();
  }
}

class _TabItem {
  const _TabItem({required this.label, required this.tab});
  final String label;
  final EmployeesTab tab;
}

class _EmployeesList extends StatelessWidget {
  const _EmployeesList({
    required this.controller,
    required this.loading,
    required this.loadingMore,
    required this.data,
    required this.onResend,
    required this.onCancel,
    required this.onWageHistory,
    required this.onAssignWalkIn,
    required this.onViewWalkInShifts,
    required this.isWalkIn,
  });

  final ScrollController controller;
  final bool loading;
  final bool loadingMore;
  final List<Map<String, dynamic>> data;
  final ValueChanged<String> onResend;
  final ValueChanged<String> onCancel;
  final ValueChanged<Map<String, dynamic>> onWageHistory;
  final ValueChanged<Map<String, dynamic>> onAssignWalkIn;
  final ValueChanged<Map<String, dynamic>> onViewWalkInShifts;
  final bool isWalkIn;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (data.isEmpty) {
      return const Center(child: Text("No employees found"));
    }
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      itemCount: data.length + (loadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= data.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final employee = data[index];
        return _EmployeeCard(
          employee: employee,
          onResend: onResend,
          onCancel: onCancel,
          onWageHistory: onWageHistory,
          onAssignWalkIn: isWalkIn ? () => onAssignWalkIn(employee) : null,
          onViewWalkInShifts: isWalkIn ? () => onViewWalkInShifts(employee) : null,
          onTap: () {
            final id = employee["id"]?.toString() ?? "";
            if (id.isEmpty) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EmployeeDetailScreen(employeeId: id),
              ),
            );
          },
        );
      },
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  const _EmployeeCard({
    required this.employee,
    required this.onResend,
    required this.onCancel,
    required this.onWageHistory,
    required this.onTap,
    this.onAssignWalkIn,
    this.onViewWalkInShifts,
  });

  final Map<String, dynamic> employee;
  final ValueChanged<String> onResend;
  final ValueChanged<String> onCancel;
  final ValueChanged<Map<String, dynamic>> onWageHistory;
  final VoidCallback onTap;
  final VoidCallback? onAssignWalkIn;
  final VoidCallback? onViewWalkInShifts;

  @override
  Widget build(BuildContext context) {
    final id = employee["id"]?.toString() ?? "";
    final first = employee["first_name"]?.toString() ?? "";
    final last = employee["last_name"]?.toString() ?? "";
    final name = "$first $last".trim();
    final jobTitle = (employee["job_title"]?["name"] ??
            employee["job_title"]?["title"] ??
            "N/A")
        .toString();
    final status = employee["status"]?.toString() ?? "";
    final credential = employee["credential_status"]?.toString() ?? "";
    final phone = _formatPhone(
      "${employee["country_code"] ?? ""}",
      "${employee["mobile"] ?? ""}",
    );
    final photo = employee["profile_photo"]?.toString();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.lightGray),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.offwhite,
                  backgroundImage: photo == null || photo.isEmpty
                      ? null
                      : NetworkImage(photo),
                  child: photo == null || photo.isEmpty
                      ? Text(
                          name.isNotEmpty ? name[0] : "?",
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
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
                        jobTitle,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.greyBlue),
                      ),
                    ],
                  ),
                ),
                if (status.isNotEmpty)
                  _StatusBadge(
                    label: status == "INVITED" ? "Invited" : status,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: AppColors.greyBlue),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    phone,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (credential.isNotEmpty)
                  _CredentialBadge(status: credential),
              ],
            ),
            if (status == "INVITED") ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => onCancel(id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.greyBlue,
                        side: const BorderSide(color: AppColors.lightGray),
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => onResend(id),
                      child: const Text("Resend"),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => onWageHistory(employee),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.greyBlue,
                        side: const BorderSide(color: AppColors.lightGray),
                      ),
                      child: const Text("Wage History"),
                    ),
                  ),
                ],
              ),
              if (onAssignWalkIn != null || onViewWalkInShifts != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (onAssignWalkIn != null)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onAssignWalkIn,
                          child: const Text("Assign"),
                        ),
                      ),
                    if (onAssignWalkIn != null && onViewWalkInShifts != null)
                      const SizedBox(width: 8),
                    if (onViewWalkInShifts != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onViewWalkInShifts,
                          child: const Text("Shifts"),
                        ),
                      ),
                  ],
                ),
              ],
            ],
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

class _SchedulerList extends StatelessWidget {
  const _SchedulerList({
    required this.loading,
    required this.data,
  });

  final bool loading;
  final List<Map<String, dynamic>> data;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (data.isEmpty) {
      return const Center(child: Text("No data"));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: data.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = data[index];
        final name = item["full_name"]?.toString() ?? "N/A";
        final email = item["email"]?.toString() ?? "N/A";
        final phone = _formatPhone(
          "${item["country_code"] ?? ""}",
          "${item["mobile"] ?? ""}",
        );
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lightGray),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(email, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(phone, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        );
      },
    );
  }
}

Future<void> _openWalkInAssignSheet(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> employee,
) async {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _WalkInAssignSheet(employee: employee),
  );
}

class _WalkInAssignSheet extends ConsumerStatefulWidget {
  const _WalkInAssignSheet({required this.employee});
  final Map<String, dynamic> employee;

  @override
  ConsumerState<_WalkInAssignSheet> createState() => _WalkInAssignSheetState();
}

class _WalkInAssignSheetState extends ConsumerState<_WalkInAssignSheet> {
  bool loading = true;
  List<Map<String, dynamic>> openings = [];
  Map<String, dynamic>? selected;
  bool assigning = false;

  @override
  void initState() {
    super.initState();
    _loadOpenings();
  }

  Future<void> _loadOpenings() async {
    try {
      final api = ApiService(ref.read(apiClientProvider));
      final date = DateTime.now();
      final dateStr =
          "${date.year}-${date.month.toString().padLeft(2, "0")}-${date.day.toString().padLeft(2, "0")}";
      final resp = await api.get(
        Endpoints.dailyScheduleOpenings,
        params: {"date": dateStr},
      );
      final list = _extractList(resp.data);
      openings = list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (openings.isNotEmpty) {
        selected = openings.first;
      }
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final employee = widget.employee;
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  "Assign Walk-in",
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
            if (loading)
              const LinearProgressIndicator(minHeight: 2)
            else if (openings.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text("No openings available today."),
              )
            else
              DropdownButtonFormField<Map<String, dynamic>>(
                value: selected,
                items: openings.map((o) {
                  final shiftName =
                      o["shift_name"]?.toString() ??
                      o["name"]?.toString() ??
                      "Shift";
                  final start =
                      o["shift_details"]?["start_time"]?.toString() ??
                      o["start_time"]?.toString() ??
                      "";
                  final end =
                      o["shift_details"]?["end_time"]?.toString() ??
                      o["end_time"]?.toString() ??
                      "";
                  return DropdownMenuItem(
                    value: o,
                    child: Text("$shiftName ($start-$end)"),
                  );
                }).toList(),
                onChanged: (value) => setState(() => selected = value),
                decoration: const InputDecoration(
                  labelText: "Select Opening",
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: assigning ? null : () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: assigning || selected == null
                        ? null
                        : () async {
                            setState(() => assigning = true);
                            final api = ApiService(ref.read(apiClientProvider));
                            final opening = selected!;
                            final openingId = opening["opening_daily_id"] ??
                                opening["daily_opening_id"] ??
                                opening["id"];
                            final layerId = (opening["shift_layers"] is List &&
                                    (opening["shift_layers"] as List).isNotEmpty)
                                ? (opening["shift_layers"] as List)
                                    .first["daily_opening_layer_id"]
                                : null;
                            final shiftId = opening["schedule_shift_id"] ??
                                opening["shift_details"]?["id"] ??
                                opening["shift_id"];
                            final jobTitleId =
                                employee["job_title_id"]?.toString() ??
                                    employee["job_title"]?["id"]?.toString();
                            final packet = {
                              "job_title":
                                  jobTitleId ?? employee["job_title"]?["name"],
                              "opening_daily_id": openingId,
                              "opening_daily_layer_id": layerId,
                              "previous_nurses": [
                                {
                                  "nurse_id": employee["nurse_id"] ??
                                      employee["id"],
                                  "id": employee["id"],
                                  "job_title_id": jobTitleId,
                                }
                              ],
                              "added_nurses": [],
                            };
                            try {
                              await api.post(
                                Endpoints.walkInAssign(shiftId.toString()),
                                data: packet,
                              );
                              if (context.mounted) Navigator.pop(context);
                            } catch (_) {
                              // no-op
                            } finally {
                              if (mounted) setState(() => assigning = false);
                            }
                          },
                    child: const Text("Assign"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openWalkInShiftHistory(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> employee,
) async {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _WalkInShiftHistorySheet(employee: employee),
  );
}

class _WalkInShiftHistorySheet extends ConsumerStatefulWidget {
  const _WalkInShiftHistorySheet({required this.employee});
  final Map<String, dynamic> employee;

  @override
  ConsumerState<_WalkInShiftHistorySheet> createState() =>
      _WalkInShiftHistorySheetState();
}

class _WalkInShiftHistorySheetState
    extends ConsumerState<_WalkInShiftHistorySheet> {
  bool loading = true;
  List<Map<String, dynamic>> shifts = [];
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _loadShifts();
  }

  Future<void> _loadShifts() async {
    try {
      final api = ApiService(ref.read(apiClientProvider));
      final id = widget.employee["id"]?.toString() ?? "";
      if (id.isEmpty) return;
      final resp = await api.get(
        Endpoints.walkInWorkHistory(id),
        params: {"page": 1, "page_size": 20},
      );
      final list = _extractList(resp.data);
      shifts = list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  "Walk-in Shifts",
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
            if (loading)
              const LinearProgressIndicator(minHeight: 2)
            else if (shifts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text("No shift history found."),
              )
            else
              SizedBox(
                height: 360,
                child: ListView.builder(
                  itemCount: shifts.length,
                  itemBuilder: (context, index) {
                    final item = shifts[index];
                    final shiftInfo = item["shift_info"] ?? {};
                    final title =
                        shiftInfo["title"]?.toString() ??
                        item["shift_name"]?.toString() ??
                        "Shift";
                    final startDate = shiftInfo["start_date"]?.toString() ?? "";
                    final startTime = shiftInfo["start_time"]?.toString() ?? "";
                    final endTime = shiftInfo["end_time"]?.toString() ?? "";
                    final clockIn = item["clock_in"]?.toString();
                    final clockOut = item["clock_out"]?.toString();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.lightGray),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$title",
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "$startDate $startTime - $endTime",
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.greyBlue),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  clockIn ?? "Clock in: N/A",
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                              if (clockIn == null)
                                TextButton(
                                  onPressed: saving
                                      ? null
                                      : () async {
                                          final picked = await showTimePicker(
                                            context: context,
                                            initialTime: TimeOfDay.now(),
                                          );
                                          if (picked == null) return;
                                          final dt = DateTime.now();
                                          final value =
                                              "${dt.year}-${dt.month.toString().padLeft(2, "0")}-${dt.day.toString().padLeft(2, "0")}T${picked.hour.toString().padLeft(2, "0")}:${picked.minute.toString().padLeft(2, "0")}:00Z";
                                          setState(() => saving = true);
                                          try {
                                            final api = ApiService(
                                              ref.read(apiClientProvider),
                                            );
                                            await api.patch(
                                              Endpoints.walkInClockInOut(
                                                item["id"].toString(),
                                              ),
                                              data: {"clock_in_time": value},
                                            );
                                            await _loadShifts();
                                          } catch (_) {} finally {
                                            if (mounted) {
                                              setState(() => saving = false);
                                            }
                                          }
                                        },
                                  child: const Text("Set"),
                                ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  clockOut ?? "Clock out: N/A",
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                              if (clockOut == null)
                                TextButton(
                                  onPressed: saving
                                      ? null
                                      : () async {
                                          final picked = await showTimePicker(
                                            context: context,
                                            initialTime: TimeOfDay.now(),
                                          );
                                          if (picked == null) return;
                                          final dt = DateTime.now();
                                          final value =
                                              "${dt.year}-${dt.month.toString().padLeft(2, "0")}-${dt.day.toString().padLeft(2, "0")}T${picked.hour.toString().padLeft(2, "0")}:${picked.minute.toString().padLeft(2, "0")}:00Z";
                                          setState(() => saving = true);
                                          try {
                                            final api = ApiService(
                                              ref.read(apiClientProvider),
                                            );
                                            await api.patch(
                                              Endpoints.walkInClockInOut(
                                                item["id"].toString(),
                                              ),
                                              data: {"clock_out_time": value},
                                            );
                                            await _loadShifts();
                                          } catch (_) {} finally {
                                            if (mounted) {
                                              setState(() => saving = false);
                                            }
                                          }
                                        },
                                  child: const Text("Set"),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            height: 30,
            width: 30,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: const Icon(Icons.favorite, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                      if (id.isEmpty) return;
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

class _FilterBadge extends StatelessWidget {
  const _FilterBadge({required this.count, required this.onTap});
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
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightGray),
        ),
        child: Row(
          children: [
            const Icon(Icons.tune, size: 18, color: AppColors.greyBlue),
            if (count > 0) ...[
              const SizedBox(width: 6),
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
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.lightPink,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _CredentialBadge extends StatelessWidget {
  const _CredentialBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final text = _credentialLabel(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.offwhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: AppColors.greyBlue),
      ),
    );
  }
}

String _credentialLabel(String status) {
  switch (status) {
    case "CREDENTIAL_VERIFIED":
      return "Verified";
    case "CREDENTIAL_PENDING":
      return "Pending";
    case "CREDENTIAL_REJECTED":
      return "Rejected";
    case "CREDENTIAL_EXPIRED":
      return "Expired";
    default:
      return "All";
  }
}

String _employeeIdForActions(Map<String, dynamic> employee) {
  final candidates = [
    employee["id"],
    employee["employee_id"],
    employee["employeeId"],
    employee["profile_id"],
    employee["nurse_id"],
    employee["user_id"],
    _nested(employee, ["profile", "id"]),
  ];
  for (final c in candidates) {
    final value = _stringify(c);
    if (value.isEmpty) continue;
    return value;
  }
  return "";
}

dynamic _nested(Map<String, dynamic> data, List<String> path) {
  dynamic current = data;
  for (final key in path) {
    if (current is Map && current.containsKey(key)) {
      current = current[key];
    } else {
      return null;
    }
  }
  return current;
}

String _stringify(dynamic value) {
  if (value == null) return "";
  if (value is String) return value.trim();
  if (value is num) return value.toString();
  return value.toString();
}

String _formatPhone(String countryCode, String mobile) {
  final digits = mobile.replaceAll(RegExp(r"\D"), "");
  if (digits.length == 10) {
    return "$countryCode (${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}";
  }
  return "$countryCode $mobile".trim();
}

void _openFilterSheet(
  BuildContext context,
  EmployeesState state,
  EmployeesController controller,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return _EmployeesFilterSheet(state: state, controller: controller);
    },
  );
}

class _EmployeesFilterSheet extends StatefulWidget {
  const _EmployeesFilterSheet({
    required this.state,
    required this.controller,
  });

  final EmployeesState state;
  final EmployeesController controller;

  @override
  State<_EmployeesFilterSheet> createState() => _EmployeesFilterSheetState();
}

class _EmployeesFilterSheetState extends State<_EmployeesFilterSheet> {
  late List<String> jobTitles;
  late List<String> departments;
  late String credential;
  late String ordering;
  String jobQuery = "";
  String deptQuery = "";

  @override
  void initState() {
    super.initState();
    jobTitles = [...widget.state.selectedJobTitles];
    departments = [...widget.state.selectedDepartments];
    credential = widget.state.credentialStatus;
    ordering = widget.state.ordering;
  }

  @override
  Widget build(BuildContext context) {
    final jobOptions = widget.state.jobTitles.where((t) {
      final name = t["name"]?.toString().toLowerCase() ?? "";
      return name.contains(jobQuery.toLowerCase());
    }).toList();
    final deptOptions = widget.state.departments.where((d) {
      final name = d["name"]?.toString().toLowerCase() ?? "";
      return name.contains(deptQuery.toLowerCase());
    }).toList();

    final height = MediaQuery.of(context).size.height * 0.85;
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
              Text("Filters", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    _FilterSectionHeader(title: "Job Titles"),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: "Search job titles",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() => jobQuery = value),
                  ),
                  const SizedBox(height: 8),
                  ...jobOptions.map((item) {
                    final id = item["id"]?.toString() ?? "";
                    final name = item["name"]?.toString() ?? "";
                    final checked = jobTitles.contains(id);
                    return CheckboxListTile(
                      value: checked,
                      onChanged: (_) {
                        setState(() {
                          if (checked) {
                            jobTitles.remove(id);
                          } else {
                            jobTitles.add(id);
                          }
                        });
                      },
                      title: Text(name),
                      controlAffinity: ListTileControlAffinity.trailing,
                      activeColor: AppColors.primary,
                    );
                  }),
                  const SizedBox(height: 12),
                  _FilterSectionHeader(title: "Departments"),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: "Search departments",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() => deptQuery = value),
                  ),
                  const SizedBox(height: 8),
                  ...deptOptions.map((item) {
                    final id = item["id"]?.toString() ?? "";
                    final name = item["name"]?.toString() ?? "";
                    final checked = departments.contains(id);
                    return CheckboxListTile(
                      value: checked,
                      onChanged: (_) {
                        setState(() {
                          if (checked) {
                            departments.remove(id);
                          } else {
                            departments.add(id);
                          }
                        });
                      },
                      title: Text(name),
                      controlAffinity: ListTileControlAffinity.trailing,
                      activeColor: AppColors.primary,
                    );
                  }),
                  const SizedBox(height: 12),
                  _FilterSectionHeader(title: "Credential Status"),
                  ..._credentialOptions.map((option) {
                    return RadioListTile<String>(
                      value: option.value,
                      groupValue: credential,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => credential = value);
                      },
                      title: Text(option.label),
                      activeColor: AppColors.primary,
                    );
                  }),
                    const SizedBox(height: 12),
                    _FilterSectionHeader(title: "Sort"),
                    ..._orderingOptions.map((option) {
                      return RadioListTile<String>(
                        value: option.value,
                        groupValue: ordering,
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => ordering = value);
                        },
                        title: Text(option.label),
                        activeColor: AppColors.primary,
                      );
                    }),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        widget.controller.clearFilters();
                        Navigator.pop(context);
                      },
                      child: const Text("Clear"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.controller.applyFilters(
                          jobTitles: jobTitles,
                          departments: departments,
                          credentialStatus: credential,
                          ordering: ordering,
                        );
                        Navigator.pop(context);
                      },
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
  }
}

class _FilterSectionHeader extends StatelessWidget {
  const _FilterSectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _OptionItem {
  const _OptionItem(this.label, this.value);
  final String label;
  final String value;
}

const _credentialOptions = [
  _OptionItem("All", "CREDENTIAL_ALL"),
  _OptionItem("Verified", "CREDENTIAL_VERIFIED"),
  _OptionItem("Pending", "CREDENTIAL_PENDING"),
  _OptionItem("Rejected", "CREDENTIAL_REJECTED"),
  _OptionItem("Expired", "CREDENTIAL_EXPIRED"),
];

const _orderingOptions = [
  _OptionItem("Newest first", "-created_at"),
  _OptionItem("Oldest first", "created_at"),
  _OptionItem("Name A-Z", "name"),
  _OptionItem("Name Z-A", "-name"),
  _OptionItem("Position A-Z", "position"),
  _OptionItem("Position Z-A", "-position"),
];

List<dynamic> _extractList(dynamic data) {
  if (data is Map<String, dynamic>) {
    if (data["data"] is List) return data["data"] as List;
    if (data["results"] is List) return data["results"] as List;
    if (data["data"] is Map && (data["data"]["results"] is List)) {
      return data["data"]["results"] as List;
    }
  }
  if (data is List) return data;
  return [];
}
