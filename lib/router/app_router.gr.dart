// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************
//
// ignore_for_file: type=lint

part of 'app_router.dart';

class _$AppRouter extends RootStackRouter {
  _$AppRouter([GlobalKey<NavigatorState>? navigatorKey]) : super(navigatorKey);

  @override
  final Map<String, PageFactory> pagesMap = {
    StartRoute.name: (routeData) {
      final args = routeData.argsAs<StartRouteArgs>(
          orElse: () => const StartRouteArgs());
      return MaterialPageX<dynamic>(
        routeData: routeData,
        child: StartScreen(key: args.key),
      );
    },
    RoomAndLaminateParametersRoute.name: (routeData) {
      return MaterialPageX<dynamic>(
        routeData: routeData,
        child: RoomAndLaminateParametersScreen(),
      );
    },
  };

  @override
  List<RouteConfig> get routes => [
        RouteConfig(
          StartRoute.name,
          path: '/',
        ),
        RouteConfig(
          RoomAndLaminateParametersRoute.name,
          path: '/room-and-laminate-parameters-screen',
        ),
      ];
}

/// generated route for
/// [StartScreen]
class StartRoute extends PageRouteInfo<StartRouteArgs> {
  StartRoute({Key? key})
      : super(
          StartRoute.name,
          path: '/',
          args: StartRouteArgs(key: key),
        );

  static const String name = 'StartRoute';
}

class StartRouteArgs {
  const StartRouteArgs({this.key});

  final Key? key;

  @override
  String toString() {
    return 'StartRouteArgs{key: $key}';
  }
}

/// generated route for
/// [RoomAndLaminateParametersScreen]
class RoomAndLaminateParametersRoute extends PageRouteInfo<void> {
  const RoomAndLaminateParametersRoute()
      : super(
          RoomAndLaminateParametersRoute.name,
          path: '/room-and-laminate-parameters-screen',
        );

  static const String name = 'RoomAndLaminateParametersRoute';
}
