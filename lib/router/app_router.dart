import 'package:auto_route/auto_route.dart';
import 'package:floor_calculator/pages/room_and_laminate_parameters_screen.dart';
import 'package:floor_calculator/pages/start_screen.dart';
import 'package:flutter/material.dart';

part 'app_router.gr.dart';

@MaterialAutoRouter(
  replaceInRouteName: 'Screen,Route',
  routes: <AutoRoute>[
    AutoRoute(page: StartScreen, initial: true),
    AutoRoute(page: RoomAndLaminateParametersScreen),
    //  AutoRoute(page: BookDetailsPage),
  ],
)
class AppRouter extends _$AppRouter {}
