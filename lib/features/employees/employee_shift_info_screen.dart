import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";

import "../../core/network/api_provider.dart";
import "../../core/network/api_service.dart";
import "../../core/network/endpoints.dart";
import "../../core/theme/app_colors.dart";

class EmployeeShiftInfoScreen extends ConsumerStatefulWidget {
  const EmployeeShiftInfoScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  final String employeeId;
  final String employeeName;

  @override
  ConsumerState<EmployeeShiftInfoScreen> createState() =>
      _EmployeeShiftInfoScreenState();
}

class _EmployeeShiftInfoScreenState
    extends ConsumerState<EmployeeShiftInfoScreen> {
  bool loading = false;
  Map<String, dynamic>? activeShift;
  List<Map<String, dynamic>> history = [];
  String sortBy = "newest";
  DateTime month = DateTime.now();
  int page = 1;
  int pageSize = 10;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.employeeId.isEmpty) return;
    setState(() => loading = true);
    try {
      final api = ApiService(ref.read(apiClientProvider));
      final activeResp =
          await api.get(Endpoints.employeeActiveShift(widget.employeeId));
      final activeData = activeResp.data is Map<String, dynamic>
          ? Map<String, dynamic>.from(
              activeResp.data["data"] ?? activeResp.data,
            )
          : null;
      final ordering = sortBy == "newest" ? "-created_at" : "created_at";
      final params = {
        "page": page,
        "page_size": pageSize,
        "start_date": DateFormat("yyyy-MM-dd")
            .format(DateTime(month.year, month.month, 1)),
        "end_date": DateFormat("yyyy-MM-dd")
            .format(DateTime(month.year, month.month + 1, 0)),
        "ordering": ordering,
      };
      final query = params.entries
          .map((e) => "${e.key}=${e.value}")
          .join("&");
      final historyResp = await api.get(
        Endpoints.employeeWorkHistoryWithParams(widget.employeeId, query),
      );
      final list = _extractList(historyResp.data);
      setState(() {
        activeShift = activeData;
        history = list;
      });
    } catch (_) {} finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Shift Info"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ActiveShiftCard(data: activeShift, name: widget.employeeName),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              DropdownButton<String>(
                value: sortBy,
                items: const [
                  DropdownMenuItem(value: "newest", child: Text("Newest first")),
                  DropdownMenuItem(value: "oldest", child: Text("Oldest first")),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => sortBy = value);
                  _load();
                },
              ),
              TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: month,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => month = picked);
                    _load();
                  }
                },
                child: Text(DateFormat("MMMM yyyy").format(month)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (loading) const LinearProgressIndicator(minHeight: 2),
          if (!loading && history.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text("No applicant found."),
            ),
          ...history.map((item) => _ShiftHistoryCard(item: item)),
        ],
      ),
    );
  }
}

class _ShiftHistoryCard extends StatelessWidget {
  const _ShiftHistoryCard({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final shift = item["shift_info"] as Map<String, dynamic>? ?? {};
    final date = _formatDate(shift["start_date"] ?? shift["date"]);
    final time =
        "${_formatTime(shift["start_time"])} - ${_formatTime(shift["end_time"])}";
    final title = _stringify(shift["title"]);
    final clockIn = _formatTime(item["clock_in_time"]);
    final clockOut = _formatTime(item["clock_out_time"]);
    final totalHrs = _stringify(item["hours_worked"]);
    final meal = _stringify(_nested(item, ["meal_time", "total_meal_time"]));
    final billable = _stringify(item["billable_hour"]);
    final scheduled = _stringify(item["scheduled_hours"]);
    final extra = _stringify(item["extra_hours"]);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.lightGray),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$date • $time${title.isEmpty ? "" : " | $title"}",
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _pill(context, "Clock In", clockIn),
                _pill(context, "Clock Out", clockOut),
                _pill(context, "Total Hrs", totalHrs),
                _pill(context, "Meal Time", meal),
                _pill(context, "Scheduled", scheduled),
                _pill(context, "Extra", extra),
                _pill(context, "Billable", billable),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(BuildContext context, String label, String value) {
    final display = value.isEmpty ? "-" : value;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.offwhite,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        "$label: $display",
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _ActiveShiftCard extends StatelessWidget {
  const _ActiveShiftCard({required this.data, required this.name});

  final Map<String, dynamic>? data;
  final String name;

  @override
  Widget build(BuildContext context) {
    final shift = data?["active_shift"] as Map<String, dynamic>? ?? {};
    final facility = _stringify(shift["facility_name"] ?? shift["agency_name"]);
    final date = _formatDate(shift["date"]);
    final rate = _stringify(shift["shift_rate"]);
    final clockIn = _formatTime(shift["clock_in_time"]);
    final clockOut = _formatTime(shift["clock_out_time"]);
    final overtime = _stringify(shift["overtime"]);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.offwhite,
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
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _Chip(label: "Active Shift"),
              _Chip(label: facility),
              _Chip(label: date),
              _Chip(label: "Rate: ${rate.isEmpty ? "-" : "\$$rate/hr"}"),
              _Chip(label: "Clock In: ${clockIn.isEmpty ? "-" : clockIn}"),
              _Chip(label: "Clock Out: ${clockOut.isEmpty ? "-" : clockOut}"),
              _Chip(label: "Overtime: ${overtime.isEmpty ? "-" : overtime}"),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

List<Map<String, dynamic>> _extractList(dynamic data) {
  if (data is Map<String, dynamic>) {
    if (data["data"] is List) {
      return (data["data"] as List)
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

String _formatDate(dynamic value) {
  if (value == null) return "N/A";
  if (value is String && value.isNotEmpty) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      return DateFormat("dd MMM yyyy").format(parsed);
    }
    return value;
  }
  return "N/A";
}

String _formatTime(dynamic value) {
  if (value == null) return "";
  if (value is String && value.isNotEmpty) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      return DateFormat("hh:mm a").format(parsed);
    }
    return value;
  }
  return "";
}

String _stringify(dynamic value) {
  if (value == null) return "";
  if (value is String) return value.trim();
  if (value is num) return value.toString();
  return value.toString();
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
