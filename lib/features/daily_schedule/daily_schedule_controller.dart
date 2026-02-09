
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
    this.selectedOpeningDetail,
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
  final Map<String, dynamic>? selectedOpeningDetail;
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
    Map<String, dynamic>? selectedOpeningDetail,
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
      selectedOpeningDetail:
          selectedOpeningDetail ?? this.selectedOpeningDetail,
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
    fetchOpenings();
  }

  void setDate(DateTime date) {
    state = state.copyWith(
      date: date,
      selectedShiftId: null,
      selectedOpening: null,
      selectedOpeningDetail: null,
      selectedLayerId: null,
      selectedScheduleShiftId: null,
      applicants: const [],
      employees: const [],
      selectedEmployees: const [],
    );
    fetchStats();
    fetchOpenings();
  }

  void setDepartment(String? id) {
    state = state.copyWith(
      selectedDepartmentId: id,
      selectedOpening: null,
      selectedOpeningDetail: null,
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
    // Shift list is derived from daily openings v4 list (fetchOpenings).
    await fetchOpenings();
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
          .map((e) => _normalizeShiftSummary(Map<String, dynamic>.from(e)))
          .toList();

      final departments = _deriveDepartmentsFromOpenings(openings);
      String? selectedDept = state.selectedDepartmentId;
      if (selectedDept != null &&
          !departments.any((d) => d["id"]?.toString() == selectedDept)) {
        selectedDept = null;
      }

      Map<String, dynamic>? selected = state.selectedOpening;
      if (selected == null && openings.isNotEmpty) {
        selected = openings.first;
      } else if (selected != null) {
        final id = _shiftSummaryId(selected);
        selected = openings.firstWhere(
          (o) => _shiftSummaryId(o) == id,
          orElse: () => openings.isNotEmpty ? openings.first : selected!,
        );
      }

      state = state.copyWith(
        openings: openings,
        departments: departments,
        selectedDepartmentId: selectedDept,
        selectedOpening: selected,
        openingsLoading: false,
      );

      if (selected != null) {
        await _loadShiftDetails(selected);
      }
    } catch (_) {
      state = state.copyWith(openingsLoading: false);
    }
  }

  void selectOpening(Map<String, dynamic> opening) {
    state = state.copyWith(
      selectedOpening: opening,
      selectedOpeningDetail: null,
      applicants: const [],
      employees: const [],
      selectedEmployees: const [],
    );
    _loadShiftDetails(opening);
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

  void selectOpeningDetail(Map<String, dynamic> detail) {
    debugPrint("OPENING DETAIL KEYS: ${detail.keys.toList()}");
    debugPrint("OPENING DETAIL JSON: ${jsonEncode(detail)}");
    final detailShiftId = detail["schedule_shift_id"]?.toString() ??
        detail["shift_id"]?.toString() ??
        detail["id"]?.toString();
    final detailLayerId = detail["opening_layer_daily_id"]?.toString() ??
        detail["daily_opening_layer_id"]?.toString() ??
        detail["opening_layer_id"]?.toString();
    state = state.copyWith(
      selectedOpeningDetail: detail,
      selectedScheduleShiftId:
          detailShiftId?.isNotEmpty == true ? detailShiftId : null,
      selectedLayerId:
          detailLayerId?.isNotEmpty == true ? detailLayerId : state.selectedLayerId,
      applicants: const [],
      employees: const [],
      selectedEmployees: const [],
    );
    _ensureSelectionFromOpening(detail, refreshLists: true);
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
    final opening = state.selectedOpeningDetail ?? state.selectedOpening;
    final shiftId =
        _assignShiftId(opening, state.selectedScheduleShiftId);
    if (shiftId == null || opening == null || shiftId.isEmpty) return;
    if (state.applicantsLoading) return;

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
    final opening = state.selectedOpeningDetail ?? state.selectedOpening;
    final shiftId =
        _assignShiftId(opening, state.selectedScheduleShiftId);
    if (shiftId == null || opening == null || shiftId.isEmpty) return;
    if (state.employeesLoading) return;

    state = state.copyWith(employeesLoading: true);
    try {
      final params = <String, dynamic>{
        "page": 1,
        "page_size": 50,
        if (state.employeeSearch.isNotEmpty)
          "search": state.employeeSearch,
      };
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
    final opening = state.selectedOpeningDetail ?? state.selectedOpening;
    final shiftId = _assignShiftId(opening, state.selectedScheduleShiftId);
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
      final scheduleShiftId = shiftId;
      final jobTitleId = overrideJobTitleId ??
          selected.first["job_title_id"]?.toString() ??
          _firstJobTitleId(opening);
      if (jobTitleId == null || jobTitleId.isEmpty) {
        state = state.copyWith(actionLoading: false, actionError: "Missing job title");
        print("Assign aborted: job title is empty");
        return false;
      }
      if (scheduleShiftId == null || scheduleShiftId.isEmpty) {
        state = state.copyWith(
          actionLoading: false,
          actionError: "Missing schedule shift id",
        );
        print("Assign aborted: schedule shift id is empty");
        return false;
      }

      final shifts = selected.map((e) {
        final empJobTitle =
            overrideJobTitleId ?? e["job_title_id"]?.toString();
        return {
          "nurse_id": e["id"],
          "schedule_shift_id": scheduleShiftId,
          "job_title_id": empJobTitle ?? jobTitleId,
        };
      }).toList();

      final payload = {"shifts": shifts};

      print("Assign endpoint: ${Endpoints.dailyScheduleMultiAssign}");
      print("Assign payload: ${_stringifyData(payload)}");

      await _api.post(
        Endpoints.dailyScheduleMultiAssign,
        data: payload,
      );

      // Optimistic UI update so assigned employee shows immediately.
      if (opening != null && selected.isNotEmpty) {
        final updated = _optimisticAssign(opening, selected.first);
        state = state.copyWith(
          selectedOpeningDetail: updated,
          selectedOpening: state.selectedOpening,
        );
      }

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
        Endpoints.dailyScheduleShiftDetail(openingId),
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
      final selected = state.selectedOpening;
      final effectiveId =
          selected?["effective_parent_id"]?.toString() ?? openingId;
      if (effectiveId.isNotEmpty &&
          selected?["created_from_opening"] != null) {
        await _api.post(
          Endpoints.dailyScheduleDeleteShift,
          data: {
            "effective_parent_ids": [
              {
                "id": effectiveId,
                "created_from_opening":
                    selected?["created_from_opening"] ?? false,
              },
            ],
            "date": _formatDate(state.date),
          },
        );
      } else {
        await _api.delete(Endpoints.dailyScheduleUpdateOpening(openingId));
      }
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
      debugPrint("Unassign payload: status=UNASSIGNED");
      debugPrint(
        "Unassign ids: openingDailyId=$openingDailyId applicantId=$applicantId",
      );
      final resp = await _api.patch(
        Endpoints.dailyScheduleUnassignApplicant(openingDailyId, applicantId),
        data: {"status": "UNASSIGNED"},
      );
      debugPrint(
        "Unassign response: ${resp.statusCode} ${_stringifyData(resp.data)}",
      );
      state = state.copyWith(actionLoading: false, actionError: null);
      await fetchOpenings();
      // Refresh the currently selected opening detail so UI updates immediately.
      final current = state.selectedOpening;
      if (current != null) {
        await _loadShiftDetails(current);
      }
      if (state.selectedOpeningDetail != null) {
        state = state.copyWith(
          selectedOpeningDetail: _optimisticUnassign(
            state.selectedOpeningDetail!,
            applicantId,
          ),
        );
      }
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
    if (shiftId == null || shiftId.isEmpty) {
      final details = opening["shift_details"];
      if (details is List && details.isNotEmpty) {
        final first = details.first;
        if (first is Map) {
          shiftId = first["schedule_shift_id"]?.toString() ??
              first["shift_id"]?.toString() ??
              first["id"]?.toString();
        }
      } else if (details is Map) {
        shiftId = details["schedule_shift_id"]?.toString() ??
            details["shift_id"]?.toString() ??
            details["id"]?.toString();
      }
    }

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

  Future<bool> updateApplicantStatus({
    required String applicantId,
    required String openingDailyId,
    String? openingLayerDailyId,
    required String status,
  }) async {
    if (applicantId.isEmpty || openingDailyId.isEmpty) return false;
    state = state.copyWith(actionLoading: true, actionError: null);
    try {
      final payload = {
        "opening_daily_id": openingDailyId,
        if (openingLayerDailyId != null && openingLayerDailyId.isNotEmpty)
          "opening_layer_daily_id": openingLayerDailyId,
        "status": status,
      };
      debugPrint("Update applicant endpoint: ${Endpoints.dailyScheduleUpdateApplicant(applicantId)}");
      debugPrint("Update applicant payload: ${jsonEncode(payload)}");
      final resp = await _api.patch(
        Endpoints.dailyScheduleUpdateApplicant(applicantId),
        data: payload,
      );
      debugPrint(
        "Update applicant response: ${resp.statusCode} ${_stringifyData(resp.data)}",
      );
      state = state.copyWith(actionLoading: false, actionError: null);
      await fetchOpenings();
      return true;
    } catch (e) {
      final message = _errorMessage(e) ?? e.toString();
      state = state.copyWith(actionLoading: false, actionError: message);
      debugPrint("Update applicant failed: $message");
      return false;
    }
  }

  Future<bool> updateApplicantStatusV2({
    required String openingDailyId,
    required String applicantId,
    required String status,
  }) async {
    if (openingDailyId.isEmpty || applicantId.isEmpty) return false;
    state = state.copyWith(actionLoading: true, actionError: null);
    try {
      final payload = {"status": status};
      debugPrint(
        "Update applicant v2 endpoint: ${Endpoints.dailyScheduleUnassignApplicant(openingDailyId, applicantId)}",
      );
      debugPrint("Update applicant v2 payload: ${jsonEncode(payload)}");
      final resp = await _api.patch(
        Endpoints.dailyScheduleUnassignApplicant(openingDailyId, applicantId),
        data: payload,
      );
      debugPrint(
        "Update applicant v2 response: ${resp.statusCode} ${_stringifyData(resp.data)}",
      );
      state = state.copyWith(actionLoading: false, actionError: null);
      await fetchOpenings();
      return true;
    } catch (e) {
      final message = _errorMessage(e) ?? e.toString();
      state = state.copyWith(actionLoading: false, actionError: message);
      debugPrint("Update applicant v2 failed: $message");
      return false;
    }
  }

  void applyLocalTransfer({
    required String fromOpeningId,
    required String toOpeningId,
    required Map<String, dynamic> employee,
  }) {
    final opening = state.selectedOpening;
    if (opening == null) return;
    final details = opening["shift_details"];
    if (details is! List) return;

    List<dynamic> updatedDetails = details.map((item) {
      if (item is! Map) return item;
      final mapped = Map<String, dynamic>.from(item);
      final id = _openingId(mapped);
      if (id == fromOpeningId) {
        mapped["applicants"] = _removeApplicant(mapped["applicants"], employee);
      } else if (id == toOpeningId) {
        mapped["applicants"] = _addApplicant(mapped["applicants"], employee);
      }
      return mapped;
    }).toList();

    final updatedOpening = {
      ...opening,
      "shift_details": updatedDetails,
    };

    Map<String, dynamic>? updatedDetail = state.selectedOpeningDetail;
    if (updatedDetail != null) {
      final detailId = _openingId(updatedDetail);
      if (detailId == fromOpeningId || detailId == toOpeningId) {
        for (final item in updatedDetails) {
          if (item is! Map) continue;
          final id = _openingId(Map<String, dynamic>.from(item));
          if (id == detailId) {
            updatedDetail = Map<String, dynamic>.from(item);
            break;
          }
        }
      }
    }

    state = state.copyWith(
      selectedOpening: updatedOpening,
      selectedOpeningDetail: updatedDetail,
    );
  }

  Future<void> _loadShiftDetails(Map<String, dynamic> summary) async {
    final shiftId = _shiftSummaryId(summary);
    if (shiftId.isEmpty) {
      _ensureSelectionFromOpening(summary, refreshLists: true);
      return;
    }
    state = state.copyWith(detailsLoading: true);
    try {
      final resp = await _api.get(
        Endpoints.dailyScheduleShiftDetail(shiftId),
        params: {"date": _formatDate(state.date)},
      );
      var list = _extractList(resp.data);
      if (list.isEmpty && resp.data is Map<String, dynamic>) {
        final data = resp.data["data"];
        if (data is Map && data["shift_details"] is List) {
          list = data["shift_details"] as List;
        }
      }
      final details = list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final totalOpenings = details.length;
      final filledOpenings = _filledOpeningsCount(details);
      final enriched = {
        ...summary,
        "schedule_shift_id": summary["schedule_shift_id"]?.toString() ?? shiftId,
        "shift_details": details,
        "mobile_total_count": totalOpenings,
        "mobile_filled_count": filledOpenings,
      };
      final selectedDetail =
          _detailForShiftMap(enriched, state.selectedScheduleShiftId);
      state = state.copyWith(
        selectedOpening: _mergeMobileCounts(enriched, totalOpenings, filledOpenings),
        selectedOpeningDetail: selectedDetail,
        detailsLoading: false,
      );
      _mergeCountsIntoOpenings(shiftId, totalOpenings, filledOpenings);
      _ensureSelectionFromOpening(enriched, refreshLists: true);
    } catch (_) {
      state = state.copyWith(detailsLoading: false);
      _ensureSelectionFromOpening(summary, refreshLists: true);
    }
  }

  void _mergeCountsIntoOpenings(String shiftId, int total, int filled) {
    if (state.openings.isEmpty) return;
    final updated = state.openings.map((opening) {
      final id = _shiftSummaryId(opening);
      if (id == shiftId) {
        return {
          ...opening,
          "mobile_total_count": total,
          "mobile_filled_count": filled,
        };
      }
      return opening;
    }).toList();
    state = state.copyWith(openings: updated);
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
      opening["effective_parent_id"]?.toString() ??
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

List<dynamic> _removeApplicant(dynamic applicants, Map<String, dynamic> employee) {
  if (applicants is! List) return applicants is List ? applicants : [];
  final empId = employee["id"]?.toString() ??
      employee["employee_id"]?.toString() ??
      employee["nurse_id"]?.toString();
  if (empId == null || empId.isEmpty) return applicants;
  return applicants.where((item) {
    if (item is! Map) return true;
    final nurse = item["nurse"];
    String? id;
    if (nurse is Map) {
      id = nurse["id"]?.toString() ??
          nurse["employee_id"]?.toString() ??
          nurse["nurse_id"]?.toString();
    }
    id ??= item["employee_id"]?.toString() ?? item["nurse_id"]?.toString();
    return id != empId;
  }).toList();
}

List<dynamic> _addApplicant(dynamic applicants, Map<String, dynamic> employee) {
  final list = applicants is List ? [...applicants] : <dynamic>[];
  final nurse = {
    "id": employee["id"],
    "first_name": employee["first_name"],
    "last_name": employee["last_name"],
    "job_title": employee["job_title"],
  };
  list.insert(0, {
    "applicant_id": "temp-${employee["id"]}",
    "status": "ACCEPTED",
    "is_assigned": true,
    "nurse": nurse,
  });
  return list;
}

Map<String, dynamic> _optimisticUnassign(
  Map<String, dynamic> openingDetail,
  String applicantId,
) {
  final copy = Map<String, dynamic>.from(openingDetail);
  final details = copy["shift_details"];
  if (details is List) {
    copy["shift_details"] = details.map((d) {
      if (d is! Map) return d;
      final mapped = Map<String, dynamic>.from(d);
      final applicants = (mapped["applicants"] as List?) ?? [];
      mapped["applicants"] = applicants.where((a) {
        if (a is! Map) return true;
        final id = a["applicant_id"]?.toString() ?? a["id"]?.toString();
        return id != applicantId;
      }).toList();
      return mapped;
    }).toList();
  }
  return copy;
}

Map<String, dynamic> _optimisticAssign(
  Map<String, dynamic> openingDetail,
  Map<String, dynamic> employee,
) {
  final copy = Map<String, dynamic>.from(openingDetail);
  final details = copy["shift_details"];
  final nurse = {
    "id": employee["id"],
    "first_name": employee["first_name"],
    "last_name": employee["last_name"],
    "job_title": employee["job_title"],
  };
  final applicant = {
    "applicant_id": "temp-${employee["id"]}",
    "status": "ACCEPTED",
    "is_assigned": true,
    "nurse": nurse,
  };
  if (details is List && details.isNotEmpty) {
    final first = details.first;
    if (first is Map) {
      final mapped = Map<String, dynamic>.from(first);
      final applicants = (mapped["applicants"] as List?) ?? [];
      mapped["applicants"] = [applicant, ...applicants];
      copy["shift_details"] = [mapped, ...details.skip(1)];
    }
  } else if (details is Map) {
    final mapped = Map<String, dynamic>.from(details);
    final applicants = (mapped["applicants"] as List?) ?? [];
    mapped["applicants"] = [applicant, ...applicants];
    copy["shift_details"] = mapped;
  }
  return copy;
}

String? _openingScheduleShiftId(Map<String, dynamic> opening) {
  final direct = opening["schedule_shift_id"]?.toString() ??
      opening["shift_id"]?.toString();
  if (direct != null && direct.isNotEmpty) return direct;
  final detail = opening["shift_details"];
  if (detail is List && detail.isNotEmpty) {
    final first = detail.first;
    if (first is Map) {
      final candidate = first["schedule_shift_id"]?.toString() ??
          first["shift_id"]?.toString() ??
          first["id"]?.toString();
      if (candidate != null && candidate.isNotEmpty) return candidate;
    }
  } else if (detail is Map) {
    final candidate = detail["schedule_shift_id"]?.toString() ??
        detail["shift_id"]?.toString() ??
        detail["id"]?.toString();
    if (candidate != null && candidate.isNotEmpty) return candidate;
  }
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

String _shiftSummaryId(Map<String, dynamic> opening) {
  return opening["effective_parent_id"]?.toString() ??
      opening["schedule_shift_id"]?.toString() ??
      opening["shift_id"]?.toString() ??
      opening["id"]?.toString() ??
      "";
}

Map<String, dynamic> _normalizeShiftSummary(Map<String, dynamic> opening) {
  if (opening["opening_daily_id"] == null &&
      opening["effective_parent_id"] != null) {
    opening["opening_daily_id"] = opening["effective_parent_id"].toString();
  }
  if (opening["name"] == null && opening["parent_name"] != null) {
    opening["name"] = opening["parent_name"];
  }
  return opening;
}

List<Map<String, dynamic>> _deriveDepartmentsFromOpenings(
  List<Map<String, dynamic>> openings,
) {
  final map = <String, Map<String, dynamic>>{};
  for (final opening in openings) {
    final dept = opening["department"];
    final id = dept is Map ? dept["id"]?.toString() : null;
    final name = dept is Map ? dept["name"]?.toString() : null;
    if (id == null || name == null) continue;
    map.putIfAbsent(id, () => {"id": id, "name": name});
  }
  final list = map.values.toList();
  list.sort((a, b) => (a["name"]?.toString() ?? "")
      .compareTo(b["name"]?.toString() ?? ""));
  return list;
}

List<String> _jobTitleIdsForOpening(Map<String, dynamic> opening) {
  final jobTitles = (opening["job_titles"] as List?)
          ?.whereType<Map>()
          .map((e) => e["id"]?.toString())
          .whereType<String>()
          .toList() ??
      [];
  if (jobTitles.isNotEmpty) return jobTitles;
  final shiftDetails = opening["shift_details"];
  if (shiftDetails is List) {
    final ids = <String>[];
    for (final detail in shiftDetails) {
      if (detail is! Map) continue;
      final titles = (detail["job_titles"] as List?)
              ?.whereType<Map>()
              .map((e) => e["id"]?.toString())
              .whereType<String>() ??
          const [];
      ids.addAll(titles);
      final positions = (detail["shift_positions"] as List?)
              ?.whereType<Map>()
              .map((e) => e["job_title_id"]?.toString())
              .whereType<String>() ??
          const [];
      ids.addAll(positions);
    }
    final unique = ids.where((e) => e.isNotEmpty).toSet().toList();
    if (unique.isNotEmpty) return unique;
  } else if (shiftDetails is Map) {
    final titles = (shiftDetails["job_titles"] as List?)
            ?.whereType<Map>()
            .map((e) => e["id"]?.toString())
            .whereType<String>()
            .toList() ??
        [];
    if (titles.isNotEmpty) return titles;
    final positions = (shiftDetails["shift_positions"] as List?)
            ?.whereType<Map>()
            .map((e) => e["job_title_id"]?.toString())
            .whereType<String>()
            .toList() ??
        [];
    if (positions.isNotEmpty) return positions;
  }
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
  final details = opening["shift_details"];
  if (details is List && details.isNotEmpty) {
    final first = details.first;
    if (first is Map) {
      final nestedTitles = (first["job_titles"] as List?) ?? [];
      if (nestedTitles.isNotEmpty && nestedTitles.first is Map) {
        return (nestedTitles.first as Map)["id"]?.toString() ?? "";
      }
      final positions = (first["shift_positions"] as List?) ?? [];
      if (positions.isNotEmpty && positions.first is Map) {
        return (positions.first as Map)["job_title_id"]?.toString() ?? "";
      }
    }
  } else if (details is Map) {
    final nestedTitles = (details["job_titles"] as List?) ?? [];
    if (nestedTitles.isNotEmpty && nestedTitles.first is Map) {
      return (nestedTitles.first as Map)["id"]?.toString() ?? "";
    }
    final positions = (details["shift_positions"] as List?) ?? [];
    if (positions.isNotEmpty && positions.first is Map) {
      return (positions.first as Map)["job_title_id"]?.toString() ?? "";
    }
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

Map<String, dynamic>? _detailForShiftMap(
  Map<String, dynamic> opening,
  String? shiftId,
) {
  final details = opening["shift_details"];
  if (details is Map<String, dynamic>) return details;
  if (details is List && details.isNotEmpty) {
    if (shiftId != null && shiftId.isNotEmpty) {
      for (final item in details) {
        if (item is! Map) continue;
        final id = item["shift_id"]?.toString() ??
            item["id"]?.toString() ??
            item["schedule_id"]?.toString() ??
            item["schedule_shift_id"]?.toString();
        if (id == shiftId) return Map<String, dynamic>.from(item);
      }
    }
    final first = details.first;
    if (first is Map) return Map<String, dynamic>.from(first);
  }
  return null;
}

int _filledOpeningsCount(List<Map<String, dynamic>> details) {
  int filled = 0;
  for (final detail in details) {
    final applicants = (detail["applicants"] as List?) ?? [];
    final hasAssigned = applicants.any((a) {
      if (a is! Map) return false;
      final status = a["status"]?.toString().toUpperCase();
      final assigned = a["is_assigned"] == true;
      return status == "ACCEPTED" || assigned;
    });
    if (hasAssigned) filled += 1;
  }
  return filled;
}

Map<String, dynamic> _mergeMobileCounts(
  Map<String, dynamic> opening,
  int total,
  int filled,
) {
  return {
    ...opening,
    "mobile_total_count": total,
    "mobile_filled_count": filled,
  };
}



