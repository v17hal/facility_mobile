import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/network/api_provider.dart";
import "../../core/network/api_service.dart";
import "../../core/network/endpoints.dart";
import "../../core/storage/secure_store.dart";
import "../../core/storage/storage_keys.dart";

final dashboardControllerProvider =
    StateNotifierProvider<DashboardController, DashboardState>((ref) {
  final api = ApiService(ref.watch(apiClientProvider));
  final store = ref.watch(secureStoreProvider);
  return DashboardController(api, store);
});

class DashboardState {
  const DashboardState({
    required this.date,
    this.loading = false,
    this.departments = const [],
    this.selectedDepartments = const [],
    this.stats,
    this.facilities = const [],
    this.selectedFacilityId,
    this.selectedFacilityName,
  });

  final DateTime date;
  final bool loading;
  final List<Map<String, dynamic>> departments;
  final List<String> selectedDepartments;
  final Map<String, dynamic>? stats;
  final List<Map<String, dynamic>> facilities;
  final String? selectedFacilityId;
  final String? selectedFacilityName;

  DashboardState copyWith({
    DateTime? date,
    bool? loading,
    List<Map<String, dynamic>>? departments,
    List<String>? selectedDepartments,
    Map<String, dynamic>? stats,
    List<Map<String, dynamic>>? facilities,
    String? selectedFacilityId,
    String? selectedFacilityName,
  }) {
    return DashboardState(
      date: date ?? this.date,
      loading: loading ?? this.loading,
      departments: departments ?? this.departments,
      selectedDepartments: selectedDepartments ?? this.selectedDepartments,
      stats: stats ?? this.stats,
      facilities: facilities ?? this.facilities,
      selectedFacilityId: selectedFacilityId ?? this.selectedFacilityId,
      selectedFacilityName: selectedFacilityName ?? this.selectedFacilityName,
    );
  }
}

class DashboardController extends StateNotifier<DashboardState> {
  DashboardController(this._api, this._store)
      : super(DashboardState(date: DateTime.now())) {
    _loadDepartments();
    _loadFacilities();
    fetchStats();
  }

  final ApiService _api;
  final SecureStore _store;

  Future<void> _loadDepartments() async {
    try {
      final resp = await _api.get(Endpoints.fetchDepartments);
      final list = resp.data is Map<String, dynamic>
          ? (resp.data["data"] as List? ?? [])
          : (resp.data as List? ?? []);
      final mapped = list
          .whereType<Map>()
          .map((e) => {
                "id": e["id"]?.toString() ?? "",
                "name": e["name"],
              })
          .cast<Map<String, dynamic>>()
          .toList();
      state = state.copyWith(departments: mapped);
    } catch (_) {
      // ignore for now
    }
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
    } catch (_) {
      // ignore
    }
  }

  Future<void> selectFacility(String id, String name) async {
    await _store.write(StorageKeys.facilityId, id);
    await _store.write(StorageKeys.facilityName, name);
    state = state.copyWith(selectedFacilityId: id, selectedFacilityName: name);
    fetchStats();
  }

  void setDate(DateTime date) {
    state = state.copyWith(date: date);
    fetchStats();
  }

  void toggleDepartment(String id) {
    List<String> next;
    if (state.selectedDepartments.contains(id)) {
      next = [];
    } else {
      next = [id];
    }
    state = state.copyWith(selectedDepartments: next);
    fetchStats();
  }

  Future<void> fetchStats() async {
    state = state.copyWith(loading: true);
    try {
      final dateStr = _formatDate(state.date);
      final params = <String, dynamic>{};
      if (state.selectedDepartments.isNotEmpty) {
        params["department"] = state.selectedDepartments;
      }
      final url = "${Endpoints.fetchStatsDashboard}/$dateStr/$dateStr";
      final resp = await _api.get(url, params: params);
      final data = resp.data is Map<String, dynamic>
          ? (resp.data["data"] as Map<String, dynamic>?) ?? {}
          : {};
      state = state.copyWith(
        stats: Map<String, dynamic>.from(data),
        loading: false,
      );
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }
}

String _formatDate(DateTime date) {
  final mm = date.month.toString().padLeft(2, "0");
  final dd = date.day.toString().padLeft(2, "0");
  return "${date.year}-$mm-$dd";
}
