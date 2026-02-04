
import "dart:convert";

import "package:dio/dio.dart";
import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/network/api_provider.dart";
import "../../core/network/api_service.dart";
import "../../core/network/endpoints.dart";
import "../../core/storage/secure_store.dart";
import "../../core/storage/storage_keys.dart";

final dailyScheduleControllerProvider =
    StateNotifierProvider<DailyScheduleController, DailyScheduleState>((ref) {
  final api = ApiService(ref.watch(apiClientProvider));
  final store = ref.watch(secureStoreProvider);
  return DailyScheduleController(api, store);
});

class DailyScheduleState {
  const DailyScheduleState({
    required this.date,
    this.facilities = const [],
    this.selectedFacilityId,
    this.selectedFacilityName,
    this.loading = false,
    this.shiftsLoading = false,
    this.openingsLoading = false,
    this.detailsLoading = false,
    this.applicantsLoading = false,
    this.employeesLoading = false,
    this.actionLoading = false,
    this.actionError,
    this.statsData = const {},
    this.departments = const [],
    this.jobTitles = const [],
    this.units = const [],
    this.colors = const [],
    this.selectedDepartmentId,
    this.shifts = const [],
    this.selectedShiftId,
    this.openings = const [],
    this.selectedOpening,
    this.selectedLayerId,
    this.selectedScheduleShiftId,
    this.applicants = const [],
    this.employees = const [],
    this.selectedEmployees = const [],
    this.employeeSearch = "",
    this.applicantSearch = "",
    this.employeeSelection = "recommended",
  });

  final DateTime date;
  final List<Map<String, dynamic>> facilities;
  final String? selectedFacilityId;
  final String? selectedFacilityName;
  final bool loading;
  final bool shiftsLoading;
  final bool openingsLoading;
  final bool detailsLoading;
  final bool applicantsLoading;
  final bool employeesLoading;
  final bool actionLoading;
  final String? actionError;
  final Map<String, dynamic> statsData;
  final List<Map<String, dynamic>> departments;
  final List<Map<String, dynamic>> jobTitles;
  final List<Map<String, dynamic>> units;
  final List<Map<String, dynamic>> colors;
  final String? selectedDepartmentId;
  final List<Map<String, dynamic>> shifts;
  final String? selectedShiftId;
  final List<Map<String, dynamic>> openings;
  final Map<String, dynamic>? selectedOpening;
  final String? selectedLayerId;
  final String? selectedScheduleShiftId;
  final List<Map<String, dynamic>> applicants;
  final List<Map<String, dynamic>> employees;
  final List<Map<String, dynamic>> selectedEmployees;
  final String employeeSearch;
  final String applicantSearch;
  final String employeeSelection;

  DailyScheduleState copyWith({
    DateTime? date,
    List<Map<String, dynamic>>? facilities,
    String? selectedFacilityId,
    String? selectedFacilityName,
    bool? loading,
    bool? shiftsLoading,
    bool? openingsLoading,
    bool? detailsLoading,
    bool? applicantsLoading,
    bool? employeesLoading,
    bool? actionLoading,
    String? actionError,
    Map<String, dynamic>? statsData,
    List<Map<String, dynamic>>? departments,
    List<Map<String, dynamic>>? jobTitles,
    List<Map<String, dynamic>>? units,
    List<Map<String, dynamic>>? colors,
    String? selectedDepartmentId,
    List<Map<String, dynamic>>? shifts,
    String? selectedShiftId,
    List<Map<String, dynamic>>? openings,
    Map<String, dynamic>? selectedOpening,
    String? selectedLayerId,
    String? selectedScheduleShiftId,
    List<Map<String, dynamic>>? applicants,
    List<Map<String, dynamic>>? employees,
    List<Map<String, dynamic>>? selectedEmployees,
    String? employeeSearch,
    String? applicantSearch,
    String? employeeSelection,
  }) {
    return DailyScheduleState(
      date: date ?? this.date,
      facilities: facilities ?? this.facilities,
      selectedFacilityId: selectedFacilityId ?? this.selectedFacilityId,
      selectedFacilityName: selectedFacilityName ?? this.selectedFacilityName,
      loading: loading ?? this.loading,
      shiftsLoading: shiftsLoading ?? this.shiftsLoading,
      openingsLoading: openingsLoading ?? this.openingsLoading,
      detailsLoading: detailsLoading ?? this.detailsLoading,
      applicantsLoading: applicantsLoading ?? this.applicantsLoading,
      employeesLoading: employeesLoading ?? this.employeesLoading,
      actionLoading: actionLoading ?? this.actionLoading,
      actionError: actionError,
      statsData: statsData ?? this.statsData,
      departments: departments ?? this.departments,
      jobTitles: jobTitles ?? this.jobTitles,
      units: units ?? this.units,
      colors: colors ?? this.colors,
      selectedDepartmentId: selectedDepartmentId ?? this.selectedDepartmentId,
      shifts: shifts ?? this.shifts,
      selectedShiftId: selectedShiftId ?? this.selectedShiftId,
      openings: openings ?? this.openings,
      selectedOpening: selectedOpening ?? this.selectedOpening,
      selectedLayerId: selectedLayerId ?? this.selectedLayerId,
      selectedScheduleShiftId:
          selectedScheduleShiftId ?? this.selectedScheduleShiftId,
      applicants: applicants ?? this.applicants,
      employees: employees ?? this.employees,
      selectedEmployees: selectedEmployees ?? this.selectedEmployees,
      employeeSearch: employeeSearch ?? this.employeeSearch,
      applicantSearch: applicantSearch ?? this.applicantSearch,
      employeeSelection: employeeSelection ?? this.employeeSelection,
    );
  }
}

