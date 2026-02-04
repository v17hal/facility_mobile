import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/network/api_provider.dart";
import "../../core/network/api_service.dart";
import "../../core/network/endpoints.dart";

class EmployeeDetailState {
  const EmployeeDetailState({
    this.loading = false,
    this.saving = false,
    this.data,
    this.wageHistory = const [],
    this.wageLoading = false,
    this.wagePage = 1,
    this.wagePageSize = 10,
    this.wageTotal = 0,
  });

  final bool loading;
  final bool saving;
  final Map<String, dynamic>? data;
  final List<Map<String, dynamic>> wageHistory;
  final bool wageLoading;
  final int wagePage;
  final int wagePageSize;
  final int wageTotal;

  EmployeeDetailState copyWith({
    bool? loading,
    bool? saving,
    Map<String, dynamic>? data,
    List<Map<String, dynamic>>? wageHistory,
    bool? wageLoading,
    int? wagePage,
    int? wagePageSize,
    int? wageTotal,
  }) {
    return EmployeeDetailState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      data: data ?? this.data,
      wageHistory: wageHistory ?? this.wageHistory,
      wageLoading: wageLoading ?? this.wageLoading,
      wagePage: wagePage ?? this.wagePage,
      wagePageSize: wagePageSize ?? this.wagePageSize,
      wageTotal: wageTotal ?? this.wageTotal,
    );
  }
}

final employeeDetailControllerProvider = StateNotifierProvider.autoDispose
    .family<EmployeeDetailController, EmployeeDetailState, String>(
  (ref, id) {
    final api = ApiService(ref.watch(apiClientProvider));
    return EmployeeDetailController(api, id)..fetch();
  },
);

class EmployeeDetailController extends StateNotifier<EmployeeDetailState> {
  EmployeeDetailController(this._api, this.employeeId)
      : super(const EmployeeDetailState());

  final ApiService _api;
  final String employeeId;

  Future<void> fetch() async {
    if (employeeId.isEmpty) return;
    state = state.copyWith(loading: true);
    try {
      final resp = await _api.get("${Endpoints.employees}/$employeeId");
      final data = resp.data is Map<String, dynamic>
          ? Map<String, dynamic>.from(resp.data["data"] ?? resp.data)
          : <String, dynamic>{};
      state = state.copyWith(loading: false, data: data);
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  Future<bool> update(Map<String, dynamic> payload) async {
    if (employeeId.isEmpty) return false;
    state = state.copyWith(saving: true);
    try {
      await _api.patch("${Endpoints.employees}/$employeeId", data: payload);
      state = state.copyWith(saving: false);
      await fetch();
      return true;
    } catch (_) {
      state = state.copyWith(saving: false);
      return false;
    }
  }

  Future<void> fetchWageHistory({int? page, int? pageSize}) async {
    if (employeeId.isEmpty) return;
    final nextPage = page ?? state.wagePage;
    final nextSize = pageSize ?? state.wagePageSize;
    state = state.copyWith(
      wageLoading: true,
      wagePage: nextPage,
      wagePageSize: nextSize,
    );
    try {
      final resp = await _api.get(
        Endpoints.employeeWageHistory(employeeId),
        params: {
          "page": nextPage,
          "page_size": nextSize,
        },
      );
      final data = resp.data is Map<String, dynamic>
          ? Map<String, dynamic>.from(resp.data)
          : <String, dynamic>{};
      final results = (data["results"] as List?)
              ?.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          <Map<String, dynamic>>[];
      state = state.copyWith(
        wageLoading: false,
        wageHistory: results,
        wageTotal: (data["count"] as int?) ?? results.length,
      );
    } catch (_) {
      state = state.copyWith(wageLoading: false);
    }
  }
}
