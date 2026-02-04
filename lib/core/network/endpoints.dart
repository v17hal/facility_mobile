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
  static const jobTitles = "common/job-titles";
  static const schedulers = "facilities/scheduler/";
  static const supervisors = "facilities/supervisor/";

  // Daily schedule (web parity)
  static const dailyScheduleOpenings = "facilities/daily-opening-v2-new/";
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
