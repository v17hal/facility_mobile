import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../core/theme/app_colors.dart";
import "../../routes/app_routes.dart";
import "employee_detail_controller.dart";
import "employee_form_screen.dart";

class EmployeeDetailScreen extends ConsumerWidget {
  const EmployeeDetailScreen({super.key, required this.employeeId});

  final String employeeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(employeeDetailControllerProvider(employeeId));
    final controller =
        ref.read(employeeDetailControllerProvider(employeeId).notifier);

    final employee = state.data ?? {};
    final name = "${employee["first_name"] ?? ""} ${employee["last_name"] ?? ""}"
        .trim();
    final jobTitle =
        employee["job_title"]?["name"]?.toString() ?? "Job Title";
    final department =
        employee["department"]?["name"]?.toString() ?? "Department";
    final phone =
        "${employee["country_code"] ?? ""} ${employee["mobile"] ?? ""}".trim();
    final email = employee["email"]?.toString() ?? "";
    final status = employee["status"]?.toString() ?? "";
    final dependents = employee["dependents"] is List
        ? (employee["dependents"] as List).length
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Employee Detail"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: state.data == null
                ? null
                : () async {
                    final updated = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EmployeeFormScreen(initial: employee),
                      ),
                    );
                    if (updated == true) {
                      controller.fetch();
                    }
                  },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.fetch,
          ),
        ],
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.lightGray),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.offwhite,
                        child: Text(
                          name.isNotEmpty ? name[0] : "?",
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
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
                        _Badge(label: status),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: state.data == null
                            ? null
                            : () async {
                                await controller.fetchWageHistory();
                                if (!context.mounted) return;
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
                                    employeeId: employeeId,
                                  ),
                                );
                              },
                        child: const Text("Wage History"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: "Personal Information",
                  children: [
                    _InfoRow(
                      label: "Employee ID",
                      value: _pickValue([
                        employee["employee_id"],
                        employee["employeeId"],
                        employee["employee_code"],
                        employee["employeeCode"],
                      ]),
                    ),
                    _InfoRow(
                      label: "Date of Hire",
                      value: _formatDate(_pickFirst([
                        employee["date_of_hire"],
                        employee["doj"],
                        employee["date_of_joining"],
                      ])),
                    ),
                    _InfoRow(
                      label: "Date of Termination",
                      value: _formatDate(_pickFirst([
                        employee["date_of_termination"],
                        employee["dot"],
                      ])),
                    ),
                    _InfoRow(
                      label: "Date of Rejoining",
                      value: _formatDate(_pickFirst([
                        employee["date_of_rejoining"],
                        employee["dor"],
                      ])),
                    ),
                    _InfoRow(
                      label: "Job Category",
                      value: _pickValue([
                        employee["job_category"],
                        employee["job_category_name"],
                        employee["job_category_title"],
                      ]),
                    ),
                    _InfoRow(
                      label: "Job Title",
                      value: jobTitle,
                    ),
                    _InfoRow(
                      label: "Employee Type",
                      value: _pickValue([
                        employee["employee_type"],
                        employee["employment_type"],
                      ]),
                    ),
                    _InfoRow(
                      label: "Department",
                      value: department,
                    ),
                    _InfoRow(
                      label: "Status",
                      value: status,
                    ),
                  ],
                ),
                _SectionCard(
                  title: "Pay Information",
                  children: [
                    _InfoRow(
                      label: "Payment Category",
                      value: _pickValue([
                        employee["payment_category"],
                        employee["paymentCategory"],
                      ]),
                    ),
                    _InfoRow(
                      label: "Hourly Rate",
                      value: _pickValue([
                        employee["hourly_rate"],
                        employee["hourlyRate"],
                      ]),
                    ),
                    _InfoRow(
                      label: "Bi-Weekly Rate",
                      value: _pickValue([
                        employee["bi_weekly_rate"],
                        employee["biweekly_rate"],
                      ]),
                    ),
                    _InfoRow(
                      label: "Pay Type",
                      value: _pickValue([
                        employee["pay_type"],
                        employee["payType"],
                      ]),
                    ),
                    _InfoRow(
                      label: "Effective From",
                      value: _formatDate(_pickFirst([
                        employee["effective_from"],
                        employee["effectiveFrom"],
                      ])),
                    ),
                    _InfoRow(
                      label: "Marital Status",
                      value: _pickValue([
                        employee["marital_status"],
                        employee["maritalStatus"],
                      ]),
                    ),
                    _InfoRow(
                      label: "Number of Jobs",
                      value: _pickValue([
                        employee["number_of_jobs"],
                        employee["numberOfJobs"],
                      ]),
                    ),
                    _InfoRow(
                      label: "Dependents",
                      value: dependents?.toString() ?? "N/A",
                    ),
                    _InfoRow(
                      label: "Other Income Source",
                      value: _pickValue([
                        employee["other_income_source"],
                        employee["otherIncomeSource"],
                      ]),
                    ),
                    _InfoRow(
                      label: "Deductions",
                      value: _pickValue([
                        employee["deductions"],
                        employee["deduction"],
                      ]),
                    ),
                    _InfoRow(
                      label: "Extra Withholding",
                      value: _pickValue([
                        employee["extra_withholding"],
                        employee["extraWithholding"],
                      ]),
                    ),
                  ],
                ),
                _SectionCard(
                  title: "Contact",
                  children: [
                    _InfoRow(label: "Phone", value: phone),
                    if (email.isNotEmpty)
                      _InfoRow(label: "Email", value: email),
                    _InfoRow(
                      label: "Address",
                      value: _pickValue([
                        employee["address"],
                        employee["address1"],
                        employee["street"],
                      ]),
                    ),
                    _InfoRow(
                      label: "City",
                      value: _pickValue([
                        employee["city"],
                      ]),
                    ),
                    _InfoRow(
                      label: "State",
                      value: _pickValue([
                        employee["state"],
                        employee["state_name"],
                      ]),
                    ),
                    _InfoRow(
                      label: "Zip",
                      value: _pickValue([
                        employee["zip"],
                        employee["zip_code"],
                      ]),
                    ),
                  ],
                ),
                _SectionCard(
                  title: "Paychex",
                  children: [
                    _InfoRow(
                      label: "Employee ID",
                      value: _pickValue([
                        _nested(employee, ["paychex", "employee_id"]),
                        employee["paychex_employee_id"],
                      ]),
                    ),
                    _InfoRow(
                      label: "Paychex Category",
                      value: _pickValue([
                        _nested(employee, ["paychex", "category"]),
                        employee["paychex_category"],
                      ]),
                    ),
                    _InfoRow(
                      label: "Organization Unit ID (LabourLevel1)",
                      value: _pickValue([
                        _nested(employee, ["paychex", "organization_unit_id"]),
                        employee["organization_unit_id"],
                      ]),
                    ),
                    _InfoRow(
                      label: "Organization Unit ID (LabourLevel5)",
                      value: _pickValue([
                        _nested(employee, ["paychex", "organization_unit_id_level5"]),
                        employee["organization_unit_id_level5"],
                      ]),
                    ),
                    _InfoRow(
                      label: "Account Holder Name",
                      value: _pickValue([
                        _nested(employee, ["paychex", "account_holder_name"]),
                        employee["account_holder_name"],
                      ]),
                    ),
                    _InfoRow(
                      label: "Account Type",
                      value: _pickValue([
                        _nested(employee, ["paychex", "account_type"]),
                        employee["account_type"],
                      ]),
                    ),
                    _InfoRow(
                      label: "SSN",
                      value: _pickValue([
                        _nested(employee, ["paychex", "ssn"]),
                        employee["ssn"],
                      ]),
                    ),
                    _InfoRow(
                      label: "Government Document Front",
                      value: _pickValue([
                        employee["government_document_front"],
                        _nested(employee, ["paychex", "government_document_front"]),
                      ]),
                    ),
                    _InfoRow(
                      label: "Government Document Back",
                      value: _pickValue([
                        employee["government_document_back"],
                        _nested(employee, ["paychex", "government_document_back"]),
                      ]),
                    ),
                    _InfoRow(
                      label: "W2 Form",
                      value: _pickValue([
                        employee["w2_form"],
                        _nested(employee, ["paychex", "w2_form"]),
                      ]),
                    ),
                  ],
                ),
                _SectionCard(
                  title: "Tax Forms",
                  children: [
                    _InfoRow(
                      label: "Forms Count",
                      value: (employee["tax_forms"] is List)
                          ? (employee["tax_forms"] as List).length.toString()
                          : "N/A",
                    ),
                  ],
                ),
                _SectionCard(
                  title: "Benefits Info",
                  children: [
                    _InfoRow(
                      label: "Benefits",
                      value: (employee["benefits"] is List)
                          ? (employee["benefits"] as List).length.toString()
                          : "N/A",
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.push(AppRoutes.employees),
                        child: const Text("Back to Employees"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
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
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class WageHistorySheet extends ConsumerWidget {
  const WageHistorySheet({
    super.key,
    required this.employeeName,
    required this.employeeId,
  });

  final String employeeName;
  final String employeeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(employeeDetailControllerProvider(employeeId));
    final controller =
        ref.read(employeeDetailControllerProvider(employeeId).notifier);
    final items = state.wageHistory;

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
                  "Wage History ($employeeName)",
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
            const SizedBox(height: 8),
            if (state.wageLoading)
              const LinearProgressIndicator(minHeight: 2)
            else if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text("No wage history found."),
              )
            else
              SizedBox(
                height: 360,
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final range =
                        "${_formatDate(item["created_at"])} - ${_formatDate(item["updated_at"])}";
                    final rate = _pickValue([
                      item["rate"],
                    ]);
                    final paymentCategory = _pickValue([
                      item["payment_category"],
                    ]);
                    final addedBy = _pickValue([
                      _nested(item, ["updated_by", "first_name"]) != null
                          ? "${_nested(item, ["updated_by", "first_name"])} ${_nested(item, ["updated_by", "last_name"])}"
                          : null,
                    ]);
                    final reason = _pickValue([item["payrate_reason"]]);
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
                            range,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          _InfoRow(
                            label: "Hourly Rate",
                            value: "$rate/$paymentCategory",
                          ),
                          _InfoRow(label: "Added By", value: addedBy),
                          _InfoRow(
                            label: "Updated Date",
                            value: _formatDate(item["updated_at"]),
                          ),
                          _InfoRow(label: "Reason", value: reason),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton(
                  onPressed: state.wagePage > 1
                      ? () => controller.fetchWageHistory(
                            page: state.wagePage - 1,
                          )
                      : null,
                  child: const Text("Prev"),
                ),
                const Spacer(),
                Text("${state.wagePage}"),
                const Spacer(),
                TextButton(
                  onPressed: (state.wagePage * state.wagePageSize) <
                          state.wageTotal
                      ? () => controller.fetchWageHistory(
                            page: state.wagePage + 1,
                          )
                      : null,
                  child: const Text("Next"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _pickValue(List<dynamic?> values) {
  for (final v in values) {
    final text = _stringify(v);
    if (text.isNotEmpty && text != "N/A") return text;
  }
  return "N/A";
}

dynamic _pickFirst(List<dynamic?> values) {
  for (final v in values) {
    if (v == null) continue;
    if (v is String && v.trim().isEmpty) continue;
    return v;
  }
  return null;
}

String _stringify(dynamic value) {
  if (value == null) return "";
  if (value is String) return value.trim();
  if (value is num) return value.toString();
  if (value is Map && value["name"] != null) {
    return value["name"].toString();
  }
  return value.toString();
}

String _formatDate(dynamic value) {
  if (value == null) return "N/A";
  if (value is DateTime) {
    return "${value.month.toString().padLeft(2, "0")}/${value.day.toString().padLeft(2, "0")}/${value.year}";
  }
  if (value is String && value.trim().isNotEmpty) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      return "${parsed.month.toString().padLeft(2, "0")}/${parsed.day.toString().padLeft(2, "0")}/${parsed.year}";
    }
    return value;
  }
  return "N/A";
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
