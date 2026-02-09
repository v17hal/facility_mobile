import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:dio/dio.dart";

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
    this.dependents = const [],
    this.dependentsLoading = false,
    this.taxForms = const [],
    this.taxFormsLoading = false,
    this.credentials = const [],
    this.credentialsLoading = false,
    this.workHistory = const [],
    this.workHistoryLoading = false,
    this.payDetails,
    this.payDetailsLoading = false,
    this.w4Forms = const [],
    this.w4Loading = false,
  });

  final bool loading;
  final bool saving;
  final Map<String, dynamic>? data;
  final List<Map<String, dynamic>> wageHistory;
  final bool wageLoading;
  final int wagePage;
  final int wagePageSize;
  final int wageTotal;
  final List<Map<String, dynamic>> dependents;
  final bool dependentsLoading;
  final List<Map<String, dynamic>> taxForms;
  final bool taxFormsLoading;
  final List<Map<String, dynamic>> credentials;
  final bool credentialsLoading;
  final List<Map<String, dynamic>> workHistory;
  final bool workHistoryLoading;
  final Map<String, dynamic>? payDetails;
  final bool payDetailsLoading;
  final List<Map<String, dynamic>> w4Forms;
  final bool w4Loading;

  EmployeeDetailState copyWith({
    bool? loading,
    bool? saving,
    Map<String, dynamic>? data,
    List<Map<String, dynamic>>? wageHistory,
    bool? wageLoading,
    int? wagePage,
    int? wagePageSize,
    int? wageTotal,
    List<Map<String, dynamic>>? dependents,
    bool? dependentsLoading,
    List<Map<String, dynamic>>? taxForms,
    bool? taxFormsLoading,
    List<Map<String, dynamic>>? credentials,
    bool? credentialsLoading,
    List<Map<String, dynamic>>? workHistory,
    bool? workHistoryLoading,
    Map<String, dynamic>? payDetails,
    bool? payDetailsLoading,
    List<Map<String, dynamic>>? w4Forms,
    bool? w4Loading,
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
      dependents: dependents ?? this.dependents,
      dependentsLoading: dependentsLoading ?? this.dependentsLoading,
      taxForms: taxForms ?? this.taxForms,
      taxFormsLoading: taxFormsLoading ?? this.taxFormsLoading,
      credentials: credentials ?? this.credentials,
      credentialsLoading: credentialsLoading ?? this.credentialsLoading,
      workHistory: workHistory ?? this.workHistory,
      workHistoryLoading: workHistoryLoading ?? this.workHistoryLoading,
      payDetails: payDetails ?? this.payDetails,
      payDetailsLoading: payDetailsLoading ?? this.payDetailsLoading,
      w4Forms: w4Forms ?? this.w4Forms,
      w4Loading: w4Loading ?? this.w4Loading,
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
      await Future.wait([
        fetchDependents(),
        fetchTaxForms(),
        fetchCredentials(),
        fetchWorkHistory(),
        fetchPayDetails(),
        fetchW4Forms(),
      ]);
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
      final results = _extractList(data);
      final total = _extractCount(data) ?? results.length;
      state = state.copyWith(
        wageLoading: false,
        wageHistory: results,
        wageTotal: total,
      );
    } catch (_) {
      state = state.copyWith(wageLoading: false);
    }
  }

  Future<void> fetchDependents() async {
    if (employeeId.isEmpty) return;
    state = state.copyWith(dependentsLoading: true);
    try {
      final resp = await _api.get(Endpoints.employeeDependents(employeeId));
      final list = _extractList(resp.data);
      state = state.copyWith(
        dependentsLoading: false,
        dependents: list,
      );
    } catch (_) {
      try {
        final resp = await _api.get(Endpoints.employeeDependentsLegacy(employeeId));
        final list = _extractList(resp.data);
        state = state.copyWith(
          dependentsLoading: false,
          dependents: list,
        );
      } catch (_) {
        state = state.copyWith(dependentsLoading: false);
      }
    }
  }

  Future<void> fetchTaxForms() async {
    if (employeeId.isEmpty) return;
    state = state.copyWith(taxFormsLoading: true);
    try {
      final resp = await _api.get(Endpoints.employeeTaxForms(employeeId));
      final list = _extractList(resp.data);
      state = state.copyWith(taxFormsLoading: false, taxForms: list);
    } catch (_) {
      state = state.copyWith(taxFormsLoading: false);
    }
  }

  Future<bool> updateTaxFormStatus({
    required String formId,
    required String status,
  }) async {
    if (employeeId.isEmpty || formId.isEmpty) return false;
    try {
      await _api.patch(
        Endpoints.employeeTaxFormPatch(employeeId, formId),
        data: {"status": status},
      );
      await fetchTaxForms();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> refreshTaxForms() async {
    if (employeeId.isEmpty) return;
    state = state.copyWith(taxFormsLoading: true);
    try {
      await _api.post(Endpoints.employeeTaxFormsRefresh(employeeId));
      await fetchTaxForms();
    } catch (_) {
      state = state.copyWith(taxFormsLoading: false);
    }
  }

  Future<void> fetchW4Forms() async {
    if (employeeId.isEmpty) return;
    state = state.copyWith(w4Loading: true);
    try {
      final resp = await _api.get(Endpoints.employeeW4Form(employeeId));
      final list = _extractList(resp.data);
      state = state.copyWith(w4Loading: false, w4Forms: list);
    } catch (_) {
      state = state.copyWith(w4Loading: false);
    }
  }

  Future<bool> upsertW4Form({
    required Map<String, dynamic> payload,
    String? w4Id,
  }) async {
    if (employeeId.isEmpty) return false;
    try {
      if (w4Id != null && w4Id.isNotEmpty) {
        await _api.patch(
          Endpoints.employeeW4FormPatch(employeeId, w4Id),
          data: payload,
        );
      } else {
        await _api.post(Endpoints.employeeW4Form(employeeId), data: payload);
      }
      await fetchW4Forms();
      await fetch();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> fetchCredentials() async {
    if (employeeId.isEmpty) return;
    state = state.copyWith(credentialsLoading: true);
    try {
      final resp = await _api.get(Endpoints.employeeCredentials(employeeId));
      final list = _extractList(resp.data);
      state = state.copyWith(credentialsLoading: false, credentials: list);
    } catch (_) {
      state = state.copyWith(credentialsLoading: false);
    }
  }

  Future<bool> updateCredentialStatus({
    required String credentialId,
    required String status,
    String? feedback,
  }) async {
    if (credentialId.isEmpty) return false;
    try {
      await _api.patch(
        Endpoints.employeeCredentialStatus(credentialId),
        data: {
          "status": status,
          if (feedback != null && feedback.isNotEmpty) "feedback": feedback,
        },
      );
      await fetchCredentials();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateCredentialExpiry({
    required String credentialId,
    required String expiry,
  }) async {
    if (employeeId.isEmpty || credentialId.isEmpty) return false;
    try {
      await _api.patch(
        Endpoints.employeeCredentialExpiry(employeeId, credentialId),
        data: {"expiry": expiry},
      );
      await fetchCredentials();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> uploadCredentialFile({
    required String credentialId,
    required String filePath,
    bool isCompleted = true,
  }) async {
    if (credentialId.isEmpty || filePath.isEmpty) return false;
    try {
      final form = FormData.fromMap({
        "upload_data": await MultipartFile.fromFile(filePath),
        if (isCompleted) "is_completed": true,
      });
      await _api.patch(
        Endpoints.employeeCredentialPatch(credentialId),
        data: form,
      );
      await fetchCredentials();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> uploadCredentialFileSecondary({
    required String credentialId,
    required String filePath,
    bool isCompleted = true,
  }) async {
    if (credentialId.isEmpty || filePath.isEmpty) return false;
    try {
      final form = FormData.fromMap({
        "upload_data_2": await MultipartFile.fromFile(filePath),
        if (isCompleted) "is_completed": true,
      });
      await _api.patch(
        Endpoints.employeeCredentialPatch(credentialId),
        data: form,
      );
      await fetchCredentials();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> uploadCredentialReferences({
    required String credentialId,
    required List<Map<String, dynamic>> references,
    bool isCompleted = true,
  }) async {
    if (credentialId.isEmpty) return false;
    try {
      final form = FormData.fromMap({
        "reference_data": references,
        if (isCompleted) "is_completed": true,
      });
      await _api.patch(
        Endpoints.employeeCredentialPatch(credentialId),
        data: form,
      );
      await fetchCredentials();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> uploadCredentialText({
    required String credentialId,
    required String text,
    bool isCompleted = true,
  }) async {
    if (credentialId.isEmpty) return false;
    try {
      final form = FormData.fromMap({
        "text_data": text,
        if (isCompleted) "is_completed": true,
      });
      await _api.patch(
        Endpoints.employeeCredentialPatch(credentialId),
        data: form,
      );
      await fetchCredentials();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> addDependent(Map<String, dynamic> payload) async {
    if (employeeId.isEmpty) return false;
    try {
      await _api.post(Endpoints.employeeDependentsLegacy(employeeId), data: payload);
      await fetchDependents();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateDependent(String dependentId, Map<String, dynamic> payload) async {
    if (employeeId.isEmpty || dependentId.isEmpty) return false;
    try {
      await _api.patch(
        "${Endpoints.employeeDependentsLegacy(employeeId)}$dependentId/",
        data: payload,
      );
      await fetchDependents();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteDependent(String dependentId) async {
    if (employeeId.isEmpty || dependentId.isEmpty) return false;
    try {
      await _api.delete(
        "${Endpoints.employeeDependentsLegacy(employeeId)}$dependentId/",
      );
      await fetchDependents();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> fetchWorkHistory({int? page, int? pageSize}) async {
    if (employeeId.isEmpty) return;
    state = state.copyWith(workHistoryLoading: true);
    try {
      final params = <String, dynamic>{};
      if (page != null) params["page"] = page;
      if (pageSize != null) params["page_size"] = pageSize;
      final resp =
          await _api.get(Endpoints.employeeWorkHistory(employeeId), params: params);
      final list = _extractList(resp.data);
      state = state.copyWith(workHistoryLoading: false, workHistory: list);
    } catch (_) {
      state = state.copyWith(workHistoryLoading: false);
    }
  }

  Future<void> fetchPayDetails({int? page, int? pageSize}) async {
    if (employeeId.isEmpty) return;
    state = state.copyWith(payDetailsLoading: true);
    try {
      final params = <String, dynamic>{};
      if (page != null) params["page"] = page;
      if (pageSize != null) params["page_size"] = pageSize;
      final resp =
          await _api.get(Endpoints.employeePayDetails(employeeId), params: params);
      final data = resp.data is Map<String, dynamic>
          ? Map<String, dynamic>.from(resp.data["data"] ?? resp.data)
          : <String, dynamic>{};
      state = state.copyWith(payDetailsLoading: false, payDetails: data);
    } catch (_) {
      state = state.copyWith(payDetailsLoading: false);
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
