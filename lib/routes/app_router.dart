import "package:go_router/go_router.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../features/common/placeholder_screen.dart";
import "../features/common/remote_list_screen.dart";
import "../features/schedule_builder/schedule_builder_screen.dart";
import "../features/daily_schedule/daily_schedule_screen.dart";
import "../features/dashboard/dashboard_screen.dart";
import "../features/home/home_screen.dart";
import "../features/employees/employees_screen.dart";
import "../features/employees/employee_detail_screen.dart";
import "../features/employees/employee_form_screen.dart";
import "../features/settings/env_switcher_screen.dart";
import "../features/auth/login_screen.dart";
import "../features/auth/reset_password_screen.dart";
import "../features/auth/set_password_screen.dart";
import "../core/auth/auth_controller.dart";
import "../widgets/app_shell.dart";
import "app_routes.dart";

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);
  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    redirect: (context, state) {
      final location = state.uri.toString();
      final isAuthRoute = location == AppRoutes.login ||
          location == AppRoutes.resetPassword ||
          location.startsWith("/set-password");
      final isPublicRoute = location == "/" || location == "/settings/env";
      if (!auth.isAuthenticated && !(isAuthRoute || isPublicRoute)) {
        return AppRoutes.login;
      }
      if (auth.isAuthenticated && isAuthRoute) {
        return AppRoutes.dashboard;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: "/",
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.setPassword,
        builder: (context, state) => SetPasswordScreen(
          uid: state.pathParameters["uid"] ?? "",
          token: state.pathParameters["token"] ?? "",
        ),
      ),
      GoRoute(
        path: "/settings/env",
        builder: (context, state) => const EnvSwitcherScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.notifications,
            builder: (context, state) => const PlaceholderScreen(title: "Notifications"),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const PlaceholderScreen(title: "Profile"),
          ),
          GoRoute(
            path: AppRoutes.scheduleBuilder,
            builder: (context, state) => const ScheduleBuilderScreen(),
          ),
          GoRoute(
            path: AppRoutes.dailySchedule,
            builder: (context, state) => const DailyScheduleScreen(),
          ),
          GoRoute(
            path: AppRoutes.weeklySchedule,
            builder: (context, state) => const RemoteListScreen(
              title: "Weekly Schedule",
              endpoint: "facilities/weekly-schedule-v2",
            ),
          ),
          GoRoute(
            path: AppRoutes.monthlyView,
            builder: (context, state) => const RemoteListScreen(
              title: "Monthly Schedule",
              endpoint: "facilities/monthly-views/",
            ),
          ),
          GoRoute(
            path: AppRoutes.allShift,
            builder: (context, state) => const RemoteListScreen(
              title: "Applicants & Reports",
              endpoint: "facilities/daily-opening/",
            ),
          ),
          GoRoute(
            path: AppRoutes.employees,
            builder: (context, state) => const EmployeesScreen(),
          ),
          GoRoute(
            path: AppRoutes.employeeAdd,
            builder: (context, state) => const EmployeeFormScreen(),
          ),
          GoRoute(
            path: AppRoutes.employeeDetail,
            builder: (context, state) => EmployeeDetailScreen(
              employeeId: state.pathParameters["id"] ?? "",
            ),
          ),
          GoRoute(
            path: AppRoutes.employeeEdit,
            builder: (context, state) => EmployeeFormScreen(
              initial: state.extra as Map<String, dynamic>?,
            ),
          ),
          GoRoute(
            path: AppRoutes.timesheet,
            builder: (context, state) => const RemoteListScreen(
              title: "Timesheet",
              endpoint: "facilities/timesheet/listing/",
            ),
          ),
          GoRoute(
            path: AppRoutes.hppdTracker,
            builder: (context, state) => const RemoteListScreen(
              title: "HPPD Tracker",
              endpoint: "owner/hppd_tracker/",
            ),
          ),
          GoRoute(
            path: AppRoutes.rotations,
            builder: (context, state) => const RemoteListScreen(
              title: "Rotation Logs",
              endpoint: "facilities/weekly-rotations/",
            ),
          ),
          GoRoute(
            path: AppRoutes.taxes,
            builder: (context, state) => const RemoteListScreen(
              title: "Taxes",
              endpoint: "facilities/taxes",
            ),
          ),
          GoRoute(
            path: AppRoutes.message,
            builder: (context, state) => const RemoteListScreen(
              title: "Message Center",
              endpoint: "facilities/message-center/conversation",
            ),
          ),
          GoRoute(
            path: AppRoutes.missingPunch,
            builder: (context, state) => const RemoteListScreen(
              title: "Missing Punches",
              endpoint: "facilities/missed-punches/",
            ),
          ),
          GoRoute(
            path: AppRoutes.pbj,
            builder: (context, state) => const RemoteListScreen(
              title: "Manage PBJ",
              endpoint: "facilities/pbj/employees",
            ),
          ),
          GoRoute(
            path: AppRoutes.bulkMessaging,
            builder: (context, state) => const RemoteListScreen(
              title: "Bulk Messaging",
              endpoint: "facilities/broadcast-messages/",
            ),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const RemoteListScreen(
              title: "Settings",
              endpoint: "facilities/profile",
            ),
          ),
          GoRoute(
            path: AppRoutes.paidTimeOff,
            builder: (context, state) => const RemoteListScreen(
              title: "Paid Time Off",
              endpoint: "facilities/pto",
            ),
          ),
          GoRoute(
            path: AppRoutes.deductions,
            builder: (context, state) => const RemoteListScreen(
              title: "Deductions",
              endpoint: "payroll/deduction/",
            ),
          ),
          GoRoute(
            path: AppRoutes.bonuses,
            builder: (context, state) => const RemoteListScreen(
              title: "Bonuses",
              endpoint: "payroll/bonus/",
            ),
          ),
          GoRoute(
            path: AppRoutes.paychex,
            builder: (context, state) => const RemoteListScreen(
              title: "Paychex",
              endpoint: "facilities/paychex-data/",
            ),
          ),
          GoRoute(
            path: AppRoutes.rotationAssign,
            builder: (context, state) => const RemoteListScreen(
              title: "Assign Rotations",
              endpoint: "facilities/rotation-assign/",
            ),
          ),
          GoRoute(
            path: AppRoutes.payroll,
            builder: (context, state) => const RemoteListScreen(
              title: "Payroll",
              endpoint: "facilities/new-payment/",
            ),
          ),
          GoRoute(
            path: AppRoutes.reimbursement,
            builder: (context, state) => const RemoteListScreen(
              title: "Expense Reimbursement",
              endpoint: "facilities/reimbursement",
            ),
          ),
          GoRoute(
            path: AppRoutes.vault,
            builder: (context, state) => const RemoteListScreen(
              title: "Facility Vault",
              endpoint: "facilities/bank/vault",
            ),
          ),
          GoRoute(
            path: AppRoutes.fees,
            builder: (context, state) => const RemoteListScreen(
              title: "Commission & Platform Fee",
              endpoint: "facilities/platform-fee/",
            ),
          ),
        ],
      ),
    ],
  );
});
