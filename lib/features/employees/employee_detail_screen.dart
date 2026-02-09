import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:file_picker/file_picker.dart";

import "../../core/theme/app_colors.dart";
import "../../core/network/api_provider.dart";
import "../../core/network/api_service.dart";
import "../../core/network/endpoints.dart";
import "../../routes/app_routes.dart";
import "employee_detail_controller.dart";
import "employee_form_screen.dart";
import "employee_payment_detail_screen.dart";
import "employee_shift_info_screen.dart";

class EmployeeDetailScreen extends ConsumerStatefulWidget {
  const EmployeeDetailScreen({super.key, required this.employeeId});

  final String employeeId;

  @override
  ConsumerState<EmployeeDetailScreen> createState() =>
      _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends ConsumerState<EmployeeDetailScreen> {
  bool showPan = false;

  @override
  Widget build(BuildContext context) {
    final state =
        ref.watch(employeeDetailControllerProvider(widget.employeeId));
    final controller =
        ref.read(employeeDetailControllerProvider(widget.employeeId).notifier);

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
    final dependentsList = state.dependents;
    final taxForms = state.taxForms;
    final credentials = state.credentials;
    final workHistory = state.workHistory;
    final payDetails = state.payDetails ?? {};
    final w4Forms = state.w4Forms;
    final w4Info = (w4Forms.isNotEmpty ? w4Forms.first : employee["w4_info"]) ??
        <String, dynamic>{};
    final w2Value = _pickValue([
      employee["w2_form"],
      _nested(employee, ["paychex", "w2_form"]),
    ]);

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
                        onPressed: status == "BLOCKED"
                            ? null
                            : () => controller.update({"status": "BLOCKED"}),
                        child: const Text("Block Employee"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: status == "TERMINATED"
                            ? null
                            : () => controller.update({"status": "TERMINATED"}),
                        child: const Text("Terminate Employee"),
                      ),
                    ),
                  ],
                ),
                if (status == "BLOCKED" || status == "TERMINATED") ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              controller.update({"status": "REINITIATED"}),
                          child: const Text("Reinitiate"),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                _SectionCard(
                  title: "Personal Information",
                  children: [
                    _InfoRow(
                      label: "Employee ID",
                      value: _displayEmployeeId(employee),
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
                        _nested(employee, ["job_title", "job_category", "name"]),
                        _nested(employee, ["job_title", "category", "name"]),
                      ]),
                    ),
                    _InfoRow(
                      label: "Job Title",
                      value: jobTitle,
                    ),
                    _InfoRow(
                      label: "Payment Category",
                      value: _pickValue([
                        employee["payment_category"],
                        employee["paymentCategory"],
                        payDetails["payment_category"],
                        payDetails["paymentCategory"],
                      ]),
                    ),
                    _InfoRow(
                      label: "Hourly Rate",
                      value: _pickValue([
                        employee["hourly_rate"],
                        employee["hourlyRate"],
                        payDetails["hourly_rate"],
                        payDetails["hourlyRate"],
                      ]),
                    ),
                    _InfoRow(
                      label: "Bi-Weekly Rate",
                      value: _pickValue([
                        employee["bi_weekly_rate"],
                        employee["biweekly_rate"],
                        payDetails["bi_weekly_rate"],
                        payDetails["biweekly_rate"],
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
                    _InfoRow(
                      label: "Status",
                      value: status,
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
                        _nested(employee, ["paychex", "category_name"]),
                        _nested(employee, ["paychex", "category_title"]),
                        employee["paychex_category_name"],
                        employee["paychex_category_title"],
                        employee["paychex_category"],
                        employee["paychex_category_name"],
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
                      value: _maskableValue(
                        _pickValue([
                          _nested(employee, ["paychex", "ssn"]),
                          _nested(employee, ["paychex", "ssn_number"]),
                          employee["ssn_number"],
                          employee["social_security_number"],
                          employee["ssn"],
                        ]),
                        showPan,
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          showPan ? Icons.visibility_off : Icons.visibility,
                          size: 18,
                        ),
                        onPressed: () => setState(() => showPan = !showPan),
                      ),
                    ),
                    _InfoRow(
                      label: "PAN",
                      value: _maskableValue(
                        _pickValue([
                          employee["pan"],
                          employee["pan_number"],
                          employee["pan_no"],
                          employee["panNo"],
                          employee["paychex_pan"],
                          _nested(employee, ["paychex", "pan_number"]),
                          _nested(employee, ["paychex", "pan"]),
                        ]),
                        showPan,
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          showPan ? Icons.visibility_off : Icons.visibility,
                          size: 18,
                        ),
                        onPressed: () => setState(() => showPan = !showPan),
                      ),
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
                      value: w2Value,
                    ),
                    if (w2Value != "N/A")
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: controller.fetchPayDetails,
                                child: const Text("Refresh"),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text("W2 Details"),
                                      content: Text(w2Value),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text("Close"),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: const Text("View Details"),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  final pending = _pickValue([
                                    payDetails["pending_payments"],
                                    payDetails["pendingPayments"],
                                  ]);
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text("Pending Details"),
                                      content: Text(pending),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text("Close"),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: const Text("Pending Details"),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (taxForms.isNotEmpty || state.taxFormsLoading)
                  _SectionCard(
                    title: "Tax Forms",
                    trailing: TextButton(
                      onPressed: controller.refreshTaxForms,
                      child: const Text("Refresh"),
                    ),
                    children: [
                      if (state.taxFormsLoading)
                        const LinearProgressIndicator(minHeight: 2),
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: "Forms Count",
                        value: taxForms.length.toString(),
                      ),
                      ...taxForms.map((form) {
                        final name = _pickValue([
                          form["form_name"],
                          form["name"],
                          form["title"],
                        ]);
                        final status = _pickValue([
                          form["status"],
                          form["form_status"],
                        ]);
                        final updated = _formatDate(_pickFirst([
                          form["updated_at"],
                          form["created_at"],
                        ]));
                        final formId = form["id"]?.toString() ?? "";
                        return _TaxFormRow(
                          title: name,
                          subtitle: "$status - $updated",
                          onApprove: formId.isEmpty
                              ? null
                              : () => controller.updateTaxFormStatus(
                                    formId: formId,
                                    status: "APPROVED",
                                  ),
                          onReject: formId.isEmpty
                              ? null
                              : () => controller.updateTaxFormStatus(
                                    formId: formId,
                                    status: "REJECTED",
                                  ),
                        );
                      }),
                    ],
                  ),
                _SectionCard(
                  title: "Dependents",
                  trailing: TextButton(
                    onPressed: () => _openDependentForm(
                      context,
                      ref,
                      widget.employeeId,
                      onSave: (payload) =>
                          controller.addDependent(payload),
                    ),
                    child: const Text("Add"),
                  ),
                  children: [
                    if (state.dependentsLoading)
                      const LinearProgressIndicator(minHeight: 2),
                    const SizedBox(height: 8),
                    _InfoRow(
                      label: "Count",
                      value: dependentsList.isNotEmpty
                          ? dependentsList.length.toString()
                          : dependents?.toString() ?? "N/A",
                    ),
                    ...dependentsList.map((item) {
                      final dependentId = item["id"]?.toString() ?? "";
                      final fullName = _pickValue([
                        item["name"],
                        "${item["first_name"] ?? ""} ${item["last_name"] ?? ""}"
                            .trim(),
                        item["full_name"],
                      ]);
                      final relation = _pickValue([
                        item["relationship"],
                        item["relation"],
                        item["type"],
                      ]);
                      final dob = _formatDate(item["dob"]);
                      return _ActionRow(
                        title: fullName,
                        subtitle: "$relation - $dob",
                                onEdit: dependentId.isEmpty
                            ? null
                            : () => _openDependentForm(
                                  context,
                                  ref,
                                  widget.employeeId,
                                  initial: item,
                                  onSave: (payload) => controller.updateDependent(
                                    dependentId,
                                    payload,
                                  ),
                                ),
                        onDelete: dependentId.isEmpty
                            ? null
                            : () => _confirmAction(
                                  context,
                                  title: "Remove Dependent",
                                  message:
                                      "Are you sure you want to remove this dependent?",
                                  onConfirm: () =>
                                      controller.deleteDependent(dependentId),
                                ),
                      );
                    }),
                  ],
                ),
                if (w4Forms.isNotEmpty || state.w4Loading)
                  _SectionCard(
                    title: "W4 Forms",
                    trailing: TextButton(
                      onPressed: () => _openW4FormSheet(
                        context,
                        widget.employeeId,
                        initial: w4Info is Map ? w4Info.cast<String, dynamic>() : {},
                      ),
                      child: const Text("Edit"),
                    ),
                    children: [
                      if (state.w4Loading)
                        const LinearProgressIndicator(minHeight: 2),
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: "Marital Status",
                        value: _pickValue([w4Info["marital_status"]]),
                      ),
                      _InfoRow(
                        label: "Number of Jobs",
                        value: _pickValue([w4Info["no_of_jobs"]]),
                      ),
                      _InfoRow(
                        label: "Dependents",
                        value: _pickValue([w4Info["no_of_dependents"]]),
                      ),
                      _InfoRow(
                        label: "Other Income Source",
                        value: _pickValue([w4Info["other_income_source"]]),
                      ),
                      _InfoRow(
                        label: "Deductions",
                        value: _pickValue([w4Info["deduction"]]),
                      ),
                      _InfoRow(
                        label: "Extra Withholding",
                        value: _pickValue([w4Info["extra_withholding"]]),
                      ),
                    ],
                  ),
                _SectionCard(
                  title: "Credentials",
                  children: [
                    if (state.credentialsLoading)
                      const LinearProgressIndicator(minHeight: 2),
                    const SizedBox(height: 8),
                    _InfoRow(
                      label: "Count",
                      value: credentials.isNotEmpty
                          ? credentials.length.toString()
                          : "N/A",
                    ),
                    ...credentials.map((cred) {
                      final title = _pickValue([
                        cred["name"],
                        cred["title"],
                        cred["credential_name"],
                      ]);
                      final status = _pickValue([
                        cred["status"],
                        cred["credential_status"],
                      ]);
                      final expiry = _formatDate(_pickFirst([
                        cred["expiry_date"],
                        cred["expiry"],
                      ]));
                      final credId = cred["id"]?.toString() ?? "";
                      final dataList = cred["credential_data"];
                      final Map<String, dynamic>? firstData =
                          (dataList is List &&
                                  dataList.isNotEmpty &&
                                  dataList.first is Map)
                              ? Map<String, dynamic>.from(
                                  dataList.first as Map,
                                )
                              : null;
                      final dataType = firstData?["data_type"]?.toString() ??
                          cred["data_type"]?.toString();
                      final initialText =
                          firstData?["text_data"]?.toString();
                      final hasSecondary =
                          (firstData?["upload_data_2"] != null ||
                              firstData?["upload_data_2_thumbnail"] != null);
                      final referenceData =
                          firstData?["reference_data"] is List
                              ? (firstData?["reference_data"] as List)
                              : const [];
                      return _CredentialRow(
                        title: title,
                        status: status,
                        expiry: expiry,
                        onApprove: credId.isEmpty
                            ? null
                            : () => controller.updateCredentialStatus(
                                  credentialId: credId,
                                  status: "APPROVED",
                                ),
                        onReject: credId.isEmpty
                            ? null
                            : () => _openFeedbackDialog(
                                  context,
                                  onSubmit: (feedback) =>
                                      controller.updateCredentialStatus(
                                    credentialId: credId,
                                    status: "REJECTED",
                                    feedback: feedback,
                                  ),
                                ),
                        onExpiry: credId.isEmpty
                            ? null
                            : () => _pickExpiryDate(
                                  context,
                                  onPick: (value) =>
                                      controller.updateCredentialExpiry(
                                    credentialId: credId,
                                    expiry: value,
                                  ),
                                ),
                        onUpload: credId.isEmpty
                            ? null
                            : () {
                                if ((dataType ?? "").toUpperCase() ==
                                    "REFERENCE") {
                                  _openReferenceForm(
                                    context,
                                    ref,
                                    credentialId: credId,
                                    employeeId: widget.employeeId,
                                    initial: referenceData,
                                  );
                                  return;
                                }
                                _openCredentialUploadSheet(
                                  context,
                                  ref,
                                  credentialId: credId,
                                  employeeId: widget.employeeId,
                                  dataType: dataType ?? "UPLOAD",
                                  initialText: initialText,
                                  allowSecondary: hasSecondary,
                                );
                              },
                      );
                    }),
                  ],
                ),
                _SectionCard(
                  title: "Pay Details",
                  children: [
                    if (state.payDetailsLoading)
                      const LinearProgressIndicator(minHeight: 2),
                    const SizedBox(height: 8),
                    _InfoRow(
                      label: "Total Paid",
                      value: _pickValue([
                        payDetails["total_paid"],
                        payDetails["totalPaid"],
                      ]),
                      trailing: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EmployeePaymentDetailScreen(
                                employeeId: widget.employeeId,
                                employeeName: name.isEmpty ? "Employee" : name,
                              ),
                            ),
                          );
                        },
                        child: const Text("View Details"),
                      ),
                    ),
                    _InfoRow(
                      label: "Pending Payments",
                      value: _pickValue([
                        payDetails["pending_payments"],
                        payDetails["pendingPayments"],
                      ]),
                      trailing: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EmployeePaymentDetailScreen(
                                employeeId: widget.employeeId,
                                employeeName: name.isEmpty ? "Employee" : name,
                              ),
                            ),
                          );
                        },
                        child: const Text("View Details"),
                      ),
                    ),
                  ],
                ),
                if (workHistory.isNotEmpty || state.workHistoryLoading)
                  _SectionCard(
                    title: "Shift Info",
                    trailing: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EmployeeShiftInfoScreen(
                              employeeId: widget.employeeId,
                              employeeName:
                                  name.isEmpty ? "Employee" : name,
                            ),
                          ),
                        );
                      },
                      child: const Text("View All"),
                    ),
                    children: [
                      if (state.workHistoryLoading)
                        const LinearProgressIndicator(minHeight: 2),
                      const SizedBox(height: 8),
                      if (workHistory.isEmpty)
                        const Text("No shift info found."),
                      ...workHistory.take(3).map((item) {
                        final shift = _pickValue([
                          item["shift_name"],
                          item["name"],
                        ]);
                        final date = _formatDate(_pickFirst([
                          item["date"],
                          item["shift_date"],
                          item["created_at"],
                        ]));
                        final hours = _pickValue([
                          item["hours_worked"],
                          item["total_hours"],
                        ]);
                        return _InfoRow(
                          label: shift,
                          value: "$date - $hours",
                        );
                      }),
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
  const _InfoRow({
    required this.label,
    required this.value,
    this.trailing,
  });
  final String label;
  final String value;
  final Widget? trailing;

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
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                          ),
                          Expanded(
                            child: Text(
                              value,
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(color: AppColors.primary),
                            ),
                          ),
                          if (trailing != null) ...[
                            const SizedBox(width: 8),
                            Flexible(child: trailing!),
                          ],
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
  const _SectionCard({
    required this.title,
    required this.children,
    this.trailing,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.title,
    required this.subtitle,
    this.onEdit,
    this.onDelete,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.greyBlue),
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: onEdit,
            ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}

