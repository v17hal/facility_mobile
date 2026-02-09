import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/network/api_provider.dart";
import "../../core/network/api_service.dart";
import "../../core/network/endpoints.dart";
import "employees_controller.dart";

class EmployeeFormScreen extends ConsumerStatefulWidget {
  const EmployeeFormScreen({
    super.key,
    this.initial,
  });

  final Map<String, dynamic>? initial;

  bool get isEdit => initial != null;

  @override
  ConsumerState<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends ConsumerState<EmployeeFormScreen> {
  late final TextEditingController firstName;
  late final TextEditingController lastName;
  late final TextEditingController email;
  late final TextEditingController phone;
  late final TextEditingController countryCode;

  String? jobTitleId;
  String? departmentId;
  String status = "ACTIVE";
  bool isWalkIn = false;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    final data = widget.initial ?? {};
    firstName = TextEditingController(text: data["first_name"]?.toString() ?? "");
    lastName = TextEditingController(text: data["last_name"]?.toString() ?? "");
    email = TextEditingController(text: data["email"]?.toString() ?? "");
    phone = TextEditingController(text: data["mobile"]?.toString() ?? "");
    countryCode =
        TextEditingController(text: data["country_code"]?.toString() ?? "+1");
    jobTitleId = data["job_title"]?["id"]?.toString();
    departmentId = data["department"]?["id"]?.toString();
    status = data["status"]?.toString() ?? status;
    isWalkIn = data["is_walk_in_nurse"] == true;
  }

  @override
  void dispose() {
    firstName.dispose();
    lastName.dispose();
    email.dispose();
    phone.dispose();
    countryCode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final errors = _validate();
    if (errors.isNotEmpty) {
      _showSnack(errors.first);
      return;
    }
    setState(() => loading = true);
    try {
      final api = ApiService(ref.read(apiClientProvider));
      final payload = {
        "first_name": firstName.text.trim(),
        "last_name": lastName.text.trim(),
        "email": email.text.trim(),
        "mobile": phone.text.trim(),
        "country_code": countryCode.text.trim(),
        "job_title": jobTitleId,
        "department": departmentId,
        "status": status,
        "is_walk_in_nurse": isWalkIn,
      };

      if (widget.isEdit) {
        final id = widget.initial?["id"]?.toString() ?? "";
        await api.patch("${Endpoints.employees}/$id", data: payload);
      } else {
        await api.post(Endpoints.employees, data: payload);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      _showSnack(widget.isEdit ? "Update failed" : "Create failed");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  List<String> _validate() {
    final errors = <String>[];
    if (firstName.text.trim().isEmpty) errors.add("First name is required");
    if (lastName.text.trim().isEmpty) errors.add("Last name is required");
    if (email.text.trim().isEmpty) errors.add("Email is required");
    if (phone.text.trim().isEmpty) errors.add("Mobile is required");
    if (jobTitleId == null || jobTitleId!.isEmpty) {
      errors.add("Job title is required");
    }
    if (departmentId == null || departmentId!.isEmpty) {
      errors.add("Department is required");
    }
    return errors;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(employeesControllerProvider);
    final jobTitles = filters.jobTitles;
    final departments = filters.departments;
    final statusOptions = const [
      "ACTIVE",
      "INVITED",
      "BLOCKED",
      "TERMINATED",
      "REINITIATED",
    ];
    final statusValue = statusOptions.contains(status) ? status : null;
    final jobTitleValue = jobTitles.any((t) => t["id"]?.toString() == jobTitleId)
        ? jobTitleId
        : null;
    final departmentValue =
        departments.any((d) => d["id"]?.toString() == departmentId)
            ? departmentId
            : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? "Edit Employee" : "Add Employee"),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _FieldLabel("First Name"),
              TextField(
                controller: firstName,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              _FieldLabel("Last Name"),
              TextField(
                controller: lastName,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              _FieldLabel("Email"),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              _FieldLabel("Mobile"),
              Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: countryCode,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _FieldLabel("Job Title"),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: jobTitleValue,
                items: jobTitles
                    .map(
                      (t) => DropdownMenuItem(
                        value: t["id"]?.toString(),
                        child: Text(t["name"]?.toString() ?? ""),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => jobTitleId = value),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              _FieldLabel("Department"),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: departmentValue,
                items: departments
                    .map(
                      (d) => DropdownMenuItem(
                        value: d["id"]?.toString(),
                        child: Text(d["name"]?.toString() ?? ""),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => departmentId = value),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              _FieldLabel("Status"),
              DropdownButtonFormField<String>(
                value: statusValue,
                items: const [
                  DropdownMenuItem(value: "ACTIVE", child: Text("Active")),
                  DropdownMenuItem(value: "INVITED", child: Text("Invited")),
                  DropdownMenuItem(value: "BLOCKED", child: Text("Blocked")),
                  DropdownMenuItem(value: "TERMINATED", child: Text("Terminated")),
                  DropdownMenuItem(
                    value: "REINITIATED",
                    child: Text("Reinitiated"),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => status = value);
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: isWalkIn,
                onChanged: (value) => setState(() => isWalkIn = value),
                title: const Text("Walk-in nurse"),
              ),
              const SizedBox(height: 16),
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
                      onPressed: _save,
                      child: Text(widget.isEdit ? "Update" : "Create"),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (loading)
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