class DailyScheduleController extends StateNotifier<DailyScheduleState> {
  DailyScheduleController(this._api, this._store)
      : super(DailyScheduleState(date: DateTime.now())) {
    _loadLookups();
    _loadFacilities();
    fetchStats();
    fetchShifts();
    fetchOpenings();
  }

  final ApiService _api;
  final SecureStore _store;


  Future<void> _loadFacilities() async {
    try {
      final resp = await _api.get("owner/facility/list");
      final list = _extractList(resp.data);
      final mapped = list
          .whereType<Map>()
          .map((e) => {
                "id": e["id"]?.toString(),
                "name": e["name"]?.toString() ?? "",
              })
          .cast<Map<String, dynamic>>()
          .toList();

      final currentId = await _store.read(StorageKeys.facilityId);
      final currentName = await _store.read(StorageKeys.facilityName);

      String? selectedId = currentId;
      String? selectedName = currentName;

      if ((selectedId == null || selectedId.isEmpty) && mapped.isNotEmpty) {
        selectedId = mapped.first["id"]?.toString();
        selectedName = mapped.first["name"]?.toString();
        if (selectedId != null) {
          await _store.write(StorageKeys.facilityId, selectedId);
        }
        if (selectedName != null) {
          await _store.write(StorageKeys.facilityName, selectedName);
        }
      }

      state = state.copyWith(
        facilities: mapped,
        selectedFacilityId: selectedId,
        selectedFacilityName: selectedName,
      );

      fetchStats();
      fetchShifts();
      fetchOpenings();
    } catch (_) {}
  }

