import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/network/api_provider.dart";
import "../../core/network/api_service.dart";
import "../../core/network/endpoints.dart";
import "../../core/theme/app_colors.dart";

class DailyActionListScreen extends ConsumerStatefulWidget {
  const DailyActionListScreen({
    super.key,
    required this.title,
    required this.endpoint,
    this.params,
    this.emptyLabel,
  });

  final String title;
  final String endpoint;
  final Map<String, dynamic>? params;
  final String? emptyLabel;

  @override
  ConsumerState<DailyActionListScreen> createState() =>
      _DailyActionListScreenState();
}

class _DailyActionListScreenState extends ConsumerState<DailyActionListScreen> {
  bool loading = false;
  List<Map<String, dynamic>> items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final api = ApiService(ref.read(apiClientProvider));
      final resp = await api.get(widget.endpoint, params: widget.params);
      final list = _extractList(resp.data);
      setState(() => items = list);
    } catch (_) {
      setState(() => items = const []);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? Center(child: Text(widget.emptyLabel ?? "No data found"))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final title = _titleForItem(item);
                    final subtitle = _subtitleForItem(item);
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
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.greyBlue),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

class DailyPeopleWorkingScreen extends ConsumerStatefulWidget {
  const DailyPeopleWorkingScreen({
    super.key,
    required this.date,
  });

  final DateTime date;

  @override
  ConsumerState<DailyPeopleWorkingScreen> createState() =>
      _DailyPeopleWorkingScreenState();
}

class _DailyPeopleWorkingScreenState
    extends ConsumerState<DailyPeopleWorkingScreen> {
  bool loading = false;
  List<Map<String, dynamic>> shifts = const [];
  List<Map<String, dynamic>> offSchedule = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final api = ApiService(ref.read(apiClientProvider));
      final dateStr = _formatDate(widget.date);
      final shiftResp =
          await api.get(Endpoints.dailyScheduleShiftList(dateStr));
      final shiftList = _extractList(shiftResp.data);
      final offResp = await api.get(
        Endpoints.dailyScheduleOffSchedule(dateStr),
      );
      final offList = _extractList(offResp.data);
      setState(() {
        shifts = shiftList;
        offSchedule = offList;
      });
    } catch (_) {
      setState(() {
        shifts = const [];
        offSchedule = const [];
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workingCount = shifts.where((shift) {
      final accepted = shift["accepted_employee"];
      if (accepted is! Map) return false;
      return accepted["clock_in"] == true && accepted["clock_out"] != true;
    }).length;

    return Scaffold(
      appBar: AppBar(title: const Text("People Working")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _InfoHeader(
                  title: "Working Now",
                  value: "${workingCount + offSchedule.length}",
                ),
                const SizedBox(height: 12),
                _SectionTitle("On Schedule"),
                const SizedBox(height: 8),
                if (shifts.isEmpty)
                  const Text("No scheduled staff")
                else
                  ...shifts.map((shift) {
                    final name = shift["title"]?.toString() ?? "Shift";
                    final employee =
                        shift["accepted_employee"]?["name"]?.toString() ?? "";
                    final time = _timeRange(
                      shift["start_time"]?.toString(),
                      shift["end_time"]?.toString(),
                    );
                    return _RowCard(
                      title: name,
                      subtitle: [employee, time]
                          .where((e) => e.isNotEmpty)
                          .join(" - "),
                    );
                  }),
                const SizedBox(height: 16),
                _SectionTitle("Off Schedule"),
                const SizedBox(height: 8),
                if (offSchedule.isEmpty)
                  const Text("No off-schedule staff")
                else
                  ...offSchedule.map((item) {
                    final name =
                        item["employee_name"]?.toString() ??
                        item["name"]?.toString() ??
                        "Employee";
                    final role =
                        item["job_title"]?.toString() ??
                        item["position"]?.toString() ??
                        "";
                    return _RowCard(
                      title: name,
                      subtitle: role,
                    );
                  }),
              ],
            ),
    );
  }
}

class DailyScorecardScreen extends ConsumerStatefulWidget {
  const DailyScorecardScreen({
    super.key,
    required this.date,
    required this.departments,
  });

  final DateTime date;
  final List<Map<String, dynamic>> departments;

  @override
  ConsumerState<DailyScorecardScreen> createState() =>
      _DailyScorecardScreenState();
}

class _DailyScorecardScreenState extends ConsumerState<DailyScorecardScreen> {
  bool loading = false;
  Map<String, dynamic> data = const {};
  String? selectedDepartmentId;

  @override
  void initState() {
    super.initState();
    if (widget.departments.isNotEmpty) {
      selectedDepartmentId = widget.departments.first["id"]?.toString();
      _load();
    }
  }

  Future<void> _load() async {
    if (selectedDepartmentId == null) return;
    setState(() => loading = true);
    try {
      final api = ApiService(ref.read(apiClientProvider));
      final params = "department_id=$selectedDepartmentId";
      final resp = await api.get(Endpoints.dailyScheduleHppdData(params));
      final map = resp.data is Map<String, dynamic>
          ? Map<String, dynamic>.from(resp.data)
          : <String, dynamic>{};
      setState(() => data = map["data"] as Map<String, dynamic>? ?? map);
    } catch (_) {
      setState(() => data = const {});
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final header = data["name"]?.toString() ?? "Scorecard";
    final today = (data["time_range_data"]?["today"] as Map?) ?? {};
    final scheduled = today["scheduled_hours"] ?? 0;
    final actual = today["actual_hours"] ?? 0;
    final target = today["target"] ?? 0;
    final census = today["census"] ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text("Scorecard")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              onChanged: (value) {
                setState(() => selectedDepartmentId = value);
                _load();
              },
              decoration: const InputDecoration(
                labelText: "Department",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (loading)
              const LinearProgressIndicator(minHeight: 2)
            else ...[
              Text(
                header,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              _ScoreRow(label: "Scheduled Hours", value: "$scheduled"),
              _ScoreRow(label: "Actual Hours", value: "$actual"),
              _ScoreRow(label: "Target HPPD", value: "$target"),
              _ScoreRow(label: "Census", value: "$census"),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.label, required this.value});
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

class _InfoHeader extends StatelessWidget {
  const _InfoHeader({required this.title, required this.value});
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
          Expanded(child: Text(title)),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .labelLarge
          ?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _RowCard extends StatelessWidget {
  const _RowCard({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.greyBlue),
            ),
          ],
        ],
      ),
    );
  }
}

String _titleForItem(Map<String, dynamic> item) {
  return item["title"]?.toString() ??
      item["name"]?.toString() ??
      item["employee_name"]?.toString() ??
      "Item";
}

String _subtitleForItem(Map<String, dynamic> item) {
  final parts = <String>[];
  final time = _timeRange(
    item["start_time"]?.toString(),
    item["end_time"]?.toString(),
  );
  if (time.isNotEmpty) parts.add(time);
  final status = item["status"]?.toString();
  if (status != null && status.isNotEmpty) parts.add(status);
  final dept = item["department"]?["name"]?.toString() ??
      item["department_name"]?.toString();
  if (dept != null && dept.isNotEmpty) parts.add(dept);
  return parts.join(" - ");
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
  return const [];
}

String _formatDate(DateTime date) {
  final mm = date.month.toString().padLeft(2, "0");
  final dd = date.day.toString().padLeft(2, "0");
  return "${date.year}-$mm-$dd";
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
