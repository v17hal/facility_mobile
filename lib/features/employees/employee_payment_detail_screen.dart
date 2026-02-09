import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";

import "../../core/network/api_provider.dart";
import "../../core/network/api_service.dart";
import "../../core/network/endpoints.dart";
import "../../core/theme/app_colors.dart";

class EmployeePaymentDetailScreen extends ConsumerStatefulWidget {
  const EmployeePaymentDetailScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  final String employeeId;
  final String employeeName;

  @override
  ConsumerState<EmployeePaymentDetailScreen> createState() =>
      _EmployeePaymentDetailScreenState();
}

class _EmployeePaymentDetailScreenState
    extends ConsumerState<EmployeePaymentDetailScreen> {
  bool loading = false;
  Map<String, dynamic>? activeShift;
  List<Map<String, dynamic>> payDetails = [];
  String payStatus = "PAID";
  String sortOrder = "asc";
  DateTime month = DateTime.now();

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
      final params = {
        "start_date": DateFormat("yyyy-MM-dd")
            .format(DateTime(month.year, month.month, 1)),
        "end_date": DateFormat("yyyy-MM-dd")
            .format(DateTime(month.year, month.month + 1, 0)),
        "pay_status": payStatus,
        "ordering": sortOrder,
      };
      final payResp = await api.get(
        Endpoints.employeePayDetails(widget.employeeId),
        params: params,
      );
      final list = _extractList(payResp.data);
      setState(() {
        activeShift = activeData;
        payDetails = list;
      });
    } catch (_) {} finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment Information"),
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
                value: payStatus,
                items: const [
                  DropdownMenuItem(value: "PAID", child: Text("Paid")),
                  DropdownMenuItem(value: "UNPAID", child: Text("Unpaid")),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => payStatus = value);
                  _load();
                },
              ),
              DropdownButton<String>(
                value: sortOrder,
                items: const [
                  DropdownMenuItem(value: "asc", child: Text("Newest First")),
                  DropdownMenuItem(value: "desc", child: Text("Oldest First")),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => sortOrder = value);
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
          if (!loading && payDetails.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text("No data found."),
            ),
          ...payDetails.map((item) {
            final date = _formatDate(item["date"] ?? item["created_at"]);
            final total = _stringify(item["total_amount"] ?? item["amount"]);
            final status = _stringify(item["pay_status"] ?? payStatus);
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
                    Row(
                      children: [
                        Text(
                          "Payment",
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Text(
                          date,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.greyBlue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _pill(status),
                        const Spacer(),
                        Text(
                          "\$$total",
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: AppColors.primary),
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

Widget _pill(String text) {
  final value = text.isEmpty ? "N/A" : text;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.lightPink,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      value,
      style: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
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
