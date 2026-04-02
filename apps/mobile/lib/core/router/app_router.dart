import 'package:go_router/go_router.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/phone_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/name_screen.dart';
import '../../features/auth/screens/location_screen.dart';
import '../../features/feed/screens/feed_screen.dart';
import '../../features/master_profile/screens/master_profile_screen.dart';
import '../../features/booking/screens/service_select_screen.dart';
import '../../features/booking/screens/slot_select_screen.dart';
import '../../features/booking/screens/booking_confirm_screen.dart';
import '../../features/master_profile/data/master_models.dart';
import '../../features/favourites/screens/favourites_screen.dart';
import '../../features/chat/screens/chats_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/bookings_list/screens/bookings_screen.dart';
import '../../features/catalog/screens/catalog_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
// Master onboarding
import '../../features/master/screens/master_specializations_screen.dart';
import '../../features/master/screens/master_address_screen.dart';
import '../../features/master/screens/master_portfolio_screen.dart';
import '../../features/master/screens/master_service_screen.dart';
import '../../features/master/screens/master_pending_screen.dart';
// Master app
import '../../features/master/screens/master_dashboard_screen.dart';
import '../../features/master/screens/master_bookings_screen.dart';
import '../../features/master/screens/master_schedule_screen.dart';
import '../../features/master/screens/master_profile_screen.dart'
    as mp show MasterProfileScreen;
import '../shell/client_shell.dart';
import '../shell/master_shell.dart';
import '../../features/stories/screens/story_viewer_screen.dart';
import '../../features/feed/data/feed_models.dart' as feed;

class AppRoutes {
  // Auth
  static const splash   = '/';
  static const phone    = '/phone';
  static const otp      = '/otp';
  static const name     = '/name';
  static const location = '/location';

  // Client tabs (shell)
  static const feed        = '/feed';
  static const catalog     = '/catalog';
  static const favourites  = '/favourites';
  static const chats       = '/chats';
  static const profile     = '/profile';

  // Outside shell
  static const bookings    = '/bookings';

  // Master tabs (shell)
  static const masterDashboard = '/master/dashboard';
  static const masterBookings  = '/master/bookings';
  static const masterSchedule  = '/master/schedule';
  static const masterProfile   = '/master/profile';

  // Master onboarding
  static const masterSpecializations = '/become-master/specializations';
  static const masterAddress         = '/become-master/address';
  static const masterPortfolio       = '/become-master/portfolio';
  static const masterService         = '/become-master/service';
  static const masterPending         = '/become-master/pending';

  // Nested routes
  static String masterPublicProfile(String id) => '/masters/$id';
  static String serviceSelect(String masterId) => '/masters/$masterId/book';
  static String slotSelect(String masterId) => '/masters/$masterId/book/slots';
  static const bookingConfirm = '/booking/confirm';
  static String chat(String roomId) => '/chats/$roomId';
  static const stories = '/stories';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    // ─── Auth ─────────────────────────────────────────────────────
    GoRoute(path: AppRoutes.splash,   builder: (_, __) => const SplashScreen()),
    GoRoute(path: AppRoutes.phone,    builder: (_, __) => const PhoneScreen()),
    GoRoute(
      path: AppRoutes.otp,
      builder: (_, state) => OtpScreen(phone: state.extra as String),
    ),
    GoRoute(
      path: AppRoutes.name,
      builder: (_, state) => NameScreen(phone: state.extra as String),
    ),
    GoRoute(path: AppRoutes.location, builder: (_, __) => const LocationScreen()),

    // ─── Story viewer ─────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.stories,
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>;
        return StoryViewerScreen(
          stories: extra['stories'] as List<feed.StoryItem>,
          initialIndex: extra['initialIndex'] as int? ?? 0,
        );
      },
    ),

    // ─── Public Master Profile (outside Shell) ─────────────────────
    GoRoute(
      path: '/masters/:id',
      builder: (_, state) =>
          MasterProfileScreen(masterId: state.pathParameters['id']!),
    ),

    // ─── Booking flow (outside Shell) ─────────────────────────────
    GoRoute(
      path: '/masters/:masterId/book',
      builder: (_, state) {
        final master = state.extra as MasterProfile;
        return ServiceSelectScreen(master: master);
      },
    ),
    GoRoute(
      path: '/masters/:masterId/book/slots',
      builder: (_, state) {
        final extra = state.extra as ({MasterProfile master, MasterService service});
        return SlotSelectScreen(master: extra.master, service: extra.service);
      },
    ),
    GoRoute(
      path: AppRoutes.bookingConfirm,
      builder: (_, state) {
        final e = state.extra
            as ({MasterProfile master, MasterService service, String date, String time});
        return BookingConfirmScreen(
          master: e.master,
          service: e.service,
          date: e.date,
          time: e.time,
        );
      },
    ),

    // ─── Chat dialog (outside Shell) ──────────────────────────────
    GoRoute(
      path: '/chats/:roomId',
      builder: (_, state) {
        final extra = state.extra as ({String masterName});
        return ChatScreen(
          roomId: state.pathParameters['roomId']!,
          masterName: extra.masterName,
        );
      },
    ),

    // ─── Master onboarding (outside Shell) ────────────────────────
    GoRoute(
      path: AppRoutes.masterSpecializations,
      builder: (_, __) => const MasterSpecializationsScreen(),
    ),
    GoRoute(
      path: AppRoutes.masterAddress,
      builder: (_, __) => const MasterAddressScreen(),
    ),
    GoRoute(
      path: AppRoutes.masterPortfolio,
      builder: (_, __) => const MasterPortfolioScreen(),
    ),
    GoRoute(
      path: AppRoutes.masterService,
      builder: (_, __) => const MasterServiceScreen(),
    ),
    GoRoute(
      path: AppRoutes.masterPending,
      builder: (_, __) => const MasterPendingScreen(),
    ),

    // ─── Bookings (outside Shell, accessed from Profile) ──────────
    GoRoute(
      path: AppRoutes.bookings,
      builder: (_, __) => const BookingsScreen(),
    ),

    // ─── Client Shell (5 tabs) ─────────────────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (_, __, shell) => ClientShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: AppRoutes.feed, builder: (_, __) => const FeedScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.catalog,
            builder: (_, __) => const CatalogScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.favourites,
            builder: (_, __) => const FavouritesScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.chats,
            builder: (_, __) => const ChatsScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, __) => const ProfileScreen(),
          ),
        ]),
      ],
    ),

    // ─── Master Shell (4 tabs) ─────────────────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (_, __, shell) => MasterShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.masterDashboard,
            builder: (_, __) => const MasterDashboardScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.masterBookings,
            builder: (_, __) => const MasterBookingsScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.masterSchedule,
            builder: (_, __) => const MasterScheduleScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.masterProfile,
            builder: (_, __) => const mp.MasterProfileScreen(),
          ),
        ]),
      ],
    ),
  ],
);
