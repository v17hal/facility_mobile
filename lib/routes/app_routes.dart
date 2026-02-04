class AppRoute {
  const AppRoute({
    required this.path,
    required this.label,
    this.group,
  });

  final String path;
  final String label;
  final String? group;
}

class AppRoutes {
  AppRoutes._();

  // Public
  static const login = "/auth/login";
  static const resetPassword = "/auth/reset-password";
  static const setPassword = "/set-password/:uid/:token";

  // Private (mirrors web)
  static const dashboard = "/dashboard";
  static const notifications = "/notifications";
  static const profile = "/profile";
  static const scheduleBuilder = "/schedule-builder";
  static const dailySchedule = "/daily-schedule";
  static const weeklySchedule = "/weekly";
  static const monthlyView = "/monthly-view";
  static const allShift = "/all-shift";
  static const employees = "/employees";
  static const employeeAdd = "/employees/add";
  static const employeeDetail = "/employees/:id";
  static const employeeEdit = "/employees/:id/edit";
  static const timesheet = "/timesheet";
  static const hppdTracker = "/hppd-tracker";
  static const rotations = "/rotations";
  static const taxes = "/taxes";
  static const message = "/message";
  static const missingPunch = "/missing-punch";
  static const pbj = "/pbj";
  static const bulkMessaging = "/bulk-messaging";
  static const settings = "/settings";
  static const paidTimeOff = "/paid-time-off";
  static const deductions = "/deductions";
  static const bonuses = "/all-bonus";
  static const paychex = "/paychex";
  static const rotationAssign = "/rotation-assign";
  static const payroll = "/payroll";
  static const reimbursement = "/reimbursement";
  static const vault = "/vault";
  static const fees = "/fees";

  static const List<AppRoute> menu = [
    AppRoute(path: dashboard, label: "Dashboard"),
    AppRoute(path: scheduleBuilder, label: "Schedule Builder"),
    AppRoute(path: dailySchedule, label: "Daily Schedule"),
    AppRoute(path: allShift, label: "Applicants & Reports"),
    AppRoute(path: weeklySchedule, label: "Weekly Schedule"),
    AppRoute(path: monthlyView, label: "Monthly Schedule"),
    AppRoute(path: employees, label: "Employees"),
    AppRoute(path: payroll, label: "Payroll", group: "Payments"),
    AppRoute(path: reimbursement, label: "Expense Reimbursement", group: "Payments"),
    AppRoute(path: vault, label: "Facility Vault", group: "Payments"),
    AppRoute(path: fees, label: "Commission & Platform Fee", group: "Payments"),
    AppRoute(path: timesheet, label: "Timesheet"),
    AppRoute(path: hppdTracker, label: "HPPD Tracker"),
    AppRoute(path: rotations, label: "Rotation Logs"),
    AppRoute(path: taxes, label: "Taxes"),
    AppRoute(path: message, label: "Message Center"),
    AppRoute(path: missingPunch, label: "Missing Punches"),
    AppRoute(path: pbj, label: "Manage PBJ"),
    AppRoute(path: bulkMessaging, label: "Bulk Messaging"),
    AppRoute(path: settings, label: "Settings"),
    AppRoute(path: paidTimeOff, label: "Paid Time Off"),
    AppRoute(path: deductions, label: "Deductions"),
    AppRoute(path: bonuses, label: "Bonuses"),
    AppRoute(path: paychex, label: "Paychex"),
    AppRoute(path: rotationAssign, label: "Assign Rotations"),
  ];
}
