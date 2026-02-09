class Endpoints {
  Endpoints._();

  static const login = "facilities/manager/login";
  static const forgotPassword = "facilities/manager/forgot-password";
  static const resetPassword = "facilities/manager/reset-password";
  static const changePassword = "facilities/manager/change-password";
  static const updateDeviceToken = "auth/user/update-device-token";
  static const fetchDepartments = "facilities/departments-list";
  static const fetchStatsDashboard = "facilities/dashboard/stats";
  static const fetchFacilityProfile = "facilities/profile";
  static const fetchSchedulesList = "facilities/opening-v2/";
  static const mergeOpenings = "facilities/opening-v2/merge/";
  static const deleteOpening = "facilities/opening-v2/confirm_delete/";
  static const dailyOpeningsList = "facilities/daily-opening-v4/";
  static const employees = "facilities/employees";
  static const employeeInviteAction = "facilities/employees";
  static String employeeWageHistory(String employeeId) =>
      "facilities/employees/$employeeId/wage-history";
  static String employeeActiveShift(String employeeId) =>
      "facilities/employees/$employeeId/active-shift/";
  static String employeePaymentHistory(String employeeId) =>
      "facilities/employees/$employeeId/payment-history";
  static String employeePendingPayments(String employeeId) =>
      "facilities/employees/$employeeId/pending-payments";
  static String employeePaymentDetail(String paymentId) =>
      "facilities/payment/$paymentId";
  static String employeeDependents(String employeeId) =>
      "facilities/employees/$employeeId/dependents/";
  static String employeeDependentsLegacy(String employeeId) =>
      "facilities/employees/$employeeId/dependent/";
  static String employeeW4Form(String employeeId) =>
      "facilities/employees/$employeeId/w4-form/";
  static String employeeW4FormPatch(String employeeId, String w4Id) =>
      "facilities/employees/$employeeId/w4-form/$w4Id/";
  static String employeeTaxForms(String employeeId) =>
      "facilities/employees/$employeeId/tax-forms/";
  static String employeeTaxFormsRefresh(String employeeId) =>
      "facilities/employees/$employeeId/tax-forms/refresh/";
  static String employeeTaxFormPatch(String employeeId, String formId) =>
      "facilities/employees/$employeeId/tax-forms/$formId/";
  static String employeeWorkHistory(String employeeId) =>
      "facilities/employees/$employeeId/work-history";
  static String employeeWorkHistoryWithParams(
    String employeeId,
    String params,
  ) =>
      "facilities/employees/$employeeId/work-history?$params";
  static String employeePayDetails(String employeeId) =>
      "facilities/employees/$employeeId/pay-details/";
  static String employeeW2Years(String employeeId) =>
      "common/w2form-nurses-years/$employeeId";
  static String employeeW2Compute(String employeeId) =>
      "facilities/employees/$employeeId/w2form/compute";
  static String employeeW2Form(String employeeId, String yearId) =>
      "facilities/employees/$employeeId/w2form/$yearId";
  static String employeeCredentials(String employeeId) =>
      "facility/employees/$employeeId/credentials";
  static String employeeCredentialPatch(String credentialId) =>
      "facilities/employees/credential/$credentialId";
  static String employeeCredentialStatus(String credentialId) =>
      "facilities/employees/credential/$credentialId/action";
  static String employeeCredentialExpiry(String employeeId, String credentialId) =>
      "facilities/employees/$employeeId/credential/expiry/$credentialId";
  static const jobTitles = "common/job-titles";
  static const schedulers = "facilities/scheduler/";
  static const supervisors = "facilities/supervisor/";
  static const employeesBulkValidate = "facilities/employees/bulk/validate";
  static const employeesBulkInvite = "facilities/employees/bulk/invite";
  static const employeesBulkInviteManual =
      "facilities/employees/bulk/invite-manually";
  static const walkInEmployees = "facilities/walk-in-employees/";
  static String walkInEmployee(String id) => "facilities/walk-in-employees/$id/";
  static String walkInAssign(String shiftId) =>
      "facilities/shifts/$shiftId/walk-in-employees/";
  static String walkInAvailableEmployees(String shiftId) =>
      "facilities/shifts/$shiftId/walk-in-employees/available/";
  static String walkInClockInOut(String shiftApplicantId) =>
      "facilities/walk-in-employees/$shiftApplicantId/clock-in-clock-out/";
  static String walkInWorkHistory(String employeeId) =>
      "facilities/walk-in-employees/$employeeId/work-history/";
  static const fetchCountries = "common/country";
  static String fetchStates(String countryId) => "common/state/$countryId";

  // Daily schedule (web parity)
  static const dailyScheduleOpenings = "facilities/daily-opening-v4/";
  static String dailyScheduleShiftDetail(String id) =>
      "facilities/daily-opening-v4/$id/";
  static const dailyScheduleDeleteShift =
      "facilities/daily-opening-v4/confirm_delete/";
  static const dailyScheduleUpdateTimings =
      "facilities/daily-opening-v4/update-timings/";
  static const dailyScheduleMultiAssign =
      "facilities/daily-opening-v4/multi-assign/";
  static String dailyScheduleOpeningCounts(String params) =>
      "facilities/daily-opening-v4/daily-opening-counts/?$params";
  static const dailyScheduleStats = "facilities/daily-opening/stats/";
  static const dailyScheduleJobTitleConflict =
      "facilities/daily-opening-v2/job-title-conflict";
  static const dailyScheduleBroadcast = "facilities/broadcast-shifts/";
  static const dailyScheduleLogs = "facilities/audit-log";
  static const dailyScheduleShiftReport = "facilities/daily-shift-report/";
  static String dailyScheduleOffSchedule(String date) =>
      "facilities/daily-opening-v2/$date/off-schedule/";
  static String dailyScheduleHppdData(String params) =>
      "facilities/daily-opening-v2/daily-hppd/?$params";
  static String dailyScheduleShiftList(String date) =>
      "facilities/new-dashboard/$date/shifts/";
  static String dailyScheduleUpdateOpening(String openingId) =>
      "facilities/daily-opening/$openingId/";
  static String dailyScheduleApplicants(String shiftId) =>
      "facilities/shifts/$shiftId/applicants";
  static String dailyScheduleAvailableEmployees(String shiftId) =>
      "facilities/shifts/$shiftId/employees-available";
  static String dailyScheduleAssignEmployees(String shiftId) =>
      "facilities/daily-opening-v2/shifts/$shiftId/employees-v2/";
  static String dailyScheduleUpdateApplicant(String applicantId) =>
      "facilities/daily-opening/applicant/$applicantId/";
  static String dailyScheduleUnassignApplicant(
    String openingDailyId,
    String applicantId,
  ) =>
      "facilities/daily-opening-v2/$openingDailyId/applicants/$applicantId/";

  // Schedule builder advanced
  static const scheduleBuilderJobTitleConflict =
      "facilities/opening-v2/job-title-conflict";
  static const scheduleBuilderResetApplicants =
      "facilities/opening-v2/remove-applicant/";
}
