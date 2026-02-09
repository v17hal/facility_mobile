import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/network/api_provider.dart";
import "../../core/network/api_service.dart";
import "../../core/network/endpoints.dart";
import "../../core/storage/secure_store.dart";
import "../../core/storage/storage_keys.dart";

enum EmployeesTab {
  active,
  invited,
  blocked,
  terminated,
  walkIn,
  supervisors,
  schedulers,
}

class EmployeesState {
  const EmployeesState({
    this.activeTab = EmployeesTab.active,
    this.loading = false,
    this.loadingMore = false,
    this.employees = const [],
    this.total = 0,
    this.page = 1,
    this.pageSize = 30,
    this.search = "",
    this.jobTitles = const [],
    this.departments = const [],
    this.selectedJobTitles = const [],
    this.selectedDepartments = const [],
    this.credentialStatus = "CREDENTIAL_ALL",
    this.ordering = "",
    this.supervisors = const [],
    this.schedulers = const [],
    this.secondaryLoading = false,
    this.facilities = const [],
    this.selectedFacilityId,
    this.selectedFacilityName,
  });

  final EmployeesTab activeTab;
  final bool loading;
  final bool loadingMore;
  final List<Map<String, dynamic>> employees;
  final int total;
  final int page;
  final int pageSize;
  final String search;
  final List<Map<String, dynamic>> jobTitles;
  final List<Map<String, dynamic>> departments;
  final List<String> selectedJobTitles;
  final List<String> selectedDepartments;
  final String credentialStatus;
  final String ordering;
  final List<Map<String, dynamic>> supervisors;
  final List<Map<String, dynamic>> schedulers;
  final bool secondaryLoading;
  final List<Map<String, dynamic>> facilities;
  final String? selectedFacilityId;
  final String? selectedFacilityName;

  bool get hasMore => employees.length < total;

  EmployeesState copyWith({
    EmployeesTab? activeTab,
    bool? loading,
    bool? loadingMore,
    List<Map<String, dynamic>>? employees,
    int? total,
    int? page,
    int? pageSize,
    String? search,
    List<Map<String, dynamic>>? jobTitles,
    List<Map<String, dynamic>>? departments,
    List<String>? selectedJobTitles,
    List<String>? selectedDepartments,
    String? credentialStatus,
    String? ordering,
    List<Map<String, dynamic>>? supervisors,
    List<Map<String, dynamic>>? schedulers,
    bool? secondaryLoading,
    List<Map<String, dynamic>>? facilities,
    String? selectedFacilityId,
    String? selectedFacilityName,
  }) {
    return EmployeesState(
      activeTab: activeTab ?? this.activeTab,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      employees: employees ?? this.employees,
      total: total ?? this.total,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      search: search ?? this.search,
      jobTitles: jobTitles ?? this.jobTitles,
      departments: departments ?? this.departments,
      selectedJobTitles: selectedJobTitles ?? this.selectedJobTitles,
      selectedDepartments: selectedDepartments ?? this.selectedDepartments,
      credentialStatus: credentialStatus ?? this.credentialStatus,
      ordering: ordering ?? this.ordering,
      supervisors: supervisors ?? this.supervisors,
      schedulers: schedulers ?? this.schedulers,
      secondaryLoading: secondaryLoading ?? this.secondaryLoading,
      facilities: facilities ?? this.facilities,
      selectedFacilityId: selectedFacilityId ?? this.selectedFacilityId,
      selectedFacilityName: selectedFacilityName ?? this.selectedFacilityName,
    );
  }
}

final employeesControllerProvider =
    StateNotifierProvider<EmployeesController, EmployeesState>((ref) {
  final api = ApiService(ref.watch(apiClientProvider));
  final store = ref.watch(secureStoreProvider);
  return EmployeesController(api, store);
});

class EmployeesController extends StateNotifier<EmployeesState> {
  EmployeesController(this._api, this._store) : super(const EmployeesState()) {
    _loadFilters();
    _loadFacilities();
    fetchEmployees(reset: true);
  }

  final ApiService _api;
  final SecureStore _store;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void setTab(EmployeesTab tab) {
    if (tab == state.activeTab) return;
    state = state.copyWith(
      activeTab: tab,
      search: "",
      page: 1,
      employees: const [],
      supervisors: const [],
      schedulers: const [],
      total: 0,
    );
    if (_isSecondaryTab(tab)) {
      fetchSecondary();
    } else {
      fetchEmployees(reset: true);
    }
  }