class _TaxFormRow extends StatelessWidget {
  const _TaxFormRow({
    required this.title,
    required this.subtitle,
    this.onApprove,
    this.onReject,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.greyBlue),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (onApprove != null)
                ElevatedButton(
                  onPressed: onApprove,
                  child: const Text("Approve"),
                ),
              if (onReject != null) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onReject,
                  child: const Text("Reject"),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _CredentialRow extends StatelessWidget {
  const _CredentialRow({
    required this.title,
    required this.status,
    required this.expiry,
    this.onApprove,
    this.onReject,
    this.onExpiry,
    this.onUpload,
  });

  final String title;
  final String status;
  final String expiry;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onExpiry;
  final VoidCallback? onUpload;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            "$status - $expiry",
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.greyBlue),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              if (onUpload != null)
                OutlinedButton(
                  onPressed: onUpload,
                  child: const Text("Upload/Edit"),
                ),
              if (onApprove != null)
                ElevatedButton(
                  onPressed: onApprove,
                  child: const Text("Approve"),
                ),
              if (onReject != null)
                OutlinedButton(
                  onPressed: onReject,
                  child: const Text("Reject"),
                ),
              if (onExpiry != null)
                TextButton(
                  onPressed: onExpiry,
                  child: const Text("Set Expiry"),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required Future<bool> Function() onConfirm,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
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
  if (result == true) {
    await onConfirm();
  }
}

Future<void> _openFeedbackDialog(
  BuildContext context, {
  required Future<bool> Function(String feedback) onSubmit,
}) async {
  final controller = TextEditingController();
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Reject Credential"),
      content: TextField(
        controller: controller,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: "Add feedback (optional)",
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Reject"),
        ),
      ],
    ),
  );
  if (result == true) {
    await onSubmit(controller.text.trim());
  }
}

