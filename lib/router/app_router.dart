import 'package:auto_route/auto_route.dart';
import 'package:floor_calculator/models.dart';
import 'package:floor_calculator/pages/laying_parameters_screen.dart';
import 'package:floor_calculator/pages/result_screen.dart';
import 'package:floor_calculator/pages/room_and_laminate_parameters_screen.dart';
import 'package:floor_calculator/pages/scheme_screen.dart';
import 'package:floor_calculator/pages/start_screen.dart';
import 'package:flutter/material.dart';

part 'app_router.gr.dart';

@MaterialAutoRouter(
  replaceInRouteName: 'Screen,Route',
  routes: <AutoRoute>[
    AutoRoute(page: RoomAndLaminateParametersScreen, initial: true),
    AutoRoute(page: StartScreen),
    AutoRoute(page: LayingParametersScreen),
    AutoRoute(page: ResultScreen),
    AutoRoute(page: SchemeScreen),
  ],
)
class AppRouter extends _$AppRouter {}
