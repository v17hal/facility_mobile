import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/network/api_provider.dart";
import "../../core/network/api_service.dart";
import "../../core/network/endpoints.dart";

final scheduleBuilderControllerProvider =
    StateNotifierProvider<ScheduleBuilderController, ScheduleBuilderState>((ref) {
  final api = ApiService(ref.watch(apiClientProvider));
  return ScheduleBuilderController(api);
});

class ScheduleBuilderState {
  const ScheduleBuilderState({
    this.loading = false,
    this.shiftLoading = false,
    this.dataList = const [],
    this.selectedDepartmentId,
    this.selectedShiftId,
    this.selectedDepartment,
    this.selectedShift,
    this.departments = const [],
    this.units = const [],
    this.jobTitles = const [],
    this.colors = const [],
    this.actionLoading = false,
    this.stats = const {
      "total_templates": 0,
      "total_openings": 0,
      "required_shifts": 0,
      "optional_shifts": 0,
    },
  });

  final bool loading;
  final bool shiftLoading;
  final List<Map<String, dynamic>> dataList;
  final String? selectedDepartmentId;
  final String? selectedShiftId;
  final Map<String, dynamic>? selectedDepartment;
  final Map<String, dynamic>? selectedShift;
  final List<Map<String, dynamic>> departments;
  final List<Map<String, dynamic>> units;
  final List<Map<String, dynamic>> jobTitles;
  final List<Map<String, dynamic>> colors;
  final bool actionLoading;
  final Map<String, dynamic> stats;

  ScheduleBuilderState copyWith({
    bool? loading,
    bool? shiftLoading,
    List<Map<String, dynamic>>? dataList,
    String? selectedDepartmentId,
    String? selectedShiftId,
    Map<String, dynamic>? selectedDepartment,
    Map<String, dynamic>? selectedShift,
    List<Map<String, dynamic>>? departments,
    List<Map<String, dynamic>>? units,
    List<Map<String, dynamic>>? jobTitles,
    List<Map<String, dynamic>>? colors,
    bool? actionLoading,
    Map<String, dynamic>? stats,
  }) {
    return ScheduleBuilderState(
      loading: loading ?? this.loading,
      shiftLoading: shiftLoading ?? this.shiftLoading,
      dataList: dataList ?? this.dataList,
      selectedDepartmentId: selectedDepartmentId ?? this.selectedDepartmentId,
      selectedShiftId: selectedShiftId ?? this.selectedShiftId,
      selectedDepartment: selectedDepartment ?? this.selectedDepartment,
      selectedShift: selectedShift ?? this.selectedShift,
      departments: departments ?? this.departments,
      units: units ?? this.units,
      jobTitles: jobTitles ?? this.jobTitles,
      colors: colors ?? this.colors,
      actionLoading: actionLoading ?? this.actionLoading,
      stats: stats ?? this.stats,
    );
  }
}

class ScheduleBuilderController extends StateNotifier<ScheduleBuilderState> {
  ScheduleBuilderController(this._api) : super(const ScheduleBuilderState()) {
    _loadLookups();
    fetchScheduleList();
  }

  final ApiService _api;

  Future<void> _loadLookups() async {
    await Future.wait([
      _loadDepartments(),
      _loadUnits(),
      _loadJobTitles(),
      _loadColors(),
    ]);
  }

  Future<void> _loadDepartments() async {
    try {
      final resp = await _api.get(Endpoints.fetchDepartments);
      final list = _extractList(resp.data);
      final mapped = list
          .whereType<Map>()
          .map((e) => {
                "id": e["id"]?.toString() ?? "",
                "name": e["name"]?.toString() ?? "",
              })
          .cast<Map<String, dynamic>>()
          .toList();
      state = state.copyWith(departments: mapped);
    } catch (_) {}
  }

  Future<void> _loadUnits() async {
    try {
      final resp = await _api.get("facilities/unit-subunit/");
      final list = _extractList(resp.data);
      final mapped = list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      state = state.copyWith(units: mapped);
    } catch (_) {}
  }

  Future<void> _loadJobTitles() async {
    try {
      final resp = await _api.get("common/job-titles");
      final list = _extractList(resp.data);
      final mapped = list
          .whereType<Map>()
          .map((e) => {
                "id": e["id"]?.toString() ?? "",
                "name": e["name"]?.toString() ?? "",
                "abbreviation": e["abbreviation"]?.toString() ?? "",
              })
          .cast<Map<String, dynamic>>()
          .toList();
      state = state.copyWith(jobTitles: mapped);
    } catch (_) {}
  }

  Future<void> _loadColors() async {
    try {
      final resp = await _api.get("common/color", params: {"is_active": true});
      final list = _extractList(resp.data);
      final mapped = list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      state = state.copyWith(colors: mapped);
    } catch (_) {}
  }