  Future<void> _loadLookups() async {
    await Future.wait([
      _loadDepartments(),
      _loadJobTitles(),
      _loadUnits(),
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

  Future<void> _loadJobTitles() async {
    try {
      final resp = await _api.get(Endpoints.jobTitles);
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

  Future<void> selectFacility(String id, String name) async {
    await _store.write(StorageKeys.facilityId, id);
    await _store.write(StorageKeys.facilityName, name);
    state = state.copyWith(selectedFacilityId: id, selectedFacilityName: name);
    fetchStats();
    fetchShifts();
    fetchOpenings();
  }

  void setDate(DateTime date) {
    state = state.copyWith(
      date: date,
      selectedShiftId: null,
      selectedOpening: null,
      selectedLayerId: null,
      selectedScheduleShiftId: null,
      applicants: const [],
      employees: const [],
      selectedEmployees: const [],
    );
    fetchStats();
    fetchShifts();
    fetchOpenings();
  }

  void setDepartment(String? id) {
    state = state.copyWith(
      selectedDepartmentId: id,
      selectedOpening: null,
      selectedLayerId: null,
      selectedScheduleShiftId: null,
      applicants: const [],
      employees: const [],
      selectedEmployees: const [],
    );
  }

  void setShift(String? id) {
    state = state.copyWith(selectedShiftId: id);
  }

  void setApplicantSearch(String value) {
    state = state.copyWith(applicantSearch: value);
    fetchApplicants();
  }

  void setEmployeeSearch(String value) {
    state = state.copyWith(employeeSearch: value);
    fetchEmployees();
  }

  void setEmployeeSelection(String value) {
    state = state.copyWith(employeeSelection: value);
    fetchEmployees();
  }

  Future<void> fetchStats() async {
    state = state.copyWith(loading: true);
    try {
      final params = {
        "date": _formatDate(state.date),
      };
      final resp = await _api.get(
        "facilities/census-v2/stats/",
        params: params,
      );
      final raw = resp.data is Map<String, dynamic>
          ? (resp.data["data"] as Map? ?? {})
          : {};
      final data = Map<String, dynamic>.from(raw);
      state = state.copyWith(statsData: data, loading: false);
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> fetchShifts() async {
    state = state.copyWith(shiftsLoading: true);
    try {
      final dateStr = _formatDate(state.date);
      final resp = await _api.get(Endpoints.dailyScheduleShiftList(dateStr));
      final data = resp.data is Map<String, dynamic>
          ? Map<String, dynamic>.from(resp.data)
          : <String, dynamic>{};
      final previous = (data["previous"] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final current = (data["current"] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final merged = [
        ...previous.map((e) => {...e, "bucket": "previous"}),
        ...current.map((e) => {...e, "bucket": "current"}),
      ];
      state = state.copyWith(shifts: merged, shiftsLoading: false);
    } catch (_) {
      state = state.copyWith(shiftsLoading: false);
    }
  }

  Future<void> fetchOpenings() async {
    state = state.copyWith(openingsLoading: true);
    try {
      final params = <String, dynamic>{
        "date": _formatDate(state.date),
      };
      final resp = await _api.get(
        Endpoints.dailyScheduleOpenings,
        params: params,
      );
      final data = resp.data is Map<String, dynamic>
          ? Map<String, dynamic>.from(resp.data)
          : <String, dynamic>{};
      final list = _extractList(data);
      final openings = list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      Map<String, dynamic>? selected = state.selectedOpening;
      if (selected == null && openings.isNotEmpty) {
        selected = openings.first;
      } else if (selected != null) {
        final id = _openingId(selected);
        selected = openings.firstWhere(
          (o) => _openingId(o) == id,
          orElse: () => openings.isNotEmpty ? openings.first : selected!,
        );
      }

      state = state.copyWith(
        openings: openings,
        selectedOpening: selected,
        openingsLoading: false,
      );

      if (selected != null) {
        _ensureSelectionFromOpening(selected, refreshLists: true);
      }
    } catch (_) {
      state = state.copyWith(openingsLoading: false);
    }
  }

  void selectOpening(Map<String, dynamic> opening) {
    state = state.copyWith(
      selectedOpening: opening,
      applicants: const [],
      employees: const [],
      selectedEmployees: const [],
    );
    _ensureSelectionFromOpening(opening, refreshLists: true);
  }

  void selectLayer(String id) {
    state = state.copyWith(selectedLayerId: id);
    _syncShiftForLayer();
    fetchApplicants();
    fetchEmployees();
  }

  void selectScheduleShift(String shiftId) {
    state = state.copyWith(selectedScheduleShiftId: shiftId);
    fetchApplicants();
    fetchEmployees();
  }

  void toggleEmployee(Map<String, dynamic> employee) {
    final id = employee["id"]?.toString();
    if (id == null) return;
    final current = [...state.selectedEmployees];
    final exists = current.indexWhere((e) => e["id"]?.toString() == id);
    if (exists >= 0) {
      current.removeAt(exists);
    } else {
      current.add(employee);
    }
    state = state.copyWith(selectedEmployees: current);
  }

  void clearSelectedEmployees() {
    state = state.copyWith(selectedEmployees: const []);
  }

  Future<void> fetchApplicants() async {
    final shiftId = _assignShiftId(state.selectedOpening, state.selectedScheduleShiftId);
    final opening = state.selectedOpening;
    if (shiftId == null || opening == null || shiftId.isEmpty) return;

    state = state.copyWith(applicantsLoading: true);
    try {
      final params = <String, dynamic>{
        "opening_daily_id": _openingId(opening),
        "opening_layer_daily_id": state.selectedLayerId,
        if (state.applicantSearch.isNotEmpty)
          "search": state.applicantSearch,
      };
      final resp = await _api.get(
        Endpoints.dailyScheduleApplicants(shiftId),
        params: params,
      );
      final data = resp.data is Map<String, dynamic>
          ? Map<String, dynamic>.from(resp.data)
          : <String, dynamic>{};
      final list = _extractList(data);
      final mapped = list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      state = state.copyWith(applicants: mapped, applicantsLoading: false);
    } catch (_) {
      state = state.copyWith(applicantsLoading: false);
    }
  }

  Future<void> fetchEmployees() async {
    final shiftId = _assignShiftId(state.selectedOpening, state.selectedScheduleShiftId);
    final opening = state.selectedOpening;
    if (shiftId == null || opening == null || shiftId.isEmpty) return;

    state = state.copyWith(employeesLoading: true);
    try {
      final params = <String, dynamic>{
        "page": 1,
        "page_size": 50,
        if (state.employeeSearch.isNotEmpty)
          "search": state.employeeSearch,
      };
      final jobTitles = _jobTitleIdsForOpening(opening);
      if (jobTitles.isNotEmpty) {
        params["position_id"] = jobTitles;
      }
      final resp = await _api.get(
        Endpoints.dailyScheduleAvailableEmployees(shiftId),
        params: params,
      );
      final data = resp.data is Map<String, dynamic>
          ? Map<String, dynamic>.from(resp.data)
          : <String, dynamic>{};
      final list = _extractList(data);
      final mapped = list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      state = state.copyWith(employees: mapped, employeesLoading: false);
    } catch (_) {
      state = state.copyWith(employeesLoading: false);
    }
  }

  Future<bool> ensureJobTitleOnOpening(String jobTitleId) async {
    final opening = state.selectedOpening;
    if (opening == null) return false;
    final existing = (opening["job_titles"] as List?)
            ?.whereType<Map>()
            .map((e) => e["id"]?.toString())
            .whereType<String>()
            .toList() ??
        [];
    if (existing.contains(jobTitleId)) return true;

    try {
      final updated = [...existing, jobTitleId];
      await _api.patch(
        Endpoints.dailyScheduleUpdateOpening(_openingId(opening)),
        data: {"job_titles": updated},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> assignEmployees({
    String? overrideJobTitleId,
    List<Map<String, dynamic>>? employees,
  }) async {
    final shiftId = _assignShiftId(state.selectedOpening, state.selectedScheduleShiftId);
    final opening = state.selectedOpening;
    if (opening == null) {
      state = state.copyWith(actionError: "Missing opening data");
      print("Assign aborted: opening is null");
      return false;
    }
    if (shiftId == null || shiftId.isEmpty) {
      state = state.copyWith(actionError: "Missing schedule shift id");
      print("Assign aborted: schedule shift id is null/empty");
      return false;
    }
    final selected = employees ?? state.selectedEmployees;
    if (selected.isEmpty) {
      state = state.copyWith(actionError: "No employee selected");
      print("Assign aborted: no employees selected");
      return false;
    }

    state = state.copyWith(actionLoading: true, actionError: null);
    try {
      final openingId = _openingId(opening);
      final layerId = state.selectedLayerId;
      final jobTitleId = overrideJobTitleId ??
          selected.first["job_title_id"]?.toString() ??
          _firstJobTitleId(opening);
      if (openingId.isEmpty) {
        state = state.copyWith(actionLoading: false, actionError: "Missing opening_daily_id");
        print("Assign aborted: opening_daily_id is empty");
        return false;
      }
      if (jobTitleId == null || jobTitleId.isEmpty) {
        state = state.copyWith(actionLoading: false, actionError: "Missing job title");
        print("Assign aborted: job title is empty");
        return false;
      }

      final nurses = selected.map((e) {
        final empJobTitle =
            overrideJobTitleId ?? e["job_title_id"]?.toString();
        return {
          "id": e["id"],
          "job_title_id": empJobTitle,
        };
      }).toList();

      final payload = {
        "nurses": nurses,
        "opening_layer_daily_id": layerId ?? "",
        "opening_daily_id": openingId,
        "position": jobTitleId,
        "is_backup": false,
      };

      print("Assign endpoint: ${Endpoints.dailyScheduleAssignEmployees(shiftId)}");
      print("Assign payload: ${_stringifyData(payload)}");

      await _api.patch(
        Endpoints.dailyScheduleAssignEmployees(shiftId),
        data: payload,
      );

      state = state.copyWith(
        actionLoading: false,
        selectedEmployees: const [],
        actionError: null,
      );
      await fetchOpenings();
      await fetchApplicants();
      await fetchEmployees();
      return true;
    } catch (e) {
      final message = _errorMessage(e) ?? e.toString();
      state = state.copyWith(actionLoading: false, actionError: message);
      debugPrint("Assign employees failed: $message");
      return false;
    }
  }

  Future<bool> createOpening(Map<String, dynamic> payload) async {
    state = state.copyWith(actionLoading: true);
    try {
      await _api.post(Endpoints.dailyScheduleOpenings, data: payload);
      state = state.copyWith(actionLoading: false);
      await fetchOpenings();
      return true;
    } catch (_) {
      state = state.copyWith(actionLoading: false);
      return false;
    }
  }

  Future<bool> updateOpening(String openingId, Map<String, dynamic> payload) async {
    state = state.copyWith(actionLoading: true);
    try {
      await _api.patch(
        Endpoints.dailyScheduleUpdateOpening(openingId),
        data: payload,
      );
      state = state.copyWith(actionLoading: false);
      await fetchOpenings();
      return true;
    } catch (_) {
      state = state.copyWith(actionLoading: false);
      return false;
    }
  }

  Future<bool> deleteOpening(String openingId) async {
    state = state.copyWith(actionLoading: true);
    try {
      await _api.delete(Endpoints.dailyScheduleUpdateOpening(openingId));
      state = state.copyWith(actionLoading: false);
      await fetchOpenings();
      return true;
    } catch (e) {
      final message = _errorMessage(e) ?? "Delete failed";
      state = state.copyWith(actionLoading: false, actionError: message);
      debugPrint("Delete opening failed: $message");
      return false;
    }
  }

  Future<bool> unassignApplicant({
    required String openingDailyId,
    required String applicantId,
  }) async {
    if (openingDailyId.isEmpty || applicantId.isEmpty) return false;
    state = state.copyWith(actionLoading: true, actionError: null);
    try {
      debugPrint(
        "Unassign endpoint: ${Endpoints.dailyScheduleUnassignApplicant(openingDailyId, applicantId)}",
      );
      await _api.patch(
        Endpoints.dailyScheduleUnassignApplicant(openingDailyId, applicantId),
        data: {"status": "UNASSIGNED"},
      );
      state = state.copyWith(actionLoading: false, actionError: null);
      await fetchOpenings();
      await fetchApplicants();
      await fetchEmployees();
      return true;
    } catch (e) {
      final message = _errorMessage(e) ?? e.toString();
      state = state.copyWith(actionLoading: false, actionError: message);
      debugPrint("Unassign failed: $message");
      return false;
    }
  }

  Future<bool> resetApplicants() async {
    state = state.copyWith(actionLoading: true);
    try {
      await _api.post(
        Endpoints.scheduleBuilderResetApplicants,
        data: {"start_date": _formatDate(state.date)},
      );
      state = state.copyWith(actionLoading: false);
      await fetchOpenings();
      await fetchApplicants();
      await fetchEmployees();
      return true;
    } catch (_) {
      state = state.copyWith(actionLoading: false);
      return false;
    }
  }

  void _ensureSelectionFromOpening(
    Map<String, dynamic> opening, {
    required bool refreshLists,
  }) {
    final layers = _shiftLayers(opening);
    String? layerId = state.selectedLayerId;
    String? shiftId = state.selectedScheduleShiftId;
    if (layerId == null || layerId.isEmpty || !_layerExists(layers, layerId)) {
      layerId = layers.isNotEmpty
          ? layers.first["daily_opening_layer_id"]?.toString()
          : null;
    }

    if (layerId != null) {
      final layer = layers.firstWhere(
        (l) => l["daily_opening_layer_id"]?.toString() == layerId,
        orElse: () => layers.isNotEmpty ? layers.first : <String, dynamic>{},
      );
      shiftId = _firstScheduleShiftId(layer) ?? shiftId;
    }
    shiftId ??= _openingScheduleShiftId(opening);

    state = state.copyWith(
      selectedLayerId: layerId,
      selectedScheduleShiftId: shiftId,
    );

    if (refreshLists) {
      fetchApplicants();
      fetchEmployees();
    }
  }

  void _syncShiftForLayer() {
    final opening = state.selectedOpening;
    if (opening == null) return;
    final layers = _shiftLayers(opening);
    final layerId = state.selectedLayerId;
    if (layerId == null) return;
    final layer = layers.firstWhere(
      (l) => l["daily_opening_layer_id"]?.toString() == layerId,
      orElse: () => <String, dynamic>{},
    );
    final shiftId = _firstScheduleShiftId(layer);
    if (shiftId != null) {
      state = state.copyWith(selectedScheduleShiftId: shiftId);
    } else {
      final fallback = _openingScheduleShiftId(opening);
      if (fallback != null) {
        state = state.copyWith(selectedScheduleShiftId: fallback);
      }
    }
  }
}

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

String _formatDate(DateTime date) {
  final mm = date.month.toString().padLeft(2, "0");
  final dd = date.day.toString().padLeft(2, "0");
  return "${date.year}-$mm-$dd";
}

String _openingId(Map<String, dynamic> opening) {
  return opening["opening_daily_id"]?.toString() ??
      opening["daily_opening_id"]?.toString() ??
      opening["daily_opening"]?.toString() ??
      opening["opening_daily"]?.toString() ??
      opening["id"]?.toString() ??
      "";
}

String? _assignShiftId(
  Map<String, dynamic>? opening,
  String? selectedShiftId,
) {
  if (opening == null) return selectedShiftId;
  final scheduleShiftId = opening["schedule_shift_id"]?.toString();
  if (scheduleShiftId != null && scheduleShiftId.isNotEmpty) {
    return scheduleShiftId;
  }
  final nested = opening["opening"];
  if (nested is Map) {
    final nestedId = nested["schedule_shift_id"]?.toString();
    if (nestedId != null && nestedId.isNotEmpty) return nestedId;
  }
  return selectedShiftId;
}

String? _errorMessage(Object error) {
  if (error is DioException) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return "Network error. Check your internet or API host.";
    }
    final status = error.response?.statusCode;
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final err = data["error"];
      if (err is Map && err["message"] != null) {
        final msg = err["message"];
        if (msg is List && msg.isNotEmpty) return msg.first.toString();
        return msg.toString();
      }
      if (data["message"] != null) {
        return data["message"].toString();
      }
    }
    if (data is String && data.isNotEmpty) return data;
    if (data != null) {
      return "Request failed${status != null ? " ($status)" : ""}: ${_stringifyData(data)}";
    }
    return error.message ??
        "Request failed${status != null ? " ($status)" : ""}";
  }
  return error.toString();
}

String _stringifyData(Object data) {
  try {
    return jsonEncode(data);
  } catch (_) {
    return data.toString();
  }
}

String? _openingScheduleShiftId(Map<String, dynamic> opening) {
  final direct = opening["schedule_shift_id"]?.toString() ??
      opening["shift_id"]?.toString();
  if (direct != null && direct.isNotEmpty) return direct;
  final details = opening["shift_details"];
  if (details is Map) {
    return details["shift_id"]?.toString() ??
        details["id"]?.toString() ??
        details["schedule_id"]?.toString();
  }
  if (details is List && details.isNotEmpty) {
    final first = details.first;
    if (first is Map) {
      return first["shift_id"]?.toString() ??
          first["id"]?.toString() ??
          first["schedule_id"]?.toString();
    }
  }
  return null;
}

List<String> _jobTitleIdsForOpening(Map<String, dynamic> opening) {
  final jobTitles = (opening["job_titles"] as List?)
          ?.whereType<Map>()
          .map((e) => e["id"]?.toString())
          .whereType<String>()
          .toList() ??
      [];
  if (jobTitles.isNotEmpty) return jobTitles;
  final shiftPositions = (opening["shift_positions"] as List?)
          ?.whereType<Map>()
          .map((e) => e["job_title_id"]?.toString())
          .whereType<String>()
          .toList() ??
      [];
  return shiftPositions;
}

String _firstJobTitleId(Map<String, dynamic> opening) {
  final titles = (opening["job_titles"] as List?) ?? [];
  if (titles.isEmpty) return "";
  if (titles.first is Map) {
    return (titles.first as Map)["id"]?.toString() ?? "";
  }
  return "";
}

List<Map<String, dynamic>> _shiftLayers(Map<String, dynamic> opening) {
  final layers = opening["shift_layers"] as List? ?? [];
  return layers
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

bool _layerExists(List<Map<String, dynamic>> layers, String id) {
  return layers.any((l) => l["daily_opening_layer_id"]?.toString() == id);
}

String? _firstScheduleShiftId(Map<String, dynamic> layer) {
  final details = (layer["schedule_details"] as List?) ?? [];
  if (details.isEmpty) return null;
  final first = details.first;
  if (first is Map) {
    return first["shift_id"]?.toString() ??
        first["id"]?.toString() ??
        first["schedule_id"]?.toString();
  }
  return null;
}


