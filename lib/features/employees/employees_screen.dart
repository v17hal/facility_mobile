import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/theme/app_colors.dart";
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
    _TabItem(label: "Invited", tab: EmployeesTab.invited),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
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
                    final id = employee["id"]?.toString() ?? "";
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
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
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
  });

  final ScrollController controller;
  final bool loading;
  final bool loadingMore;
  final List<Map<String, dynamic>> data;
  final ValueChanged<String> onResend;
  final ValueChanged<String> onCancel;
  final ValueChanged<Map<String, dynamic>> onWageHistory;

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
  });

  final Map<String, dynamic> employee;
  final ValueChanged<String> onResend;
  final ValueChanged<String> onCancel;
  final ValueChanged<Map<String, dynamic>> onWageHistory;
  final VoidCallback onTap;

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