  void updateSearch(String value) {
    state = state.copyWith(search: value, page: 1);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (_isSecondaryTab(state.activeTab)) {
        fetchSecondary();
      } else {
        fetchEmployees(reset: true);
      }
    });
  }

  void updateOrdering(String ordering) {
    state = state.copyWith(ordering: ordering);
    if (_isSecondaryTab(state.activeTab)) {
      fetchSecondary();
    } else {
      fetchEmployees(reset: true);
    }
  }

  void updateCredentialStatus(String status) {
    state = state.copyWith(credentialStatus: status);
    if (!_isSecondaryTab(state.activeTab)) {
      fetchEmployees(reset: true);
    }
  }

  void applyFilters({
    required List<String> jobTitles,
    required List<String> departments,
    required String credentialStatus,
    required String ordering,
  }) {
    state = state.copyWith(
      selectedJobTitles: jobTitles,
      selectedDepartments: departments,
      credentialStatus: credentialStatus,
      ordering: ordering,
    );
    if (!_isSecondaryTab(state.activeTab)) {
      fetchEmployees(reset: true);
    }
  }

  void clearFilters() {
    state = state.copyWith(
      selectedJobTitles: const [],
      selectedDepartments: const [],
      credentialStatus: "CREDENTIAL_ALL",
      ordering: "",
    );
    if (!_isSecondaryTab(state.activeTab)) {
      fetchEmployees(reset: true);
    }
  }

  Future<void> fetchEmployees({bool reset = false}) async {
    if (state.loading || state.loadingMore) return;
    final nextPage = reset ? 1 : state.page;
    if (!reset && !state.hasMore) return;
    state = state.copyWith(loading: reset, loadingMore: !reset, page: nextPage);
    try {
      final params = <String, dynamic>{
        "page_size": state.pageSize,
      };
      if (state.search.isEmpty) {
        params["page"] = nextPage;
      } else {
        params["search"] = state.search;
      }

      if (state.activeTab == EmployeesTab.walkIn) {
        params["is_walk_in_nurse"] = true;
      } else {
        params["credential_status"] = state.credentialStatus;
      }

      switch (state.activeTab) {
        case EmployeesTab.active:
          params["status"] = "ACTIVE_AND_INVITED";
          break;
        case EmployeesTab.invited:
          params["status"] = "INVITED";
          break;
        case EmployeesTab.blocked:
          params["status"] = "BLOCKED";
          break;
        case EmployeesTab.terminated:
          params["status"] = "TERMINATED";
          break;
        case EmployeesTab.walkIn:
        case EmployeesTab.supervisors:
        case EmployeesTab.schedulers:
          break;
      }

      if (state.selectedJobTitles.isNotEmpty) {
        params["job_title"] = state.selectedJobTitles;
      }
      if (state.selectedDepartments.isNotEmpty) {
        params["department"] = state.selectedDepartments;
      }
      if (state.ordering.isNotEmpty) {
        params["ordering"] = state.ordering;
        params["order_by"] = state.ordering;
      }

      final resp = await _api.get(Endpoints.employees, params: params);
      final data = resp.data is Map<String, dynamic>
          ? Map<String, dynamic>.from(resp.data)
          : <String, dynamic>{};
      final results = _extractList(data);
      final total = _extractCount(data) ?? results.length;
      final merged = reset ? results : [...state.employees, ...results];
      state = state.copyWith(
        employees: merged,
        total: total,
        page: nextPage + 1,
        loading: false,
        loadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(loading: false, loadingMore: false);
    }
  }

  Future<void> fetchSecondary() async {
    if (state.secondaryLoading) return;
    state = state.copyWith(secondaryLoading: true);
    try {
      final params = <String, dynamic>{};
      if (state.search.isNotEmpty) params["search"] = state.search;
      if (state.ordering.isNotEmpty) params["ordering"] = state.ordering;
      final endpoint = state.activeTab == EmployeesTab.supervisors
          ? Endpoints.supervisors
          : Endpoints.schedulers;
      final resp = await _api.get(endpoint, params: params);
      final list = _extractList(resp.data);
      if (state.activeTab == EmployeesTab.supervisors) {
        state = state.copyWith(
          supervisors: list,
          secondaryLoading: false,
        );
      } else {
        state = state.copyWith(
          schedulers: list,
          secondaryLoading: false,
        );
      }
    } catch (_) {
      state = state.copyWith(secondaryLoading: false);
    }
  }

  Future<void> resendInvite(String id) async {
    try {
      await _api.patch(
        "${Endpoints.employeeInviteAction}/$id/invite-action",
        data: {"action": "resend_invite"},
      );
      fetchEmployees(reset: true);
    } catch (_) {}
  }

  Future<void> cancelInvite(String id) async {
    try {
      await _api.patch(
        "${Endpoints.employeeInviteAction}/$id/invite-action",
        data: {"action": "cancel_invite"},
      );
      fetchEmployees(reset: true);
    } catch (_) {}
  }

  Future<void> _loadFilters() async {
    await Future.wait([
      _loadJobTitles(),
      _loadDepartments(),
    ]);
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
              })
          .cast<Map<String, dynamic>>()
          .toList();
      state = state.copyWith(jobTitles: mapped);
    } catch (_) {}
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

  Future<void> _loadFacilities() async {
    try {
      final resp = await _api.get("owner/facility/list");
      final list = resp.data is Map<String, dynamic>
          ? (resp.data["data"] as List? ?? [])
          : (resp.data as List? ?? []);
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
    } catch (_) {}
  }

  Future<void> selectFacility(String id, String name) async {
    await _store.write(StorageKeys.facilityId, id);
    await _store.write(StorageKeys.facilityName, name);
    state = state.copyWith(selectedFacilityId: id, selectedFacilityName: name);
    if (_isSecondaryTab(state.activeTab)) {
      fetchSecondary();
    } else {
      fetchEmployees(reset: true);
    }
  }
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

int? _extractCount(Map<String, dynamic> data) {
  if (data["count"] is int) return data["count"] as int;
  final nested = data["data"];
  if (nested is Map<String, dynamic> && nested["count"] is int) {
    return nested["count"] as int;
  }
  return null;
}

bool _isSecondaryTab(EmployeesTab tab) {
  return tab == EmployeesTab.supervisors || tab == EmployeesTab.schedulers;
}