Future<void> _pickExpiryDate(
  BuildContext context, {
  required Future<bool> Function(String value) onPick,
}) async {
  final now = DateTime.now();
  final picked = await showDatePicker(
    context: context,
    initialDate: now.add(const Duration(days: 1)),
    firstDate: now,
    lastDate: DateTime(now.year + 10),
  );
  if (picked != null) {
    final value =
        "${picked.year}-${picked.month.toString().padLeft(2, "0")}-${picked.day.toString().padLeft(2, "0")}";
    await onPick(value);
  }
}

Future<void> _openDependentForm(
  BuildContext context,
  WidgetRef ref,
  String employeeId, {
  Map<String, dynamic>? initial,
  required Future<bool> Function(Map<String, dynamic> payload) onSave,
}) async {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _DependentFormSheet(
      employeeId: employeeId,
      initial: initial,
      onSave: onSave,
    ),
  );
}

Future<void> _openCredentialUploadSheet(
  BuildContext context,
  WidgetRef ref, {
  required String credentialId,
  required String employeeId,
  required String dataType,
  String? initialText,
  bool allowSecondary = false,
}) async {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _CredentialUploadSheet(
      credentialId: credentialId,
      employeeId: employeeId,
      dataType: dataType,
      initialText: initialText,
      allowSecondary: allowSecondary,
    ),
  );
}

