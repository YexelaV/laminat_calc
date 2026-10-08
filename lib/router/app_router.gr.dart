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
      return MaterialPageX<dynamic>(
        routeData: routeData,
        child: const StartScreen(),
      );
    },
    MeasurementSystemRoute.name: (routeData) {
      return MaterialPageX<dynamic>(
        routeData: routeData,
        child: const MeasurementSystemScreen(),
      );
    },
    RoomParametersRoute.name: (routeData) {
      return MaterialPageX<dynamic>(
        routeData: routeData,
        child: const RoomParametersScreen(),
      );
    },
    LaminateAndLayingRoute.name: (routeData) {
      return MaterialPageX<dynamic>(
        routeData: routeData,
        child: const LaminateAndLayingScreen(),
      );
    },
    ReviewRoute.name: (routeData) {
      return MaterialPageX<dynamic>(
        routeData: routeData,
        child: const ReviewScreen(),
      );
    },
    ResultRoute.name: (routeData) {
      final args = routeData.argsAs<ResultRouteArgs>();
      return MaterialPageX<dynamic>(
        routeData: routeData,
        child: ResultScreen(
          args.result,
          key: args.key,
        ),
      );
    },
    SchemeRoute.name: (routeData) {
      final args = routeData.argsAs<SchemeRouteArgs>();
      return MaterialPageX<dynamic>(
        routeData: routeData,
        child: SchemeScreen(
          args.result,
          args.number,
          key: args.key,
        ),
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
          MeasurementSystemRoute.name,
          path: '/measurement-system-screen',
        ),
        RouteConfig(
          RoomParametersRoute.name,
          path: '/room-parameters-screen',
        ),
        RouteConfig(
          LaminateAndLayingRoute.name,
          path: '/laminate-and-laying-screen',
        ),
        RouteConfig(
          ReviewRoute.name,
          path: '/review-screen',
        ),
        RouteConfig(
          ResultRoute.name,
          path: '/result-screen',
        ),
        RouteConfig(
          SchemeRoute.name,
          path: '/scheme-screen',
        ),
      ];
}

/// generated route for
/// [StartScreen]
class StartRoute extends PageRouteInfo<void> {
  const StartRoute()
      : super(
          StartRoute.name,
          path: '/',
        );

  static const String name = 'StartRoute';
}

/// generated route for
/// [MeasurementSystemScreen]
class MeasurementSystemRoute extends PageRouteInfo<void> {
  const MeasurementSystemRoute()
      : super(
          MeasurementSystemRoute.name,
          path: '/measurement-system-screen',
        );

  static const String name = 'MeasurementSystemRoute';
}

/// generated route for
/// [RoomParametersScreen]
class RoomParametersRoute extends PageRouteInfo<void> {
  const RoomParametersRoute()
      : super(
          RoomParametersRoute.name,
          path: '/room-parameters-screen',
        );

  static const String name = 'RoomParametersRoute';
}

/// generated route for
/// [LaminateAndLayingScreen]
class LaminateAndLayingRoute extends PageRouteInfo<void> {
  const LaminateAndLayingRoute()
      : super(
          LaminateAndLayingRoute.name,
          path: '/laminate-and-laying-screen',
        );

  static const String name = 'LaminateAndLayingRoute';
}

/// generated route for
/// [ReviewScreen]
class ReviewRoute extends PageRouteInfo<void> {
  const ReviewRoute()
      : super(
          ReviewRoute.name,
          path: '/review-screen',
        );

  static const String name = 'ReviewRoute';
}

/// generated route for
/// [ResultScreen]
class ResultRoute extends PageRouteInfo<ResultRouteArgs> {
  ResultRoute({
    required List<Result> result,
    Key? key,
  }) : super(
          ResultRoute.name,
          path: '/result-screen',
          args: ResultRouteArgs(
            result: result,
            key: key,
          ),
        );

  static const String name = 'ResultRoute';
}

class ResultRouteArgs {
  const ResultRouteArgs({
    required this.result,
    this.key,
  });

  final List<Result> result;

  final Key? key;

  @override
  String toString() {
    return 'ResultRouteArgs{result: $result, key: $key}';
  }
}

/// generated route for
/// [SchemeScreen]
class SchemeRoute extends PageRouteInfo<SchemeRouteArgs> {
  SchemeRoute({
    required Result result,
    required int number,
    Key? key,
  }) : super(
          SchemeRoute.name,
          path: '/scheme-screen',
          args: SchemeRouteArgs(
            result: result,
            number: number,
            key: key,
          ),
        );

  static const String name = 'SchemeRoute';
}

class SchemeRouteArgs {
  const SchemeRouteArgs({
    required this.result,
    required this.number,
    this.key,
  });

  final Result result;

  final int number;

  final Key? key;

  @override
  String toString() {
    return 'SchemeRouteArgs{result: $result, number: $number, key: $key}';
  }
}
