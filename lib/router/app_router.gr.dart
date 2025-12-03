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
      final args = routeData.argsAs<StartRouteArgs>(orElse: () => const StartRouteArgs());
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
    LayingParametersRoute.name: (routeData) {
      return MaterialPageX<dynamic>(
        routeData: routeData,
        child: LayingParametersScreen(),
      );
    },
    ResultRoute.name: (routeData) {
      final args = routeData.argsAs<ResultRouteArgs>();
      return MaterialPageX<dynamic>(
        routeData: routeData,
        child: ResultScreen(args.result),
      );
    },
    SchemeRoute.name: (routeData) {
      final args = routeData.argsAs<SchemeRouteArgs>();
      return MaterialPageX<dynamic>(
        routeData: routeData,
        child: SchemeScreen(args.result, args.number),
      );
    },
  };

  @override
  List<RouteConfig> get routes => [
        RouteConfig(
          RoomAndLaminateParametersRoute.name,
          path: '/',
        ),
        RouteConfig(
          StartRoute.name,
          path: '/start-screen',
        ),
        RouteConfig(
          LayingParametersRoute.name,
          path: '/laying-parameters-screen',
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
class StartRoute extends PageRouteInfo<StartRouteArgs> {
  StartRoute({Key? key})
      : super(
          StartRoute.name,
          path: '/start-screen',
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
          path: '/',
        );

  static const String name = 'RoomAndLaminateParametersRoute';
}

/// generated route for
/// [LayingParametersScreen]
class LayingParametersRoute extends PageRouteInfo<void> {
  const LayingParametersRoute()
      : super(
          LayingParametersRoute.name,
          path: '/laying-parameters-screen',
        );

  static const String name = 'LayingParametersRoute';
}

/// generated route for
/// [ResultScreen]
class ResultRoute extends PageRouteInfo<ResultRouteArgs> {
  ResultRoute({required List<Result> result})
      : super(
          ResultRoute.name,
          path: '/result-screen',
          args: ResultRouteArgs(result: result),
        );

  static const String name = 'ResultRoute';
}

class ResultRouteArgs {
  const ResultRouteArgs({required this.result});

  final List<Result> result;

  @override
  String toString() {
    return 'ResultRouteArgs{result: $result}';
  }
}

/// generated route for
/// [SchemeScreen]
class SchemeRoute extends PageRouteInfo<SchemeRouteArgs> {
  SchemeRoute({required Result result, required int number})
      : super(
          SchemeRoute.name,
          path: '/scheme-screen',
          args: SchemeRouteArgs(result: result, number: number),
        );

  static const String name = 'SchemeRoute';
}

class SchemeRouteArgs {
  const SchemeRouteArgs({required this.result, required this.number});

  final Result result;
  final int number;

  @override
  String toString() {
    return 'SchemeRouteArgs{result: $result, number: $number}';
  }
}