Future<void> _openW4FormSheet(
  BuildContext context,
  String employeeId, {
  required Map<String, dynamic> initial,
}) async {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _W4FormSheet(
      employeeId: employeeId,
      initial: initial,
    ),
  );
}

class _W4FormSheet extends ConsumerStatefulWidget {
  const _W4FormSheet({
    required this.employeeId,
    required this.initial,
  });

  final String employeeId;
  final Map<String, dynamic> initial;

  @override
  ConsumerState<_W4FormSheet> createState() => _W4FormSheetState();
}

class _W4FormSheetState extends ConsumerState<_W4FormSheet> {
  late final TextEditingController _jobs;
  late final TextEditingController _dependents;
  late final TextEditingController _income;
  late final TextEditingController _deduction;
  late final TextEditingController _withholding;
  String? maritalStatus;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    maritalStatus = initial["marital_status"]?.toString();
    _jobs = TextEditingController(text: _stringify(initial["no_of_jobs"]));
    _dependents =
        TextEditingController(text: _stringify(initial["no_of_dependents"]));
    _income =
        TextEditingController(text: _stringify(initial["other_income_source"]));
    _deduction =
        TextEditingController(text: _stringify(initial["deduction"]));
    _withholding =
        TextEditingController(text: _stringify(initial["extra_withholding"]));
  }

  @override
  void dispose() {
    _jobs.dispose();
    _dependents.dispose();
    _income.dispose();
    _deduction.dispose();
    _withholding.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller =
        ref.read(employeeDetailControllerProvider(widget.employeeId).notifier);
    final w4Id = widget.initial["id"]?.toString();
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
                  "W4 Information",
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
            DropdownButtonFormField<String>(
              value: maritalStatus,
              items: const [
                DropdownMenuItem(
                  value: "SINGLE_OR_MARRIED",
                  child: Text("Single or Married filing separately"),
                ),
                DropdownMenuItem(
                  value: "MARRIED_OR_QUALIFYING",
                  child: Text("Married filing jointly / Qualifying spouse"),
                ),
                DropdownMenuItem(
                  value: "HEAD_OF_HOUSEHOLD",
                  child: Text("Head of household"),
                ),
              ],
              onChanged: (value) => setState(() => maritalStatus = value),
              decoration: const InputDecoration(
                labelText: "Marital Status",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _jobs,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Number of Jobs",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _dependents,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Dependents",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _income,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Other Income Source",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _deduction,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Deductions",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _withholding,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Extra Withholding",
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
                            final payload = {
                              "marital_status": maritalStatus,
                              "no_of_jobs": _jobs.text.trim(),
                              "no_of_dependents": _dependents.text.trim(),
                              "other_income_source": _income.text.trim(),
                              "deduction": _deduction.text.trim(),
                              "extra_withholding": _withholding.text.trim(),
                            };
                            final ok = await controller.upsertW4Form(
                              payload: payload,
                              w4Id: w4Id,
                            );
                            if (!mounted) return;
                            setState(() => saving = false);
                            if (ok) Navigator.pop(context);
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

Future<void> _openReferenceForm(
  BuildContext context,
  WidgetRef ref, {
  required String credentialId,
  required String employeeId,
  required List<dynamic> initial,
}) async {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _ReferenceFormSheet(
      credentialId: credentialId,
      employeeId: employeeId,
      initial: initial,
    ),
  );
}

class _ReferenceFormSheet extends ConsumerStatefulWidget {
  const _ReferenceFormSheet({
    required this.credentialId,
    required this.employeeId,
    required this.initial,
  });

  final String credentialId;
  final String employeeId;
  final List<dynamic> initial;

  @override
  ConsumerState<_ReferenceFormSheet> createState() =>
      _ReferenceFormSheetState();
}

class _ReferenceFormSheetState extends ConsumerState<_ReferenceFormSheet> {
  final List<Map<String, TextEditingController>> _rows = [];
  bool saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initial.isNotEmpty) {
      for (final item in widget.initial) {
        if (item is Map) {
          _rows.add({
            "name": TextEditingController(text: item["name"]?.toString() ?? ""),
            "email":
                TextEditingController(text: item["email"]?.toString() ?? ""),
            "mobile":
                TextEditingController(text: item["mobile"]?.toString() ?? ""),
            "relationship": TextEditingController(
              text: item["relationship"]?.toString() ?? "",
            ),
          });
        }
      }
    }
    if (_rows.isEmpty) {
      _addRow();
    }
  }

  void _addRow() {
    _rows.add({
      "name": TextEditingController(),
      "email": TextEditingController(),
      "mobile": TextEditingController(),
      "relationship": TextEditingController(),
    });
  }

  @override
  void dispose() {
    for (final row in _rows) {
      for (final c in row.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller =
        ref.read(employeeDetailControllerProvider(widget.employeeId).notifier);
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
                  "References",
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
            SizedBox(
              height: 320,
              child: ListView.builder(
                itemCount: _rows.length,
                itemBuilder: (context, index) {
                  final row = _rows[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.lightGray),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: row["name"],
                          decoration: const InputDecoration(
                            labelText: "Name",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: row["email"],
                          decoration: const InputDecoration(
                            labelText: "Email",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: row["mobile"],
                          decoration: const InputDecoration(
                            labelText: "Phone",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: row["relationship"],
                          decoration: const InputDecoration(
                            labelText: "Relationship",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            TextButton.icon(
              onPressed: () => setState(_addRow),
              icon: const Icon(Icons.add),
              label: const Text("Add reference"),
            ),
            const SizedBox(height: 12),
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
                            final refs = _rows.map((row) {
                              return {
                                "name": row["name"]!.text.trim(),
                                "email": row["email"]!.text.trim(),
                                "mobile": row["mobile"]!.text.trim(),
                                "relationship":
                                    row["relationship"]!.text.trim(),
                              };
                            }).toList();
                            final ok = await controller.uploadCredentialReferences(
                              credentialId: widget.credentialId,
                              references: refs,
                            );
                            if (!mounted) return;
                            setState(() => saving = false);
                            if (ok) Navigator.pop(context);
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

class _CredentialUploadSheet extends ConsumerStatefulWidget {
  const _CredentialUploadSheet({
    required this.credentialId,
    required this.employeeId,
    required this.dataType,
    this.initialText,
    this.allowSecondary = false,
  });

  final String credentialId;
  final String employeeId;
  final String dataType;
  final String? initialText;
  final bool allowSecondary;

  @override
  ConsumerState<_CredentialUploadSheet> createState() =>
      _CredentialUploadSheetState();
}

class _CredentialUploadSheetState
    extends ConsumerState<_CredentialUploadSheet> {
  final TextEditingController _text = TextEditingController();
  String? filePath;
  bool saving = false;
  bool secondary = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      _text.text = widget.initialText!;
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller =
        ref.read(employeeDetailControllerProvider(widget.employeeId).notifier);
    final dataType = widget.dataType.toUpperCase();

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
                  "Update Credential",
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
            if (dataType == "TEXT") ...[
              TextField(
                controller: _text,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: "Text value",
                  border: OutlineInputBorder(),
                ),
              ),
            ] else if (dataType == "UPLOAD") ...[
              OutlinedButton.icon(
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles();
                  if (result != null && result.files.single.path != null) {
                    setState(() => filePath = result.files.single.path);
                  }
                },
                icon: const Icon(Icons.upload_file),
                label: Text(filePath == null ? "Choose file" : "Change file"),
              ),
              if (widget.allowSecondary)
                SwitchListTile(
                  value: secondary,
                  onChanged: (value) => setState(() => secondary = value),
                  title: const Text("Upload signed document"),
                ),
              if (filePath != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    filePath!.split("\\").last,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ] else ...[
              Text(
                "This credential type is not editable from mobile.",
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.greyBlue),
              ),
            ],
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
                            bool ok = false;
                            if (dataType == "TEXT") {
                              ok = await controller.uploadCredentialText(
                                credentialId: widget.credentialId,
                                text: _text.text.trim(),
                              );
                            } else if (dataType == "UPLOAD" &&
                                filePath != null) {
                              if (secondary) {
                                ok = await controller.uploadCredentialFileSecondary(
                                  credentialId: widget.credentialId,
                                  filePath: filePath!,
                                );
                              } else {
                                ok = await controller.uploadCredentialFile(
                                  credentialId: widget.credentialId,
                                  filePath: filePath!,
                                );
                              }
                            }
                            if (!mounted) return;
                            setState(() => saving = false);
                            if (ok) Navigator.pop(context);
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

class _DependentFormSheet extends ConsumerStatefulWidget {
  const _DependentFormSheet({
    required this.employeeId,
    required this.onSave,
    this.initial,
  });

  final String employeeId;
  final Map<String, dynamic>? initial;
  final Future<bool> Function(Map<String, dynamic> payload) onSave;

  @override
  ConsumerState<_DependentFormSheet> createState() =>
      _DependentFormSheetState();
}

class _DependentFormSheetState extends ConsumerState<_DependentFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _relation;
  late final TextEditingController _gender;
  late final TextEditingController _dob;
  late final TextEditingController _address1;
  late final TextEditingController _address2;
  late final TextEditingController _city;
  late final TextEditingController _zip;

  List<Map<String, dynamic>> countries = [];
  List<Map<String, dynamic>> states = [];
  String? countryId;
  String? stateId;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial ?? {};
    _name = TextEditingController(
      text: initial["full_name"]?.toString() ??
          initial["name"]?.toString() ??
          "",
    );
    _relation = TextEditingController(
      text: initial["type"]?.toString() ??
          initial["relation"]?.toString() ??
          "",
    );
    _gender = TextEditingController(
      text: initial["gender"]?.toString() ?? "",
    );
    _dob = TextEditingController(
      text: _formatDate(initial["dob"]),
    );
    final address = initial["address"] as Map? ?? {};
    _address1 = TextEditingController(
      text: address["address_line1"]?.toString() ?? "",
    );
    _address2 = TextEditingController(
      text: address["address_line2"]?.toString() ?? "",
    );
    _city = TextEditingController(
      text: address["city"]?.toString() ?? "",
    );
    _zip = TextEditingController(
      text: address["zipcode"]?.toString() ?? "",
    );
    countryId = address["country"]?["id"]?.toString();
    stateId = address["state"]?["id"]?.toString();
    _loadCountries();
  }

  @override
  void dispose() {
    _name.dispose();
    _relation.dispose();
    _gender.dispose();
    _dob.dispose();
    _address1.dispose();
    _address2.dispose();
    _city.dispose();
    _zip.dispose();
    super.dispose();
  }

  Future<void> _loadCountries() async {
    setState(() => loading = true);
    try {
      final api = ApiService(ref.read(apiClientProvider));
      final resp = await api.get(Endpoints.fetchCountries);
      final list = _extractList(resp.data);
      setState(() {
        countries = list;
        if (countryId == null && countries.isNotEmpty) {
          countryId = countries.first["id"]?.toString();
        }
      });
      if (countryId != null) {
        await _loadStates(countryId!);
      }
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _loadStates(String id) async {
    try {
      final api = ApiService(ref.read(apiClientProvider));
      final resp = await api.get(Endpoints.fetchStates(id));
      final list = _extractList(resp.data);
      setState(() {
        states = list;
        if (stateId == null && states.isNotEmpty) {
          stateId = states.first["id"]?.toString();
        }
      });
    } catch (_) {}
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
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    widget.initial == null ? "Add Dependent" : "Edit Dependent",
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
              if (loading) const LinearProgressIndicator(minHeight: 2),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    TextField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: "Full name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _relation,
                      decoration: const InputDecoration(
                        labelText: "Relation",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _gender,
                      decoration: const InputDecoration(
                        labelText: "Gender",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _dob,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: "Date of birth",
                        border: OutlineInputBorder(),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now()
                              .subtract(const Duration(days: 3650)),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          _dob.text =
                              "${picked.month.toString().padLeft(2, "0")}/${picked.day.toString().padLeft(2, "0")}/${picked.year}";
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _address1,
                      decoration: const InputDecoration(
                        labelText: "Street line 1",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _address2,
                      decoration: const InputDecoration(
                        labelText: "Street line 2",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _city,
                      decoration: const InputDecoration(
                        labelText: "City",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: countryId,
                            items: countries
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c["id"]?.toString(),
                                    child: Text(c["name"]?.toString() ?? ""),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() => countryId = value);
                              if (value != null) {
                                _loadStates(value);
                              }
                            },
                            decoration: const InputDecoration(
                              labelText: "Country",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: stateId,
                            items: states
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s["id"]?.toString(),
                                    child: Text(s["name"]?.toString() ?? ""),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setState(() => stateId = value),
                            decoration: const InputDecoration(
                              labelText: "State",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _zip,
                      decoration: const InputDecoration(
                        labelText: "Zip code",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
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
                      onPressed: () async {
                        final dobValue = _parseUsDate(_dob.text);
                        final payload = {
                          "full_name": _name.text.trim(),
                          "type": _relation.text.trim(),
                          "dob": dobValue,
                          "gender": _gender.text.trim(),
                          "address": {
                            "address_line1": _address1.text.trim(),
                            "address_line2": _address2.text.trim(),
                            "city": _city.text.trim(),
                            "state": stateId,
                            "zipcode": _zip.text.trim(),
                            "country": countryId,
                          },
                        };
                        final ok = await widget.onSave(payload);
                        if (!context.mounted) return;
                        if (ok) Navigator.pop(context);
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
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text("Date Range")),
                      DataColumn(label: Text("Hourly Rate")),
                      DataColumn(label: Text("Added By")),
                      DataColumn(label: Text("Updated Date")),
                      DataColumn(label: Text("Reason")),
                    ],
                    rows: items.map((item) {
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
                      final updated = _formatDate(item["updated_at"]);
                      final reason = _pickValue([item["payrate_reason"]]);
                      return DataRow(cells: [
                        DataCell(Text(range)),
                        DataCell(Text("$rate/$paymentCategory")),
                        DataCell(Text(addedBy)),
                        DataCell(Text(updated)),
                        DataCell(Text(reason)),
                      ]);
                    }).toList(),
                  ),
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

String _displayEmployeeId(Map<String, dynamic> employee) {
  final candidates = [
    employee["employee_id"],
    employee["employeeId"],
    employee["employee_code"],
    employee["employeeCode"],
    employee["employee_no"],
    employee["employee_number"],
    employee["emp_id"],
    employee["empId"],
  ];
  for (final c in candidates) {
    final value = _stringify(c);
    if (value.isEmpty || value == "N/A") continue;
    if (_looksLikeUuid(value)) continue;
    return value;
  }
  return "N/A";
}

bool _looksLikeUuid(String value) {
  final regex = RegExp(
    r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$",
  );
  return regex.hasMatch(value);
}

String _maskableValue(String value, bool show) {
  if (value.isEmpty || value == "N/A") return "N/A";
  if (show) return value;
  if (value.length <= 4) return "****";
  return "${"*" * (value.length - 4)}${value.substring(value.length - 4)}";
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

String? _parseUsDate(String input) {
  final parts = input.split("/");
  if (parts.length != 3) return null;
  final mm = int.tryParse(parts[0]);
  final dd = int.tryParse(parts[1]);
  final yyyy = int.tryParse(parts[2]);
  if (mm == null || dd == null || yyyy == null) return null;
  final dt = DateTime(yyyy, mm, dd);
  return "${dt.year}-${dt.month.toString().padLeft(2, "0")}-${dt.day.toString().padLeft(2, "0")}";
}

List<Map<String, dynamic>> _extractList(dynamic data) {
  if (data is Map<String, dynamic>) {
    final nested = data["data"];
    if (nested is List) {
      return nested
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (nested is Map<String, dynamic> && nested["results"] is List) {
      return (nested["results"] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (data["results"] is List) {
      return (data["results"] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
  }
  if (data is List) {
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
  return [];
}