  Future<void> fetchScheduleList() async {
    state = state.copyWith(loading: true);
    try {
      final resp = await _api.get(Endpoints.fetchSchedulesList);
      final list = _extractList(resp.data);
      final processed = _processListData(list);
      final stats = _computeStats(processed);
      final selectedDept = processed.length > 1 ? processed[1] : processed.first;
      final selectedDeptId = selectedDept["department"]["id"].toString();
      final selectedShiftId =
          (selectedDept["shifts"] as List).isNotEmpty
              ? (selectedDept["shifts"] as List).first["id"].toString()
              : null;
      state = state.copyWith(
        dataList: processed,
        selectedDepartment: selectedDept,
        selectedDepartmentId: selectedDeptId,
        selectedShiftId: selectedShiftId,
        stats: stats,
        loading: false,
      );
      if (selectedShiftId != null) {
        await fetchShift(selectedShiftId);
      }
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  void selectDepartment(String departmentId) {
    final dept = state.dataList.firstWhere(
      (d) => d["department"]["id"].toString() == departmentId,
      orElse: () => state.dataList.first,
    );
    final shifts = dept["shifts"] as List? ?? [];
    final shiftId = shifts.isNotEmpty ? shifts.first["id"].toString() : null;
    state = state.copyWith(
      selectedDepartmentId: departmentId,
      selectedDepartment: dept,
      selectedShiftId: shiftId,
      selectedShift: null,
    );
    if (shiftId != null) {
      fetchShift(shiftId);
    }
  }

  void selectShift(String shiftId) {
    state = state.copyWith(selectedShiftId: shiftId);
    fetchShift(shiftId);
  }

  Future<void> fetchShift(String shiftId) async {
    state = state.copyWith(shiftLoading: true);
    try {
      final resp = await _api.get("${Endpoints.fetchSchedulesList}$shiftId/");
      final data = _extractMap(resp.data);
      state = state.copyWith(selectedShift: data, shiftLoading: false);
    } catch (_) {
      state = state.copyWith(shiftLoading: false);
    }
  }

  Future<void> createShift(Map<String, dynamic> payload) async {
    state = state.copyWith(actionLoading: true);
    try {
      await _api.post(Endpoints.fetchSchedulesList, data: payload);
      await fetchScheduleList();
      state = state.copyWith(actionLoading: false);
    } catch (_) {
      state = state.copyWith(actionLoading: false);
    }
  }

  Future<void> updateShift(String shiftId, Map<String, dynamic> payload) async {
    state = state.copyWith(actionLoading: true);
    try {
      await _api.patch("${Endpoints.fetchSchedulesList}$shiftId/", data: payload);
      await fetchScheduleList();
      state = state.copyWith(actionLoading: false);
    } catch (_) {
      state = state.copyWith(actionLoading: false);
    }
  }

  Future<void> deleteShift(String shiftId) async {
    state = state.copyWith(actionLoading: true);
    try {
      await _api.post(Endpoints.deleteOpening, data: {
        "opening_ids": [shiftId],
      });
      await fetchScheduleList();
      state = state.copyWith(actionLoading: false);
    } catch (_) {
      state = state.copyWith(actionLoading: false);
    }
  }

  Future<bool> mergeOpenings(List<String> openingIds) async {
    if (openingIds.length < 2) return false;
    state = state.copyWith(actionLoading: true);
    try {
      await _api.post(Endpoints.mergeOpenings, data: {
        "opening_ids": openingIds,
      });
      await fetchScheduleList();
      state = state.copyWith(actionLoading: false);
      return true;
    } catch (_) {
      state = state.copyWith(actionLoading: false);
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchJobTitleConflicts(
    String openingId,
  ) async {
    try {
      final resp =
          await _api.get("${Endpoints.scheduleBuilderJobTitleConflict}/$openingId");
      final list = _extractList(resp.data);
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

List<dynamic> _extractList(dynamic data) {
  if (data is Map<String, dynamic>) {
    if (data["data"] is List) return data["data"] as List;
    if (data["results"] is List) return data["results"] as List;
  }
  if (data is List) return data;
  return [];
}

Map<String, dynamic> _extractMap(dynamic data) {
  if (data is Map<String, dynamic>) {
    if (data["data"] is Map<String, dynamic>) {
      return Map<String, dynamic>.from(data["data"]);
    }
    return Map<String, dynamic>.from(data);
  }
  return {};
}

List<Map<String, dynamic>> _processListData(List<dynamic> data) {
  final map = <String, Map<String, dynamic>>{};
  for (final item in data) {
    if (item is! Map) continue;
    final dept = item["department"] ?? {};
    final deptId = dept["id"]?.toString();
    final deptName = dept["name"]?.toString();
    if (deptId == null) continue;
    map.putIfAbsent(deptId, () {
      return {
        "department": {"id": deptId, "name": deptName},
        "shifts": <Map<String, dynamic>>[],
      };
    });
    map[deptId]!["shifts"].add(Map<String, dynamic>.from(item));
  }
  final departments = map.values.toList();
  return [
    {
      "department": {"id": "all", "name": "All Departments"},
      "shifts": departments.expand((d) => d["shifts"] as List).toList(),
    },
    ...departments,
  ];
}

Map<String, dynamic> _computeStats(List<Map<String, dynamic>> dataList) {
  if (dataList.isEmpty) {
    return {
      "total_templates": 0,
      "total_openings": 0,
      "required_shifts": 0,
      "optional_shifts": 0,
    };
  }
  final allDept =
      dataList.firstWhere((d) => d["department"]["id"] == "all");
  final shifts = allDept["shifts"] as List;
  final totalTemplates = shifts.length;
  final totalOpenings = shifts.fold<int>(
    0,
    (sum, s) => sum + ((s["no_of_child_openings"] ?? 0) as int),
  );
  final required = shifts
      .where((s) => (s["is_optional"] ?? false) == false)
      .length;
  final optional = shifts
      .where((s) => (s["is_optional"] ?? false) == true)
      .length;
  return {
    "total_templates": totalTemplates,
    "total_openings": totalOpenings,
    "required_shifts": required,
    "optional_shifts": optional,
  };
}
